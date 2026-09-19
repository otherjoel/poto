import SwiftUI

/// Shown over the window while files are dragged onto it.
struct DropHighlightView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .strokeBorder(.tint, style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
            .background(.tint.opacity(0.06), in: .rect(cornerRadius: 10))
            .padding(6)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
