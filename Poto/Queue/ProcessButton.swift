import SwiftUI

/// Starts a run, or stops the run in progress.
struct ProcessButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        if model.queue.isProcessing {
            Button("Stop", systemImage: "stop.fill", action: model.queue.cancel)
                .labelStyle(.titleAndIcon)
                .help("Stop processing (⌘.)")
        } else {
            Button("Process", systemImage: "play.fill", action: model.requestProcessing)
                .labelStyle(.titleAndIcon)
                .disabled(!model.canProcess)
                .help("Process the photos into the destination folder (⌘↩)")
                .confirmationDialog(
                    "Replace ^[\(model.overwriteNames.count) existing image set](inflect: true)?",
                    isPresented: $model.isConfirmingOverwrite
                ) {
                    Button("Replace", role: .destructive, action: model.startProcessing)
                } message: {
                    Text("The destination folder already contains: \(model.overwriteNames.formatted(.list(type: .and))).")
                }
        }
    }
}
