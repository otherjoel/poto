import Foundation
import UniformTypeIdentifiers

/// Turns opened or dropped URLs into a list of image files.
nonisolated enum SourceScanner {
    static let contentTypes: [UTType] = [.image]

    /// Any bitmap image. Camera raw and SVG files are not accepted: ImageMagick
    /// needs more delegates for them than a usual install has.
    static func isSource(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return isSource(type)
    }

    static func isSource(_ type: UTType) -> Bool {
        type.conforms(to: .image) && !type.conforms(to: .rawImage) && !type.conforms(to: .svg)
    }

    static func isHEIF(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .heic) || type.conforms(to: .heif)
    }

    /// Files pass through if they are images. Folders give the image files directly
    /// inside them, sorted by name. Subfolders are not searched.
    @concurrent
    static func expand(_ urls: [URL]) async -> [URL] {
        var result: [URL] = []
        for url in urls {
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
            if isDirectory {
                let children = (try? FileManager.default.contentsOfDirectory(
                    at: url,
                    includingPropertiesForKeys: nil,
                    options: [.skipsHiddenFiles]
                )) ?? []
                result += children
                    .filter(isSource)
                    .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            } else if isSource(url) {
                result.append(url)
            }
        }
        return result.map(\.standardizedFileURL)
    }
}
