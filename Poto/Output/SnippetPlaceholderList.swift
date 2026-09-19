import SwiftUI

/// Explains the template placeholders below the template field.
struct SnippetPlaceholderList: View {
    var body: some View {
        Grid(alignment: .leadingFirstTextBaseline, verticalSpacing: 2) {
            ForEach(SnippetTemplate.placeholders) { placeholder in
                GridRow {
                    Text(placeholder.token)
                        .font(.callout.monospaced())
                        .textSelection(.enabled)
                    Text(placeholder.meaning)
                        .font(.callout)
                }
            }
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
