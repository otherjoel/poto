import QuickLook
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @State private var isDropTargeted = false

    var body: some View {
        @Bindable var model = model

        NavigationSplitView {
            SidebarView()
        } content: {
            Group {
                if let folder = model.selectedFolder {
                    OutputListView(folder: folder)
                } else {
                    QueueListView()
                }
            }
            .navigationSplitViewColumnWidth(
                min: Design.listWidth.min,
                ideal: Design.listWidth.ideal,
                max: Design.listWidth.max
            )
        } detail: {
            if model.selectedFolder != nil {
                OutputDetailView()
            } else {
                QueueDetailView()
            }
        }
        .onDrop(of: DropImporter.acceptedTypes, isTargeted: $isDropTargeted, perform: openDrop)
        .overlay {
            DropHighlightView()
                .opacity(isDropTargeted ? 1 : 0)
                .animation(Design.feedback, value: isDropTargeted)
        }
        .fileImporter(
            isPresented: $model.isOpenPanelPresented,
            allowedContentTypes: SourceScanner.contentTypes + [.folder],
            allowsMultipleSelection: true,
            onCompletion: open
        )
        .fileDialogMessage("Choose photos, or a folder of photos.")
        .sheet(isPresented: $model.isPhotosPickerPresented) {
            PhotosPickerSheet(onCompletion: openPicked)
                .frame(minWidth: 720, idealWidth: 960, minHeight: 520, idealHeight: 680)
        }
        .sheet(item: $model.editingFolder, content: FolderSettingsView.init)
        .quickLookPreview($model.quickLookURL)
        .alert(
            model.alert?.title ?? "",
            isPresented: $model.isAlertPresented,
            presenting: model.alert
        ) { _ in
        } message: { alert in
            Text(alert.message)
        }
    }

    private func openDrop(_ providers: [NSItemProvider]) -> Bool {
        // Promises first. For a drag from Photos, the item providers give a reduced
        // derivative from the library; the promise gives the real export.
        let receivers = PromisedFileImporter.receiversOnDragPasteboard()
        if receivers.isEmpty {
            model.open(providers)
        } else {
            model.open(receivers)
        }
        return true
    }

    private func openPicked(_ providers: [NSItemProvider]) {
        model.isPhotosPickerPresented = false
        if !providers.isEmpty {
            model.open(providers)
        }
    }

    private func open(_ result: Result<[URL], any Error>) {
        if case .success(let urls) = result {
            model.open(urls)
        }
    }
}
