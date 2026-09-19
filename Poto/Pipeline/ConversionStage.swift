import Foundation

nonisolated enum ConversionStage: Equatable, Sendable {
    case preparing
    case decodingHDR
    case extractingSDR
    case fixingGrayscale
    case encoding
    case finishing

    var label: String {
        switch self {
        case .preparing: "Preparing image"
        case .decodingHDR: "Decoding HDR"
        case .extractingSDR: "Extracting SDR base"
        case .fixingGrayscale: "Converting grayscale to RGB"
        case .encoding: "Encoding sizes"
        case .finishing: "Moving files"
        }
    }
}
