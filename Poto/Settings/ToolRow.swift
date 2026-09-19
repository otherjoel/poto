import SwiftUI

struct ToolRow: View {
    let tool: Tool
    let location: URL?

    var body: some View {
        LabeledContent {
            if let location {
                Text(location.path)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
            } else {
                Text(tool.installHint)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .multilineTextAlignment(.trailing)
            }
        } label: {
            Label(tool.rawValue, systemImage: location == nil ? "xmark.octagon.fill" : "checkmark.circle.fill")
                .foregroundStyle(.primary, location == nil ? .red : .green)
                .accessibilityLabel("\(tool.rawValue), \(location == nil ? "not found" : "found")")
            Text(tool.purpose)
        }
    }
}
