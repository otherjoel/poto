import SwiftUI

struct SidebarFolderRow: View {
    @Environment(AppModel.self) private var model
    let folder: OutputFolder

    private var isDestination: Bool {
        model.destinationID == folder.id
    }

    var body: some View {
        Label(folder.displayName, systemImage: "folder")
            .help(folder.abbreviatedPath)
            .contextMenu {
                Button("Use as Destination", systemImage: "arrow.down.to.line", action: useAsDestination)
                    .disabled(isDestination)
                Button("Folder Settings…", systemImage: "gearshape", action: editSettings)
                Button("Show in Finder", systemImage: "finder", action: showInFinder)
                Divider()
                Button("Remove from Sidebar", systemImage: "minus.circle", role: .destructive, action: remove)
            }
    }

    private func useAsDestination() {
        model.destinationID = folder.id
    }

    private func editSettings() {
        model.editingFolder = folder
    }

    private func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([folder.url])
    }

    private func remove() {
        model.removeFolder(folder.id)
    }
}
