import Foundation
import CoreGraphics

/// Keeps list thumbnails in memory. The key includes the modification date, so a
/// file that was processed again gets a new thumbnail.
final class ThumbnailCache {
    static let shared = ThumbnailCache()

    private let cache = NSCache<NSString, CGImage>()

    init() {
        cache.countLimit = 500
    }

    func thumbnail(for url: URL, version: Date) async -> CGImage? {
        let key = "\(url.path)|\(version.timeIntervalSinceReferenceDate)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let decoded = await ImageDecoder.decode(url, maxPixelSize: Design.thumbnailPixelSize, hdr: false) else {
            return nil
        }
        cache.setObject(decoded.image, forKey: key)
        return decoded.image
    }
}
