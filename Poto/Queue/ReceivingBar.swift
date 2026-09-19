import SwiftUI

/// Shown while dropped photos are on their way, for example from the Photos app.
struct ReceivingBar: View {
    let count: Int

    var body: some View {
        if count > 0 {
            VStack(spacing: 0) {
                Divider()
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Receiving ^[\(count) photo](inflect: true)…")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding()
            }
            .background(.bar)
        }
    }
}
