import SwiftUI

/// Shows where each command-line tool was found, and how to install a missing one.
struct ToolsSettingsView: View {
    @State private var locations: [Tool: URL] = [:]

    var body: some View {
        Form {
            Section {
                ForEach(Tool.allCases) { tool in
                    ToolRow(tool: tool, location: locations[tool])
                }
            } footer: {
                Text("Poto runs these command-line tools. HDR photos use the same steps as heic-to-hdr-avif.sh. It looks in the Homebrew folders, ~/.local/bin and /usr/bin.")
                    .settingsFooter()
            }
            Section {
                Button("Check Again", action: locate)
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: locate)
    }

    private func locate() {
        locations = ToolLocator.locateAll()
    }
}
