import SwiftUI

struct MetadataSettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        Form {
            Section {
                TextField("Author", text: $model.settings.author)
                TextField("Rights", text: $model.settings.rights, axis: .vertical)
            } footer: {
                Text("Written to each file as XMP Creator and Rights. Camera, lens, exposure and date tags are copied from the source photo. All other metadata, location included, is removed.")
                    .settingsFooter()
            }
        }
        .formStyle(.grouped)
    }
}
