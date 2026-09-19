import AppKit

/// Receives the promised files of a drag.
///
/// Photos puts three things on the drag pasteboard: a file promise, the image data,
/// and a file URL to a reduced derivative inside its library. SwiftUI's item providers
/// hand over the derivative. The promise is the real export, and with Option held it is
/// the unmodified original, so promises go first.
enum PromisedFileImporter {
    /// Call this inside the drop handler, while the drag pasteboard is current.
    static func receiversOnDragPasteboard() -> [NSFilePromiseReceiver] {
        NSPasteboard(name: .drag).readObjects(forClasses: [NSFilePromiseReceiver.self], options: nil)
            as? [NSFilePromiseReceiver] ?? []
    }

    /// Receives every promised file into the inbox. A file that fails is left out.
    static func receive(_ receivers: [NSFilePromiseReceiver]) async -> [URL] {
        let expected = receivers.reduce(0) { $0 + max($1.fileTypes.count, 1) }
        guard expected > 0 else { return [] }

        let collector = PromisedFileCollector(expected: expected)
        let queue = OperationQueue()
        return await withCheckedContinuation { continuation in
            for (index, receiver) in receivers.enumerated() {
                // One folder per receiver: `Inbox.discard` removes a whole folder.
                let folder = Inbox.directory.appending(path: UUID().uuidString)
                do {
                    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                } catch {
                    for _ in 0..<max(receiver.fileTypes.count, 1) {
                        if let urls = collector.add(nil, order: index) { continuation.resume(returning: urls) }
                    }
                    continue
                }
                // `@Sendable` keeps this closure off the main actor. AppKit calls it on
                // `queue`, and a main-actor closure stops the app there.
                receiver.receivePromisedFiles(atDestination: folder, options: [:], operationQueue: queue) { @Sendable url, error in
                    if let urls = collector.add(error == nil ? url : nil, order: index) {
                        continuation.resume(returning: urls)
                    }
                }
            }
        }
    }
}
