import Foundation
import ImageIO

nonisolated enum ImageDecoder {
    /// Decodes an image off the main actor, scaled down to `maxPixelSize` and with its
    /// orientation applied. With `hdr`, gain-map images (Apple HEIC, AVIF) decode to HDR.
    @concurrent
    static func decode(_ url: URL, maxPixelSize: Int, hdr: Bool) async -> DecodedImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }

        var options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        if hdr {
            options[kCGImageSourceDecodeRequest] = kCGImageSourceDecodeToHDR
        }
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        var width = properties?[kCGImagePropertyPixelWidth] as? Int ?? image.width
        var height = properties?[kCGImagePropertyPixelHeight] as? Int ?? image.height
        // Orientations 5–8 are rotated by 90°, so the displayed size is swapped.
        if let orientation = properties?[kCGImagePropertyOrientation] as? Int, orientation >= 5 {
            swap(&width, &height)
        }
        return DecodedImage(image: image, pixelWidth: width, pixelHeight: height)
    }
}
