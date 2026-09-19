import SwiftUI

/// Overall progress of the current run, at the bottom of the photo list.
struct BatchProgressBar: View {
    let isVisible: Bool
    let fraction: Double

    var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                Divider()
                ProgressView(value: fraction) {
                    Text("Processing…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(.bar)
            .transition(.opacity)
        }
    }
}
