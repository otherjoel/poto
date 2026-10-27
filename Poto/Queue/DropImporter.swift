import Foundation
import UniformTypeIdentifiers

/// Turns the items of a drop into file URLs.
///
/// Files and folders from Finder are used in place. A drag with file promises does not
/// come here; `PromisedFileImporter` takes it. The inbox branches below are for a source
/// that gives image data with no file and no promise.
nonisolated enum DropImporter {
    static let acceptedTypes: [UTType] = [.fileURL, .image]

    static func urls(from providers: [NSItemProvider]) async -> [URL] {
        var urls: [URL] = []
        for provider in providers {
            if let url = await url(from: provider) {
                urls.append(url)
            }
        }
        return urls
    }

    private static func url(from provider: NSItemProvider) async -> URL? {
        if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
           let url = await fileURL(from: provider) {
            return url
        }
        guard let type = preferredImageType(among: provider.registeredTypeIdentifiers) else { return nil }
        return await receivedFile(from: provider, type: type)
    }

    /// HEIC first: only the HEIC of an iPhone HDR photo has the gain map. After that,
    /// the order of the source, which lists its best representation first. Types that
    /// Poto cannot open, such as the DNG of a ProRAW photo, are skipped.
    static func preferredImageType(among identifiers: [String]) -> UTType? {
        let types = identifiers
            .compactMap { UTType($0) }
            .filter(SourceScanner.isSource)
        return types.first { $0.conforms(to: .heic) || $0.conforms(to: .heif) } ?? types.first
    }

    /// Reads the URL from its data form. `loadObject(ofClass: URL.self)` gives nothing
    /// for the file URLs of a macOS drag.
    private static func fileURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            _ = provider.loadDataRepresentation(for: .fileURL) { data, _ in
                let url = data.flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
                continuation.resume(returning: url?.isFileURL == true ? url?.standardizedFileURL : nil)
            }
        }
    }

    /// An image file on disk comes back in place, as itself. A promised file comes back
    /// as a temporary file, or "in place" in a SwiftUI promise folder. Both go into the inbox.
    private static func receivedFile(from provider: NSItemProvider, type: UTType) async -> URL? {
        let suggestedName = provider.suggestedName
        return await withCheckedContinuation { continuation in
            _ = provider.loadFileRepresentation(for: type, openInPlace: true) { url, isInPlace, _ in
                guard let url else {
                    continuation.resume(returning: nil)
                    return
                }
                if !isInPlace {
                    // The file is deleted when this handler returns, so copy it now.
                    continuation.resume(returning: try? Inbox.adopt(url, suggestedName: suggestedName))
                } else if Inbox.isInPromiseFolder(url) {
                    continuation.resume(returning: try? Inbox.adoptPromisedFile(url))
                } else {
                    continuation.resume(returning: url.standardizedFileURL)
                }
            }
        }
    }
}
