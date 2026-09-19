import SwiftUI

/// The trailing status mark of a queue row. Each state has its own symbol shape,
/// so it does not depend on color.
struct PhotoStatusView: View {
    let status: SourcePhotoStatus

    var body: some View {
        switch status {
        case .ready:
            EmptyView()
        case .waiting:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Waiting")
                .help("Waiting")
        case .processing(let progress):
            ProgressView(value: progress.fraction)
                .progressViewStyle(.circular)
                .controlSize(.small)
                .accessibilityLabel(progress.stage.label)
                .help(progress.stage.label)
        case .finished:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityLabel("Finished")
                .help("Finished")
        case .failed(let message):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .accessibilityLabel("Failed")
                .help(message)
        }
    }
}
