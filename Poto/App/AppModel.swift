import SwiftUI

/// App-wide state: the output folders, the settings, what is selected, and the queue.
@Observable
final class AppModel {
    var folders: [OutputFolder] {
        didSet { save(folders, forKey: Keys.folders) }
    }
    var settings: ProcessingSettings {
        didSet { save(settings, forKey: Keys.settings) }
    }
    /// The output folder that processed photos go to.
    var destinationID: OutputFolder.ID? {
        didSet { defaults.set(destinationID?.uuidString, forKey: Keys.destination) }
    }

    var selection: SidebarItem? = .queue
    let queue = ImportQueue()

    // The folder that is open in the list
    private(set) var imageSets: [ImageSet] = []
    private(set) var folderIsMissing = false
    var selectedSetID: ImageSet.ID?
    var searchText = ""
    var sortOrder = ImageSetSortOrder.name
    var prefersHDRPreview = true

    // Presentation
    var isOpenPanelPresented = false
    var isPhotosPickerPresented = false
    var isAddFolderPanelPresented = false
    var editingFolder: OutputFolder?
    var alert: AlertInfo? {
        didSet { isAlertPresented = alert != nil }
    }
    var isAlertPresented = false
    /// Names of existing sets that the next run would replace.
    private(set) var overwriteNames: [String] = []
    var isConfirmingOverwrite = false
    var quickLookURL: URL?
    private(set) var copiedSetID: ImageSet.ID?

    /// A set to select as soon as the folder that contains it has loaded.
    private var pendingSetID: ImageSet.ID?

    private let defaults: UserDefaults
    private var copiedResetTask: Task<Void, Never>?

    private enum Keys {
        static let folders = "outputFolders"
        static let settings = "processingSettings"
        static let destination = "destinationFolderID"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        folders = Self.load([OutputFolder].self, from: defaults, forKey: Keys.folders) ?? []
        settings = Self.load(ProcessingSettings.self, from: defaults, forKey: Keys.settings) ?? ProcessingSettings()
        destinationID = defaults.string(forKey: Keys.destination).flatMap(UUID.init)
        if destinationFolder == nil {
            destinationID = folders.first?.id
        }
        queue.onPhotoFinished = { [weak self] folderID in
            guard let self, selection == .folder(folderID) else { return }
            Task { await self.reloadSets() }
        }
    }

    // MARK: - Derived state

    var destinationFolder: OutputFolder? {
        folders.first { $0.id == destinationID }
    }

    var selectedFolder: OutputFolder? {
        guard case .folder(let id) = selection else { return nil }
        return folders.first { $0.id == id }
    }

    var visibleSets: [ImageSet] {
        let sorted = sortOrder.sorted(imageSets)
        guard !searchText.isEmpty else { return sorted }
        return sorted.filter { $0.name.localizedStandardContains(searchText) }
    }

    var selectedSet: ImageSet? {
        imageSets.first { $0.id == selectedSetID }
    }

    var selectedSnippet: String? {
        guard let selectedSet, let selectedFolder else { return nil }
        return SnippetTemplate.render(selectedFolder.snippetTemplate, for: selectedSet)
    }

    var canProcess: Bool {
        !queue.isProcessing && !queue.pending.isEmpty && destinationFolder != nil
    }

    // MARK: - Opening source photos

    func open(_ urls: [URL]) {
        Task {
            showResult(ofAdding: await queue.add(urls), from: urls.count)
        }
    }

    /// Opens the items of a drop. They can be files, or promised files from Photos.
    func open(_ providers: [NSItemProvider]) {
        selection = .queue
        Task {
            showResult(ofAdding: await queue.add(providers), from: providers.count)
        }
    }

    /// Opens the promised files of a drop.
    func open(_ receivers: [NSFilePromiseReceiver]) {
        selection = .queue
        Task {
            showResult(ofAdding: await queue.add(receivers), from: receivers.count)
        }
    }

    private func showResult(ofAdding added: Int, from itemCount: Int) {
        if added > 0 {
            selection = .queue
        } else if itemCount > 0 {
            alert = AlertInfo(
                title: "No New Photos",
                message: "The items you opened contain no images, or the images are already in the list."
            )
        }
    }

    // MARK: - Output folders

