import CoreImage
import Foundation

/// Makes the HDR image of a gain-map photo with macOS itself.
///
/// `apple-hdr-heic-decoder` accepts only `.heic` files. iPhone JPEGs, and the JPEGs that
/// Photos exports, carry the same Apple gain map, so Core Image decodes those. On a
/// HEIC, its result is within 0.2 % (mean, in PQ code values) of the decoder's.
nonisolated enum NativeHDRDecoder {
    /// Writes a 16-bit PQ / BT.2020 PNG, the same form as the decoder's output, with
    /// the orientation of the source applied.
    static func writePQImage(from source: URL, to output: URL) throws {
        guard
            let image = CIImage(contentsOf: source, options: [.expandToHDR: true, .applyOrientationProperty: true]),
            let pq = CGColorSpace(name: CGColorSpace.itur_2100_PQ)
        else {
            throw PipelineError.hdrDecodeFailed("macOS could not read the image and its gain map.")
        }
        // A half-float working format keeps the values above SDR white.
        let context = CIContext(options: [.workingFormat: CIFormat.RGBAh])
        try context.writePNGRepresentation(of: image, to: output, format: .RGBA16, colorSpace: pq)
    }
}
