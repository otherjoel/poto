import SwiftUI

/// The bar below a source preview: the output name and the state of the photo.
/// Give it `.id(photo.id)` so the text field starts fresh for each photo.
struct SourceNameBar: View {
    @Environment(AppModel.self) private var model
    let photo: SourcePhoto

    @State private var name: String

    init(photo: SourcePhoto) {
        self.photo = photo
        _name = State(initialValue: photo.outputName)
    }

    private var fileNamesHint: String {
        let widths = model.settings.widths
        guard let first = widths.first, let last = widths.last, !photo.sanitizedOutputName.isEmpty else {
            return "Type a name for the output files."
        }
        let firstName = ConversionPipeline.outputFileName(name: photo.sanitizedOutputName, width: first)
        let lastName = ConversionPipeline.outputFileName(name: photo.sanitizedOutputName, width: last)
        return widths.count > 1 ? "Makes \(firstName) to \(lastName)" : "Makes \(firstName)"
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .firstTextBaseline, spacing: Design.barSpacing) {
                VStack(alignment: .leading) {
                    LabeledContent("Output Name") {
                        TextField("Output Name", text: $name)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .disabled(photo.status.isActive)
                    }
                    SourceStatusText(status: photo.status, hint: fileNamesHint)
                }
                if photo.status == .finished {
                    Button("Show in Output Folder", systemImage: "arrow.right.circle", action: reveal)
                }
            }
            .padding()
        }
        .background(.bar)
        .onChange(of: name) {
            model.queue.rename(photo.id, to: name)
        }
    }

    private func reveal() {
        model.reveal(photo)
    }
}
