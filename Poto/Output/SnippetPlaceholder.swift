import Foundation

nonisolated struct SnippetPlaceholder: Identifiable, Sendable {
    let token: String
    let meaning: String

    var id: String { token }
}
