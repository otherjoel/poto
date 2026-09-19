import SwiftUI

extension Text {
    /// The explanatory text below a settings section.
    func settingsFooter() -> some View {
        font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
