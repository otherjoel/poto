import SwiftUI

struct QueueRowView: View {
    let photo: SourcePhoto

    var body: some View {
        HStack {
            ThumbnailView(url: photo.url)
            VStack(alignment: .leading) {
                Text(photo.outputName.isEmpty ? "Untitled" : photo.outputName)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text("\(photo.url.lastPathComponent) · \(photo.isHDR ? "HDR" : "SDR")")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            PhotoStatusView(status: photo.status)
        }
        .padding(.vertical, 2)
    }
}
