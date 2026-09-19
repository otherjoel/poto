import Foundation

nonisolated struct PreviewRequest: Hashable, Sendable {
    let url: URL
    let version: Date
    let hdr: Bool
}
