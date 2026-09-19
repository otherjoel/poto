import Foundation

/// Saves an unmodified copy of a source photo next to the name of its output set.
nonisolated enum OriginalArchiver {
    /// `iceland-church-window` + `IMG_1234.HEIC` gives `iceland-church-window.HEIC`.
    static func fileName(outputName: String, source: URL) -> String {
        let ext = source.pathExtension
        return ext.isEmpty ? outputName : "\(outputName).\(ext)"
    }

    /// Copies `source`, byte for byte, into `folder`. An existing file with the same
    /// name is replaced. If `source` already is that file, nothing happens.
    @concurrent
    @discardableResult
    static func archive(_ source: URL, outputName: String, in folder: URL) async throws -> URL {
        let manager = FileManager.default
        let target = folder.appending(path: fileName(outputName: outputName, source: source))
        guard source.resolvingSymlinksInPath().path != target.resolvingSymlinksInPath().path else { return target }

        try manager.createDirectory(at: folder, withIntermediateDirectories: true)
        // Copy first, then swap, so a failed copy does not lose the file that was there.
        let partial = folder.appending(path: ".\(UUID().uuidString).partial")
        do {
            try manager.copyItem(at: source, to: partial)
            if manager.fileExists(atPath: target.path) {
                try manager.removeItem(at: target)
            }
            try manager.moveItem(at: partial, to: target)
        } catch {
            try? manager.removeItem(at: partial)
            throw error
        }
        return target
    }
}
