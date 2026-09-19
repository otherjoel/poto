import Foundation

/// Counts finished units of work and sends each change to the progress stream.
nonisolated struct ProgressTracker {
    let totalUnits: Int
    let continuation: AsyncStream<ConversionProgress>.Continuation
    private var completedUnits = 0

    init(totalUnits: Int, continuation: AsyncStream<ConversionProgress>.Continuation) {
        self.totalUnits = totalUnits
        self.continuation = continuation
    }

    func report(_ stage: ConversionStage) {
        continuation.yield(ConversionProgress(stage: stage, completedUnits: completedUnits, totalUnits: totalUnits))
    }

    mutating func complete(_ stage: ConversionStage) {
        completedUnits += 1
        report(stage)
    }
}
