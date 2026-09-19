import SwiftUI

/// A small square thumbnail for list rows.
struct ThumbnailView: View {
    let url: URL
    /// Changes when the file changes, to load the thumbnail again.
    var version = Date.distantPast

    @State private var image: CGImage?

    var body: some View {
        Rectangle()
            .fill(.quaternary)
            .overlay {
                if let image {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFill()
                }
            }
            .frame(width: Design.rowThumbnailSize, height: Design.rowThumbnailSize)
            .clipShape(.rect(cornerRadius: Design.thumbnailCornerRadius))
            .accessibilityHidden(true)
            .task(id: ThumbnailKey(url: url, version: version)) {
                image = await ThumbnailCache.shared.thumbnail(for: url, version: version)
            }
    }
}
