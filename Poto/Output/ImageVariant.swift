import Foundation

/// One file of an image set.
nonisolated struct ImageVariant: Identifiable, Hashable, Sendable {
    let url: URL
    /// The width from the `-<width>` filename suffix. `nil` for a file without one.
    let width: Int?
    let byteCount: Int
    let modified: Date

    var id: URL { url }

    var label: String {
        if let width { "\(width) px" } else { "Original" }
    }
}
