import Foundation

/// Builds the text that is copied to the clipboard for an image set.
///
/// Only the known `{placeholders}` are replaced. Every other character, other
/// braces included, passes through unchanged.
nonisolated enum SnippetTemplate {
    static let defaultTemplate = "•photo[\"{name}\" #:ext \"{ext}\"]{}"

    static let placeholders = [
        SnippetPlaceholder(token: "{name}", meaning: "Set name, without size or extension"),
        SnippetPlaceholder(token: "{ext}", meaning: "File extension"),
        SnippetPlaceholder(token: "{file}", meaning: "File name of the largest size"),
        SnippetPlaceholder(token: "{width}", meaning: "Largest width in pixels"),
        SnippetPlaceholder(token: "{widths}", meaning: "All widths, separated by spaces"),
    ]

    static func render(_ template: String, for set: ImageSet) -> String {
        // One pass, so a value that happens to contain a token is not expanded again.
        template.replacing(/\{(name|ext|file|widths|width)\}/) { match in
            switch match.output.1 {
            case "name": set.name
            case "ext": set.ext
            case "file": set.largest?.url.lastPathComponent ?? ""
            case "width": set.largest?.width.map(String.init) ?? ""
            case "widths": set.widths.map(String.init).joined(separator: " ")
            default: String(match.output.0)
            }
        }
    }

    /// A stand-in set for the template editor when the folder is empty.
    static let exampleSet = ImageSet(
        name: "iceland-church-window",
        ext: "avif",
        variants: [500, 800, 1000, 1200, 1600].map { (width: Int) in
            ImageVariant(
                url: URL(filePath: "/iceland-church-window-\(width).avif"),
                width: width,
                byteCount: 0,
                modified: .distantPast
            )
        }
    )
}
