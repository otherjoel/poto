import Foundation

/// A message for the app-wide alert.
nonisolated struct AlertInfo: Identifiable, Equatable, Sendable {
    let id = UUID()
    let title: String
    let message: String
}
