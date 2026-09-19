import Foundation

/// What the scanner needs to know about one file on disk.
nonisolated struct ImageFileEntry: Sendable {
    let url: URL
    var byteCount = 0
    var modified = Date.distantPast
}
