import SwiftUI

/// A whole-number field with a stepper, the standard macOS pair.
struct NumberField: View {
    let title: LocalizedStringKey
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        LabeledContent(title) {
            HStack {
                TextField(title, value: $value, format: .number)
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .frame(width: 56)
                Stepper(title, value: $value, in: range)
                    .labelsHidden()
            }
        }
        .onChange(of: value) {
            // The stepper stays in range by itself. Typed values do not.
            let clamped = min(max(value, range.lowerBound), range.upperBound)
            if clamped != value {
                value = clamped
            }
        }
    }
}
