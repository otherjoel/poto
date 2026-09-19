import SwiftUI

/// Chooses the output folder that processed photos go to.
struct DestinationPicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        if model.folders.isEmpty {
            Button("Add Output Folder…", systemImage: "folder.badge.plus", action: showAddFolderPanel)
                .labelStyle(.titleAndIcon)
                .help("Choose where processed images go")
        } else {
            Picker("Destination", selection: $model.destinationID) {
                ForEach(model.folders) { folder in
                    // Text, not Label: a toolbar shows a Label as its icon only, and
                    // the name of the destination must stay visible.
                    Text(folder.displayName)
                        .tag(OutputFolder.ID?.some(folder.id))
                }
            }
            .accessibilityLabel("Destination")
            .help("The output folder for processed images")
        }
    }

    private func showAddFolderPanel() {
        model.isAddFolderPanelPresented = true
    }
}
