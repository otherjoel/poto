import Foundation

/// Runs one command-line tool to completion without blocking a thread.
nonisolated enum ProcessRunner {
    /// Holds the process so the cancellation handler can reach it.
    private final class Box: @unchecked Sendable {
        let process = Process()
    }

    /// - Returns: The standard output of the tool.
    /// - Throws: `PipelineError.toolFailed` on a non-zero exit, `CancellationError` on cancel.
    @discardableResult
    static func run(
        _ executable: URL,
        _ arguments: [String],
        in directory: URL,
        environment: [String: String] = ToolLocator.environment
    ) async throws -> String {
        try Task.checkCancellation()

        // Output goes to files, not pipes. A pipe that fills up blocks the child,
        // and draining two pipes needs more machinery than this does.
        let logID = UUID().uuidString
        let outURL = directory.appending(path: ".\(logID).out")
        let errURL = directory.appending(path: ".\(logID).err")
        let manager = FileManager.default
        manager.createFile(atPath: outURL.path, contents: nil)
        manager.createFile(atPath: errURL.path, contents: nil)
        defer {
            try? manager.removeItem(at: outURL)
            try? manager.removeItem(at: errURL)
        }

        let box = Box()
        let process = box.process
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = directory
        process.environment = environment
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = try FileHandle(forWritingTo: outURL)
        process.standardError = try FileHandle(forWritingTo: errURL)

        let status: Int32 = try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { finished in
                    continuation.resume(returning: finished.terminationStatus)
                }
                do {
                    try process.run()
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: error)
                    return
                }
                // A cancel that arrived before the launch had nothing to terminate.
                if Task.isCancelled {
                    process.terminate()
                }
            }
        } onCancel: {
            // `terminate()` raises an exception on a process that has not started.
            if box.process.isRunning {
                box.process.terminate()
            }
        }

        try Task.checkCancellation()

        let output = (try? String(contentsOf: outURL, encoding: .utf8)) ?? ""
        guard status == 0 else {
            let errors = (try? String(contentsOf: errURL, encoding: .utf8)) ?? ""
            throw PipelineError.toolFailed(
                tool: executable.lastPathComponent,
                status: status,
                message: summary(of: errors.isEmpty ? output : errors)
            )
        }
        return output
    }

    /// The last lines of a tool's output, where the cause usually is. Whole lines
    /// only, and never the middle of one.
    static func summary(of output: String, maxLines: Int = 3) -> String {
        output
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.allSatisfy { $0 == "^" || $0 == "~" } }
            .suffix(maxLines)
            .joined(separator: "\n")
    }
}
