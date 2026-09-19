import AppKit
import Observation

/// The opened source photos and the work of processing them.
@Observable
final class ImportQueue {
    private(set) var photos: [SourcePhoto] = []
    var selection: Set<SourcePhoto.ID> = []
    private(set) var isProcessing = false
    /// The number of dropped items that are still on their way, for example from Photos.
    private(set) var incomingCount = 0

    /// Called on the main actor each time a photo finishes, with its destination.
    var onPhotoFinished: ((OutputFolder.ID) -> Void)?

    private var task: Task<Void, Never>?
    private var batchIDs: Set<SourcePhoto.ID> = []

    /// Each photo already encodes all its widths in parallel, so only a few
    /// photos run at the same time.
    private var concurrentPhotoLimit: Int {
        max(1, ProcessInfo.processInfo.activeProcessorCount / 6)
    }

    var pending: [SourcePhoto] {
        photos.filter { $0.status == .ready || $0.status.isFailure }
    }

    var selectedPhoto: SourcePhoto? {
        guard selection.count == 1, let id = selection.first else { return nil }
        return photos.first { $0.id == id }
    }

    var hasFinishedPhotos: Bool {
        photos.contains { $0.status == .finished }
    }

    /// The share of the current batch that is done, for the overall progress bar.
    var batchFraction: Double {
        let batch = photos.filter { batchIDs.contains($0.id) }
        guard !batch.isEmpty else { return 0 }
        let done = batch.reduce(0.0) { sum, photo in
            switch photo.status {
            case .finished: sum + 1
            case .processing(let progress): sum + progress.fraction
            default: sum
            }
        }
        return done / Double(batch.count)
    }

    // MARK: - Editing the queue

    /// - Returns: The number of photos that were added.
    @discardableResult
    func add(_ urls: [URL]) async -> Int {
        let known = Set(photos.map(\.url))
        let new = await SourceScanner.expand(urls).filter { !known.contains($0) }
        let hdr = await SourceInspector.photosWithGainMap(in: new)
        let added = new.map { SourcePhoto(url: $0, isHDR: hdr.contains($0)) }
        photos += added
        if let first = added.first {
            selection = [first.id]
        }
        return added.count
    }

    /// Receives dropped items, then adds them. Promised files take a moment to arrive.
    @discardableResult
    func add(_ providers: [NSItemProvider]) async -> Int {
        incomingCount += providers.count
        let urls = await DropImporter.urls(from: providers)
        incomingCount -= providers.count
        return await add(urls)
    }

    /// Receives promised files, for example from Photos, then adds them.
    @discardableResult
    func add(_ receivers: [NSFilePromiseReceiver]) async -> Int {
        incomingCount += receivers.count
        let urls = await PromisedFileImporter.receive(receivers)
        incomingCount -= receivers.count
        return await add(urls)
    }

    func remove(_ ids: Set<SourcePhoto.ID>) {
        for photo in photos where ids.contains(photo.id) && !photo.status.isActive {
            Inbox.discard(photo.url)
        }
        photos.removeAll { ids.contains($0.id) && !$0.status.isActive }
        selection.subtract(ids)
    }

    func removeFinished() {
        remove(Set(photos.filter { $0.status == .finished }.map(\.id)))
    }

    func rename(_ id: SourcePhoto.ID, to name: String) {
        guard let index = index(of: id), !photos[index].status.isActive else { return }
        photos[index].outputName = name
        if photos[index].status != .ready {
            photos[index].status = .ready
        }
    }

    // MARK: - Processing

    func process(into folder: OutputFolder, settings: ProcessingSettings) throws {
        guard !isProcessing else { return }
        let pipeline = try ConversionPipeline(settings: settings)
        let batch = pending.map(\.id)
        guard !batch.isEmpty else { return }

        batchIDs = Set(batch)
        for id in batch {
            setStatus(.waiting, for: id)
        }
        isProcessing = true

        let limit = concurrentPhotoLimit
        task = Task {
            await withTaskGroup(of: Void.self) { group in
                var remaining = batch.makeIterator()
                for _ in 0..<limit {
                    guard let id = remaining.next() else { break }
                    group.addTask { await self.convert(id, with: pipeline, into: folder) }
                }
                while await group.next() != nil {
                    guard !Task.isCancelled, let id = remaining.next() else { continue }
                    group.addTask { await self.convert(id, with: pipeline, into: folder) }
                }
            }
            for index in photos.indices where photos[index].status.isActive {
                photos[index].status = .ready
            }
            isProcessing = false
            task = nil
        }
    }

    func cancel() {
        task?.cancel()
    }

    private func convert(_ id: SourcePhoto.ID, with pipeline: ConversionPipeline, into folder: OutputFolder) async {
        guard !Task.isCancelled, let photo = photos.first(where: { $0.id == id }) else { return }

        let (stream, continuation) = AsyncStream.makeStream(of: ConversionProgress.self)
        async let outputs = pipeline.convert(
            source: photo.url,
            outputName: photo.sanitizedOutputName,
            destination: folder.url,
            progress: continuation
        )
        for await progress in stream {
            setStatus(.processing(progress), for: id)
        }

        do {
            _ = try await outputs
            if let originals = folder.originalsURL {
                do {
                    try await OriginalArchiver.archive(photo.url, outputName: photo.sanitizedOutputName, in: originals)
                } catch {
                    throw PipelineError.originalNotSaved(error.localizedDescription)
                }
            }
            if let index = index(of: id) {
                photos[index].status = .finished
                photos[index].destinationID = folder.id
            }
            onPhotoFinished?(folder.id)
        } catch is CancellationError {
            setStatus(.ready, for: id)
        } catch {
            // A cancel ends the running tool, which then reports a failure of its own.
            setStatus(Task.isCancelled ? .ready : .failed(error.localizedDescription), for: id)
        }
    }

    private func index(of id: SourcePhoto.ID) -> Int? {
        photos.firstIndex { $0.id == id }
    }

    private func setStatus(_ status: SourcePhotoStatus, for id: SourcePhoto.ID) {
        guard let index = index(of: id) else { return }
        photos[index].status = status
    }
}
