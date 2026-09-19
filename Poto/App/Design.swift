import SwiftUI

/// Shared layout and timing values, so the views stay uniform.
enum Design {
    static let rowThumbnailSize = 44.0
    static let thumbnailCornerRadius = 5.0
    static let thumbnailPixelSize = 176
    static let previewPixelSize = 3200
    static let previewPadding = 20.0
    static let barSpacing = 12.0

    static let sidebarWidth = (min: 180.0, ideal: 210.0, max: 300.0)
    static let listWidth = (min: 260.0, ideal: 310.0, max: 460.0)

    static let feedback = Animation.easeOut(duration: 0.15)
    /// How long "Copied" stays visible.
    static let copiedDuration = Duration.seconds(1.5)
}
