import SwiftUI

struct SettingsView: View {
    private enum Pane: Hashable {
        case encoding, metadata, tools
    }

    @State private var pane = Pane.encoding

    var body: some View {
        TabView(selection: $pane) {
            Tab("Encoding", systemImage: "slider.horizontal.3", value: Pane.encoding) {
                EncodingSettingsView()
            }
            Tab("Metadata", systemImage: "tag", value: Pane.metadata) {
                MetadataSettingsView()
            }
            Tab("Tools", systemImage: "wrench.and.screwdriver", value: Pane.tools) {
                ToolsSettingsView()
            }
        }
        .scenePadding()
        .frame(width: 540)
    }
}
