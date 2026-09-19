import SwiftUI

/// The middle column for an output folder: one row per image set.
struct OutputListView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    let folder: OutputFolder

    var body: some View {
        @Bindable var model = model

        List(selection: $model.selectedSetID) {
            ForEach(model.visibleSets) { set in
                ImageSetRowView(set: set, isCopied: model.isCopied(set))
                    .draggable(SnippetTemplate.render(folder.snippetTemplate, for: set))
            }
        }
        .contextMenu(forSelectionType: ImageSet.ID.self) { ids in
            if let set = model.visibleSets.first(where: { ids.contains($0.id) }) {
                Button("Copy Snippet", systemImage: "doc.on.clipboard") { model.copySnippet(for: set) }
                Button("Show in Finder", systemImage: "finder") { showInFinder(set) }
            }
        } primaryAction: { ids in
            if let set = model.visibleSets.first(where: { ids.contains($0.id) }) {
                model.copySnippet(for: set)
            }
        }
        .onKeyPress(.space, action: quickLook)
        .overlay {
            OutputListPlaceholder(folder: folder)
        }
        .searchable(text: $model.searchText, prompt: "Search")
        .navigationTitle(folder.displayName)
        .navigationSubtitle(folder.abbreviatedPath)
        .toolbar {
            ToolbarItem {
                Menu("Sort", systemImage: "arrow.up.arrow.down") {
                    Picker("Sort By", selection: $model.sortOrder) {
                        ForEach(ImageSetSortOrder.allCases) { order in
                            Text(order.label).tag(order)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .help("Change the sort order")
            }
            ToolbarItem {
                Button("Folder Settings…", systemImage: "gearshape", action: editSettings)
                    .help("Change the snippet template of this folder")
            }
        }
        .task(id: folder) {
            await model.reloadSets()
        }
        .onChange(of: scenePhase) {
            // Files can change while another app is in front.
            if scenePhase == .active {
                Task { await model.reloadSets() }
            }
        }
    }

    private func editSettings() {
        model.editingFolder = folder
    }

    private func showInFinder(_ set: ImageSet) {
        NSWorkspace.shared.activateFileViewerSelecting(set.variants.map(\.url))
    }

    private func quickLook() -> KeyPress.Result {
        guard let url = model.selectedSet?.largest?.url else { return .ignored }
        model.quickLookURL = url
        return .handled
    }
}
