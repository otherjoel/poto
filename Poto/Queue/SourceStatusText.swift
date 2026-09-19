import SwiftUI

/// One line of text below the output name: the file names, the current step, or the error.
struct SourceStatusText: View {
    let status: SourcePhotoStatus
    let hint: String

    var body: some View {
        Group {
            switch status {
            case .ready:
                Text(hint)
            case .waiting:
                Text("Waiting…")
            case .processing(let progress):
                Text("\(progress.stage.label)…")
            case .finished:
                Label("Finished", systemImage: "checkmark.circle")
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .textSelection(.enabled)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .lineLimit(4)
    }
}
