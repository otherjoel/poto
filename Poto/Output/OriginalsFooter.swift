import SwiftUI

struct OriginalsFooter: View {
    let isOutputFolder: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("After Poto processes a photo, it saves an unmodified copy in this folder. The copy gets the output name, for example iceland-church-window.heic. Location data stays in the copy.")
            if isOutputFolder {
                Label("Choose a folder that is not the output folder. Originals in the output folder show in its list of images.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.primary)
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
