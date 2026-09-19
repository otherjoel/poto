import Foundation

/// Finds the pipeline tools. An app started from Finder does not get the shell's
/// PATH, so the usual install locations are searched directly.
nonisolated enum ToolLocator {
    static var searchDirectories: [URL] {
        let home = URL.homeDirectory
        return [
            URL(filePath: "/opt/homebrew/bin"),
            URL(filePath: "/usr/local/bin"),
            home.appending(path: ".local/bin"),
            home.appending(path: ".cargo/bin"),
            URL(filePath: "/usr/bin"),
        ]
    }

    static func locate(_ tool: Tool) -> URL? {
        searchDirectories
            .map { $0.appending(path: tool.rawValue) }
            .first { FileManager.default.isExecutableFile(atPath: $0.path) }
    }

    static func locateAll() -> [Tool: URL] {
        var found: [Tool: URL] = [:]
        for tool in Tool.allCases {
            found[tool] = locate(tool)
        }
        return found
    }

    /// The environment for child processes. The search directories go first on PATH
    /// so that tools which start other tools (uv, magick delegates) find them.
    static var environment: [String: String] {
        var environment = ProcessInfo.processInfo.environment
        let inherited = environment["PATH"] ?? "/usr/bin:/bin"
        let ours = searchDirectories.map(\.path).joined(separator: ":")
        environment["PATH"] = "\(ours):\(inherited)"
        return environment
    }
}
