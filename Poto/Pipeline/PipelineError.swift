import Foundation

nonisolated enum PipelineError: LocalizedError, Equatable {
    case missingTools([Tool])
    case toolFailed(tool: String, status: Int32, message: String)
    case missingOutput(String)
    case hdrDecodeFailed(String)
    case originalNotSaved(String)

    var errorDescription: String? {
        switch self {
        case .missingTools(let tools):
            "Required tools not found: \(tools.map(\.rawValue).joined(separator: ", ")). See Settings > Tools."
        case .toolFailed(let tool, let status, let message):
            message.isEmpty ? "\(tool) failed with status \(status)." : "\(tool) failed with status \(status): \(message)"
        case .hdrDecodeFailed(let message):
            "The HDR decoder could not read this photo. \(message)"
        case .originalNotSaved(let message):
            "The images were made, but the copy of the original was not saved. \(message)"
        case .missingOutput(let name):
            "The pipeline did not produce \(name)."
        }
    }
}
