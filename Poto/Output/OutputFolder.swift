import Foundation

/// A folder that receives processed images, with its own snippet template.
nonisolated struct OutputFolder: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var url: URL
    /// Shown in the sidebar. Empty means "use the folder name".
    var customName = ""
    var snippetTemplate = SnippetTemplate.defaultTemplate
    /// Where to save an unmodified copy of each processed photo. `nil` saves none.
    var originalsURL: URL?

    var displayName: String {
        customName.isEmpty ? url.lastPathComponent : customName
    }

    /// The path with the home directory written as `~`.
    var abbreviatedPath: String {
        Self.abbreviate(url)
    }

    var abbreviatedOriginalsPath: String? {
        originalsURL.map(Self.abbreviate)
    }

    /// Originals in the output folder itself would show in its list as image sets.
    var originalsFolderIsOutputFolder: Bool {
        originalsURL?.standardizedFileURL.path == url.standardizedFileURL.path
    }

    private static func abbreviate(_ url: URL) -> String {
        (url.path as NSString).abbreviatingWithTildeInPath
    }
}
