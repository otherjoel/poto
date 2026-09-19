import Foundation

nonisolated enum SourcePhotoStatus: Equatable, Sendable {
    case ready
    case waiting
    case processing(ConversionProgress)
    case finished
    case failed(String)

    var isActive: Bool {
        switch self {
        case .waiting, .processing: true
        case .ready, .finished, .failed: false
        }
    }

    var isFailure: Bool {
        if case .failed = self { true } else { false }
    }
}
