import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        List(selection: $model.selection) {
            Section("Import") {
                Label("Source Photos", systemImage: "photo.stack")
                    .badge(model.queue.photos.count)
                    .tag(SidebarItem.queue)
            }
            Section("Output Folders") {
                ForEach(model.folders) { folder in
                    SidebarFolderRow(folder: folder)
                        .tag(SidebarItem.folder(folder.id))
                }
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .leading) {
            Button("Add Folder", systemImage: "plus.circle", action: showAddFolderPanel)
                .buttonStyle(.borderless)
                .padding()
                .help("Add an output folder")
        }
        .navigationSplitViewColumnWidth(
            min: Design.sidebarWidth.min,
            ideal: Design.sidebarWidth.ideal,
            max: Design.sidebarWidth.max
        )
        .fileImporter(
            isPresented: $model.isAddFolderPanelPresented,
            allowedContentTypes: [.folder],
            onCompletion: addFolder
        )
        .fileDialogMessage("Choose a folder for processed images.")
        .fileDialogConfirmationLabel("Add Folder")
    }

    private func showAddFolderPanel() {
        model.isAddFolderPanelPresented = true
    }

    private func addFolder(_ result: Result<URL, any Error>) {
        if case .success(let url) = result {
            model.addFolder(url)
        }
    }
}
