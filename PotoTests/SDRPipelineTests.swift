import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers
@testable import Poto

/// Runs the SDR path with the real tools on a small generated image. Off on a
/// machine that does not have the tools.
@MainActor
struct SDRPipelineTests {
    nonisolated private static let hasTools = ToolLocator.locateAll().count == Tool.allCases.count

    /// Writes a 120 × 80 gradient in the given color space.
    private func makeImage(at url: URL, type: UTType, colorSpace: CFString, orientation: Int = 1) throws {
        let space = try #require(CGColorSpace(name: colorSpace))
        let context = try #require(CGContext(
            data: nil, width: 120, height: 80, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ))
        let gradient = try #require(CGGradient(
            colorsSpace: space,
            colors: [CGColor(red: 1, green: 0.2, blue: 0.1, alpha: 1), CGColor(red: 0.1, green: 0.3, blue: 1, alpha: 1)] as CFArray,
            locations: nil
        ))
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 120, y: 80), options: [])
        let image = try #require(context.makeImage())
        let destination = try #require(CGImageDestinationCreateWithURL(url as CFURL, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
    }

    private func convert(_ source: URL, into destination: URL) async throws -> [URL] {
        var settings = ProcessingSettings()
        settings.widths = [60, 240]
        settings.speed = 10
        settings.author = "Test Author"
        let pipeline = try ConversionPipeline(settings: settings)
        let (_, continuation) = AsyncStream.makeStream(of: ConversionProgress.self)
        return try await pipeline.convert(source: source, outputName: "out", destination: destination, progress: continuation)
    }

    private func pixelSize(of url: URL) throws -> (width: Int, height: Int) {
        let source = try #require(CGImageSourceCreateWithURL(url as CFURL, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        return (image.width, image.height)
    }

    @Test(.enabled(if: hasTools), arguments: [UTType.jpeg, .png, .tiff])
    func convertsAnSDRImage(type: UTType) async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "poto-sdr-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appending(path: "source.\(try #require(type.preferredFilenameExtension))")
        try makeImage(at: source, type: type, colorSpace: CGColorSpace.displayP3)

        let outputs = try await convert(source, into: folder.appending(path: "out"))
        #expect(outputs.map(\.lastPathComponent) == ["out-60.avif", "out-240.avif"])
        #expect(try pixelSize(of: outputs[0]) == (60, 40))
        // A width above the source width upscales, so that every set has every size.
        #expect(try pixelSize(of: outputs[1]) == (240, 160))
    }

    @Test(.enabled(if: hasTools))
    func appliesTheOrientationOfAJPEG() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "poto-sdr-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appending(path: "rotated.jpg")
        // Orientation 6: the stored 120 × 80 pixels show as 80 × 120.
        try makeImage(at: source, type: .jpeg, colorSpace: CGColorSpace.sRGB, orientation: 6)

        let outputs = try await convert(source, into: folder.appending(path: "out"))
        #expect(try pixelSize(of: outputs[0]) == (60, 90))
    }
}