    func addFolder(_ url: URL) {
        let url = url.standardizedFileURL
        // Compare paths: the same folder can arrive with or without a trailing slash.
        if let existing = folders.first(where: { $0.url.path == url.path }) {
            selection = .folder(existing.id)
            return
        }
        let folder = OutputFolder(url: url)
        folders.append(folder)
        if destinationFolder == nil {
            destinationID = folder.id
        }
        selection = .folder(folder.id)
    }

    /// Removes the folder from the app. The folder on disk is not touched.
    func removeFolder(_ id: OutputFolder.ID) {
        folders.removeAll { $0.id == id }
        if selection == .folder(id) {
            selection = .queue
        }
        if destinationID == id {
            destinationID = folders.first?.id
        }
    }

    func update(_ folder: OutputFolder) {
        guard let index = folders.firstIndex(where: { $0.id == folder.id }) else { return }
        let urlChanged = folders[index].url != folder.url
        folders[index] = folder
        if urlChanged, selection == .folder(folder.id) {
            Task { await reloadSets() }
        }
    }

    func reloadSets() async {
        guard let folder = selectedFolder else {
            imageSets = []
            folderIsMissing = false
            return
        }
        do {
            let sets = try await ImageSetScanner.scan(folder: folder.url, knownWidths: Set(settings.widths))
            // The selection can change while the scan runs.
            guard selectedFolder?.id == folder.id else { return }
            imageSets = sets
            folderIsMissing = false
        } catch {
            guard selectedFolder?.id == folder.id else { return }
            imageSets = []
            folderIsMissing = true
        }
        if let pendingSetID, imageSets.contains(where: { $0.id == pendingSetID }) {
            selectedSetID = pendingSetID
        } else if selectedSet == nil {
            selectedSetID = nil
        }
        pendingSetID = nil
    }

    /// Opens the output folder of a finished photo with its set selected.
    func reveal(_ photo: SourcePhoto) {
        guard let folderID = photo.destinationID, folders.contains(where: { $0.id == folderID }) else { return }
        searchText = ""
        // The list clears a selection that matches none of its rows, and the rows
        // of this folder are not loaded yet. `reloadSets()` applies it afterward.
        pendingSetID = photo.imageSetID
        selection = .folder(folderID)
    }

    // MARK: - Snippets

    func copySnippet() {
        guard let selectedSet, let selectedSnippet else { return }
        copy(selectedSnippet, from: selectedSet.id)
    }

    func copySnippet(for set: ImageSet) {
        guard let selectedFolder else { return }
        copy(SnippetTemplate.render(selectedFolder.snippetTemplate, for: set), from: set.id)
    }

    private func copy(_ text: String, from setID: ImageSet.ID) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        copiedSetID = setID
        copiedResetTask?.cancel()
        copiedResetTask = Task {
            try? await Task.sleep(for: Design.copiedDuration)
            guard !Task.isCancelled else { return }
            copiedSetID = nil
        }
    }

    func isCopied(_ set: ImageSet) -> Bool {
        copiedSetID == set.id
    }

    // MARK: - Processing

    /// Checks the queue, then starts the run or asks before it replaces files.
    func requestProcessing() {
        guard let folder = destinationFolder else { return }
        let pending = queue.pending

        if pending.contains(where: { $0.sanitizedOutputName.isEmpty }) {
            alert = AlertInfo(title: "Output Name Missing", message: "Give each photo an output name, then try again.")
            return
        }
        let names = pending.map { $0.sanitizedOutputName.lowercased() }
        if let duplicate = Set(names).first(where: { name in names.count(where: { $0 == name }) > 1 }) {
            alert = AlertInfo(
                title: "Duplicate Output Name",
                message: "More than one photo has the output name “\(duplicate)”. Give each photo a different name."
            )
            return
        }

        let existing = pending.map(\.sanitizedOutputName).filter { name in
            settings.widths.contains { width in
                let file = ConversionPipeline.outputFileName(name: name, width: width)
                return FileManager.default.fileExists(atPath: folder.url.appending(path: file).path)
            }
        }
        if existing.isEmpty {
            startProcessing()
        } else {
            overwriteNames = existing
            isConfirmingOverwrite = true
        }
    }

    func startProcessing() {
        overwriteNames = []
        guard let folder = destinationFolder else { return }
        do {
            try queue.process(into: folder, settings: settings)
        } catch {
            alert = AlertInfo(title: "Cannot Process Photos", message: error.localizedDescription)
        }
    }

    // MARK: - Persistence

    private func save(_ value: some Encodable, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private static func load<Value: Decodable>(_ type: Value.Type, from defaults: UserDefaults, forKey key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
