import Foundation
import Testing
@testable import Poto

/// Runs the real tools on a real photo. It is off unless the environment names a sample:
///
///     TEST_RUNNER_POTO_SAMPLE_HEIC=/path/photo.heic TEST_RUNNER_POTO_OUTPUT_DIR=/path/out xcodebuild test …
@MainActor
struct PipelineIntegrationTests {
    nonisolated private static let sample = ProcessInfo.processInfo.environment["POTO_SAMPLE_HEIC"]
    nonisolated private static let outputDirectory = ProcessInfo.processInfo.environment["POTO_OUTPUT_DIR"]

    @Test(.enabled(if: sample != nil && outputDirectory != nil), .timeLimit(.minutes(10)))
    func convertsASamplePhoto() async throws {
        let source = URL(filePath: try #require(Self.sample))
        let destination = URL(filePath: try #require(Self.outputDirectory))
        let pipeline = try ConversionPipeline(settings: ProcessingSettings())

        let (stream, continuation) = AsyncStream.makeStream(of: ConversionProgress.self)
        async let outputs = pipeline.convert(
            source: source,
            outputName: source.deletingPathExtension().lastPathComponent,
            destination: destination,
            progress: continuation
        )
        var fractions: [Double] = []
        for await progress in stream {
            fractions.append(progress.fraction)
        }

        let files = try await outputs
        #expect(files.count == 5)
        #expect(files.allSatisfy { FileManager.default.fileExists(atPath: $0.path) })
        #expect(fractions == fractions.sorted())
        #expect(fractions.last == 1)
    }

    @Test(.enabled(if: sample != nil))
    func cancelStopsTheRun() async throws {
        let source = URL(filePath: try #require(Self.sample))
        let destination = FileManager.default.temporaryDirectory.appending(path: "poto-cancel-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: destination) }
        let pipeline = try ConversionPipeline(settings: ProcessingSettings())

        let task = Task {
            let (_, continuation) = AsyncStream.makeStream(of: ConversionProgress.self)
            return try await pipeline.convert(source: source, outputName: "cancelled", destination: destination, progress: continuation)
        }
        try await Task.sleep(for: .milliseconds(300))
        task.cancel()

        await #expect(throws: (any Error).self) { try await task.value }
        #expect(!FileManager.default.fileExists(atPath: destination.appending(path: "cancelled-500.avif").path))
    }
}
