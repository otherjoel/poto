import CoreGraphics

/// A decoded image plus the pixel size of the file it came from, which can be
/// larger than the decoded image.
nonisolated struct DecodedImage: Sendable {
    let image: CGImage
    let pixelWidth: Int
    let pixelHeight: Int

    var aspectRatio: Double {
        image.height > 0 ? Double(image.width) / Double(image.height) : 1
    }
}
