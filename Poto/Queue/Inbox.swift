import Foundation
import UniformTypeIdentifiers

/// Holds photos that arrive as promised files, for example from the Photos app.
/// Such a file is temporary at its source, so Poto keeps its own copy until the
/// photo leaves the list. The folder is emptied at each launch.
nonisolated enum Inbox {
    static var directory: URL {
        let bundleID = Bundle.main.bundleIdentifier ?? "com.joeldueck.Poto"
        return URL.cachesDirectory.appending(path: "\(bundleID)/Inbox")
    }

    /// Copies `file` into the inbox, under `suggestedName` if there is one, else under
    /// its own name. Each file gets its own subfolder, so two photos with the same name
    /// do not collide.
    static func adopt(_ file: URL, suggestedName: String? = nil) throws -> URL {
        let folder = directory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let target = folder.appending(path: fileName(for: file, suggestedName: suggestedName))
        try FileManager.default.copyItem(at: file, to: target)
        return target
    }

    /// The suggested name with the extension of `file`. The temporary file of an item
    /// provider can have a random name, and the suggested name, for example "IMG_1234"
    /// from the Photos picker, often has no extension.
    static func fileName(for file: URL, suggestedName: String?) -> String {
        var base = suggestedName?
            .replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let suggestedExtension = (base as NSString).pathExtension
        if let type = UTType(filenameExtension: suggestedExtension), type.conforms(to: .image) {
            base = (base as NSString).deletingPathExtension
        }
        guard !base.isEmpty, !base.hasPrefix(".") else { return file.lastPathComponent }
        return file.pathExtension.isEmpty ? base : "\(base).\(file.pathExtension)"
    }

    /// SwiftUI receives promised files into a folder of this name in the caches, says
    /// they are "in place", and never deletes them.
    static let promiseFolderPrefix = "com.apple.SwiftUI.filePromises-"

    static func isInPromiseFolder(_ url: URL) -> Bool {
        let folder = url.deletingLastPathComponent()
        return folder.lastPathComponent.hasPrefix(promiseFolderPrefix)
            && folder.deletingLastPathComponent().standardizedFileURL.path == URL.cachesDirectory.standardizedFileURL.path
    }

    /// Moves a received promised file into the inbox and deletes its promise folder,
    /// so the inbox rules clean it up. Only for files where `isInPromiseFolder` is true.
    static func adoptPromisedFile(_ file: URL) throws -> URL {
        let folder = directory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let target = folder.appending(path: file.lastPathComponent)
        try FileManager.default.moveItem(at: file, to: target)
        let promiseFolder = file.deletingLastPathComponent()
        if (try? FileManager.default.contentsOfDirectory(atPath: promiseFolder.path))?.isEmpty == true {
            try? FileManager.default.removeItem(at: promiseFolder)
        }
        return target
    }

    static func contains(_ url: URL) -> Bool {
        url.standardizedFileURL.path.hasPrefix(directory.standardizedFileURL.path + "/")
    }

    /// Deletes the inbox copy of `url`. Does nothing for a file outside the inbox.
    static func discard(_ url: URL) {
        guard contains(url) else { return }
        try? FileManager.default.removeItem(at: url.deletingLastPathComponent())
    }

    static func removeAll() {
        try? FileManager.default.removeItem(at: directory)
    }
}
