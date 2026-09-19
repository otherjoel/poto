import SwiftUI

/// The detail column for an output folder.
struct OutputDetailView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if let set = model.selectedSet, let snippet = model.selectedSnippet {
            ImageSetDetailView(imageSet: set, snippet: snippet)
                .id(set.id)
        } else {
            ContentUnavailableView(
                "No Image Selected",
                systemImage: "photo",
                description: Text("Select an image to see it and to copy its snippet.")
            )
        }
    }
}
