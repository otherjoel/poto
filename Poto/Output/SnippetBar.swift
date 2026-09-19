import SwiftUI

/// The bar below an output preview: the snippet text and the Copy button.
struct SnippetBar: View {
    let snippet: String
    let info: String
    let isCopied: Bool
    let copy: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: Design.barSpacing) {
                VStack(alignment: .leading) {
                    Text(snippet)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .lineLimit(3)
                        .truncationMode(.middle)
                        .accessibilityLabel("Snippet: \(snippet)")
                    Text(info)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: copy) {
                    Label(isCopied ? "Copied" : "Copy Snippet", systemImage: isCopied ? "checkmark" : "doc.on.clipboard")
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .animation(Design.feedback, value: isCopied)
                .help("Copy the snippet to the clipboard (⇧⌘C)")
                .accessibilityLabel(isCopied ? "Copied" : "Copy Snippet")
                .accessibilityInputLabels(["Copy Snippet", "Copy"])
            }
            .padding()
        }
        .background(.bar)
    }
}
