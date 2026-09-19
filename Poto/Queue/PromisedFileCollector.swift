import Foundation

/// Gathers promised files as they arrive on a background queue, and reports the
/// complete list exactly once.
nonisolated final class PromisedFileCollector: @unchecked Sendable {
    private let lock = NSLock()
    private let expected: Int
    private var received = 0
    private var files: [(order: Int, url: URL)] = []

    init(expected: Int) {
        self.expected = expected
    }

    /// - Returns: All files in drag order when the last one is in; `nil` before that.
    func add(_ url: URL?, order: Int) -> [URL]? {
        lock.lock()
        defer { lock.unlock() }
        received += 1
        if let url {
            files.append((order, url))
        }
        guard received == expected else { return nil }
        return files.sorted { $0.order < $1.order }.map(\.url)
    }
}
