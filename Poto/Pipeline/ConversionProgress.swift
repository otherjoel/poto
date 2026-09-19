import Foundation

nonisolated struct ConversionProgress: Equatable, Sendable {
    var stage: ConversionStage
    var completedUnits: Int
    var totalUnits: Int

    var fraction: Double {
        totalUnits > 0 ? Double(completedUnits) / Double(totalUnits) : 0
    }
}
