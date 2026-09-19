import SwiftUI

/// The detail column for "Source Photos": the preview and the output name.
struct QueueDetailView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        let queue = model.queue

        Group {
            if let photo = queue.selectedPhoto {
                PreviewImageView(
                    url: photo.url,
                    hdr: model.prefersHDRPreview,
                    accessibilityName: photo.url.lastPathComponent
                )
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    SourceNameBar(photo: photo)
                        .id(photo.id)
                }
            } else if queue.selection.count > 1 {
                ContentUnavailableView(
                    "^[\(queue.selection.count) Photo](inflect: true) Selected",
                    systemImage: "photo.stack",
                    description: Text("Select one photo to see it and to change its output name.")
                )
            } else {
                ContentUnavailableView(
                    "No Photo Selected",
                    systemImage: "photo",
                    description: Text("Select a photo to see it and to change its output name.")
                )
            }
        }
        .toolbar {
            ToolbarItem {
                Toggle("HDR", systemImage: "sun.max", isOn: $model.prefersHDRPreview)
                    .help("Show the preview in HDR")
            }
            ToolbarItem {
                DestinationPicker()
            }
            ToolbarItem(placement: .primaryAction) {
                ProcessButton()
            }
        }
    }
}
