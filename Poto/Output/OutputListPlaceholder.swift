import SwiftUI

/// The empty states of the image set list.
struct OutputListPlaceholder: View {
    @Environment(AppModel.self) private var model
    let folder: OutputFolder

    var body: some View {
        if model.folderIsMissing {
            ContentUnavailableView(
                "Folder Not Found",
                systemImage: "folder.badge.questionmark",
                description: Text("\(folder.abbreviatedPath) cannot be read. Choose a new location in Folder Settings.")
            )
        } else if model.imageSets.isEmpty {
            ContentUnavailableView(
                "No Images",
                systemImage: "photo.on.rectangle",
                description: Text("Processed photos that go to this folder show here.")
            )
        } else if model.visibleSets.isEmpty {
            ContentUnavailableView.search
        }
    }
}
