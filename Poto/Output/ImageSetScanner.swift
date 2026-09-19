import Foundation
import UniformTypeIdentifiers

/// Reads an output folder and groups its image files into sets.
nonisolated enum ImageSetScanner {

    /// Lists the image files directly inside `folder`. Subfolders are not searched.
    @concurrent
    static func scan(folder: URL, knownWidths: Set<Int>) async throws -> [ImageSet] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .contentTypeKey]
        let urls = try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: Array(keys),
            options: [.skipsHiddenFiles]
        )
        let entries = urls.compactMap { url -> ImageFileEntry? in
            guard
                let values = try? url.resourceValues(forKeys: keys),
                values.isRegularFile == true,
                values.contentType?.conforms(to: .image) == true
            else { return nil }
            return ImageFileEntry(
                url: url,
                byteCount: values.fileSize ?? 0,
                modified: values.contentModificationDate ?? .distantPast
            )
        }
        return group(entries, knownWidths: knownWidths)
    }

    /// Groups files into sets by the `<name>-<width>.<ext>` pattern.
    ///
    /// A numeric suffix is a width only if another file shares the name, or the number
    /// is one of `knownWidths`. This keeps a lone `trip-2023.jpg` from turning into a
    /// set called "trip".
    static func group(_ entries: [ImageFileEntry], knownWidths: Set<Int>) -> [ImageSet] {
        struct Candidate {
            let entry: ImageFileEntry
            let name: String
            let width: Int
        }

        var candidates: [String: [Candidate]] = [:]
        var plain: [ImageFileEntry] = []

        for entry in entries {
            let ext = entry.url.pathExtension
            let stem = entry.url.deletingPathExtension().lastPathComponent
            if let (name, width) = splitWidthSuffix(stem) {
                candidates[ImageSet.id(name: name, ext: ext), default: []].append(
                    Candidate(entry: entry, name: name, width: width)
                )
            } else {
                plain.append(entry)
            }
        }

        var sets: [ImageSet] = []
        for group in candidates.values {
            let isSet = group.count > 1 || group.allSatisfy { knownWidths.contains($0.width) }
            guard isSet, let first = group.first else {
                plain.append(contentsOf: group.map(\.entry))
                continue
            }
            let variants = group
                .map { ImageVariant(url: $0.entry.url, width: $0.width, byteCount: $0.entry.byteCount, modified: $0.entry.modified) }
                .sorted { ($0.width ?? 0) < ($1.width ?? 0) }
            sets.append(ImageSet(name: first.name, ext: first.entry.url.pathExtension, variants: variants))
        }

        for entry in plain {
            let variant = ImageVariant(url: entry.url, width: nil, byteCount: entry.byteCount, modified: entry.modified)
            sets.append(ImageSet(
                name: entry.url.deletingPathExtension().lastPathComponent,
                ext: entry.url.pathExtension,
                variants: [variant]
            ))
        }
        return sets
    }

    /// Splits "iceland-glacier-1600" into ("iceland-glacier", 1600).
    static func splitWidthSuffix(_ stem: String) -> (name: String, width: Int)? {
        guard
            let dash = stem.lastIndex(of: "-"),
            dash != stem.startIndex
        else { return nil }
        let digits = stem[stem.index(after: dash)...]
        guard
            !digits.isEmpty,
            digits.allSatisfy(\.isASCII),
            digits.allSatisfy(\.isNumber),
            let width = Int(digits),
            width > 0
        else { return nil }
        return (String(stem[..<dash]), width)
    }
}
