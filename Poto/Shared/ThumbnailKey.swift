import Foundation

nonisolated struct ThumbnailKey: Hashable, Sendable {
    let url: URL
    let version: Date
}
