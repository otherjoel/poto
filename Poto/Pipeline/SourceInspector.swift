import Foundation
import ImageIO

/// Looks at a source photo to choose its pipeline.
nonisolated enum SourceInspector {
    /// True for the HDR photos of iPhone 12 and later. `apple-hdr-heic-decoder` reads
    /// their gain map; every other image goes through the SDR pipeline.
    static func hasAppleHDRGainMap(_ url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return false }
        return CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeHDRGainMap) != nil
    }

    /// The URLs from `urls` that have an Apple HDR gain map.
    @concurrent
    static func photosWithGainMap(in urls: [URL]) async -> Set<URL> {
        Set(urls.filter(hasAppleHDRGainMap))
    }
}
