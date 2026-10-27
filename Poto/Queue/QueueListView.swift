import SwiftUI

/// The middle column for "Source Photos".
struct QueueListView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var queue = model.queue

        List(selection: $queue.selection) {
            ForEach(queue.photos) { photo in
                QueueRowView(photo: photo)
            }
        }
        .contextMenu(forSelectionType: SourcePhoto.ID.self) { ids in
            Button("Show in Finder", systemImage: "finder") { showInFinder(ids) }
            Divider()
            Button("Remove", systemImage: "minus.circle", role: .destructive) { queue.remove(ids) }
        }
        .onDeleteCommand(perform: removeSelected)
        .onKeyPress(.space, action: quickLook)
        .overlay {
            if queue.photos.isEmpty, queue.incomingCount == 0 {
                ContentUnavailableView {
                    Label("No Photos", systemImage: "photo.badge.plus")
                } description: {
                    Text("Drop photos or a folder on the window, choose Open, or add photos from your Photos library.")
                } actions: {
                    Button("Open…", action: showOpenPanel)
                    Button("Add from Photos…", action: showPhotosPicker)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                ReceivingBar(count: queue.incomingCount)
                BatchProgressBar(isVisible: queue.isProcessing, fraction: queue.batchFraction)
            }
        }
        .navigationTitle("Source Photos")
        .navigationSubtitle(queue.photos.isEmpty ? "" : "^[\(queue.photos.count) photo](inflect: true)")
        .toolbar {
            ToolbarItem {
                Button("Open…", systemImage: "plus", action: showOpenPanel)
                    .help("Open photos or a folder of photos (⌘O)")
            }
            ToolbarItem {
                Button("Add from Photos…", systemImage: "photo.on.rectangle.angled", action: showPhotosPicker)
                    .help("Add photos from your Photos library, iCloud photos included (⇧⌘O)")
            }
            ToolbarItem {
                Menu("More", systemImage: "ellipsis.circle") {
                    Button("Remove Finished Photos", action: queue.removeFinished)
                        .disabled(!queue.hasFinishedPhotos)
                }
            }
        }
    }

    private func showOpenPanel() {
        model.isOpenPanelPresented = true
    }

    private func showPhotosPicker() {
        model.isPhotosPickerPresented = true
    }

    private func removeSelected() {
        model.queue.remove(model.queue.selection)
    }

    private func showInFinder(_ ids: Set<SourcePhoto.ID>) {
        let urls = model.queue.photos.filter { ids.contains($0.id) }.map(\.url)
        NSWorkspace.shared.activateFileViewerSelecting(urls)
    }

    private func quickLook() -> KeyPress.Result {
        guard let photo = model.queue.selectedPhoto else { return .ignored }
        model.quickLookURL = photo.url
        return .handled
    }
}
