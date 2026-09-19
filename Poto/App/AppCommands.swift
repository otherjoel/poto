import SwiftUI

struct AppCommands: Commands {
    @Bindable var model: AppModel

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open…", action: showOpenPanel)
                .keyboardShortcut("o")
            Button("Add Output Folder…", action: showAddFolderPanel)
                .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Copy Snippet", action: model.copySnippet)
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .disabled(model.selectedSnippet == nil)
        }

        CommandGroup(after: .sidebar) {
            Toggle("Show Previews in HDR", isOn: $model.prefersHDRPreview)
                .keyboardShortcut("h", modifiers: [.command, .option, .shift])
            Button("Reload Folder", action: reload)
                .keyboardShortcut("r")
                .disabled(model.selectedFolder == nil)
            Divider()
        }

        CommandMenu("Photos") {
            Button("Process Photos", action: model.requestProcessing)
                .keyboardShortcut(.return)
                .disabled(!model.canProcess)
            Button("Stop Processing", action: model.queue.cancel)
                .keyboardShortcut(".")
                .disabled(!model.queue.isProcessing)
            Divider()
            Button("Remove Finished Photos", action: model.queue.removeFinished)
                .disabled(!model.queue.hasFinishedPhotos)
        }
    }

    private func showOpenPanel() {
        model.selection = .queue
        model.isOpenPanelPresented = true
    }

    private func showAddFolderPanel() {
        model.isAddFolderPanelPresented = true
    }

    private func reload() {
        Task { await model.reloadSets() }
    }
}
