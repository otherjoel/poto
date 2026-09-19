import SwiftUI
import UniformTypeIdentifiers

/// The sheet that edits one output folder: its location, name and snippet template.
struct FolderSettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var draft: OutputFolder
    @State private var isChoosingFolder = false
    @State private var folderChoice = FolderChoice.location

    init(folder: OutputFolder) {
        _draft = State(initialValue: folder)
    }

    /// A real set from the folder if it is open, so the example is familiar.
    private var exampleSet: ImageSet {
        let real = model.selectedFolder?.id == draft.id ? (model.selectedSet ?? model.visibleSets.first) : nil
        return real ?? SnippetTemplate.exampleSet
    }

    var body: some View {
        Form {
            Section("Folder") {
                LabeledContent("Location") {
                    HStack {
                        Text(draft.abbreviatedPath)
                            .lineLimit(1)
                            .truncationMode(.head)
                            .textSelection(.enabled)
                        Button("Choose…", action: chooseLocation)
                    }
                }
                TextField("Name", text: $draft.customName, prompt: Text(draft.url.lastPathComponent))
            }
            Section {
                LabeledContent("Save Copy To") {
                    HStack {
                        Text(draft.abbreviatedOriginalsPath ?? "None")
                            .foregroundStyle(draft.originalsURL == nil ? .secondary : .primary)
                            .lineLimit(1)
                            .truncationMode(.head)
                        Button("Choose…", action: chooseOriginalsFolder)
                        Button("Remove", action: removeOriginalsFolder)
                            .disabled(draft.originalsURL == nil)
                    }
                }
            } header: {
                Text("Originals")
            } footer: {
                OriginalsFooter(isOutputFolder: draft.originalsFolderIsOutputFolder)
            }
            Section {
                TextField("Template", text: $draft.snippetTemplate, axis: .vertical)
                    .font(.body.monospaced())
                    .lineLimit(2...6)
                    .autocorrectionDisabled()
                LabeledContent("Example") {
                    Text(SnippetTemplate.render(draft.snippetTemplate, for: exampleSet))
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }
            } header: {
                Text("Snippet")
            } footer: {
                SnippetPlaceholderList()
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 520, idealWidth: 560)
        .fixedSize(horizontal: false, vertical: true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel, action: cancel)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(draft.originalsFolderIsOutputFolder)
            }
        }
        // One importer for both folders: a view shows only one of two importers.
        .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder], onCompletion: setFolder)
    }

    private func chooseLocation() {
        folderChoice = .location
        isChoosingFolder = true
    }

    private func chooseOriginalsFolder() {
        folderChoice = .originals
        isChoosingFolder = true
    }

    private func removeOriginalsFolder() {
        draft.originalsURL = nil
    }

    private func setFolder(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        switch folderChoice {
        case .location: draft.url = url.standardizedFileURL
        case .originals: draft.originalsURL = url.standardizedFileURL
        }
    }

    private func cancel() {
        dismiss()
    }

    private func save() {
        model.update(draft)
        dismiss()
    }
}
