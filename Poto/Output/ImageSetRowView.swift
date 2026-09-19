import SwiftUI

struct ImageSetRowView: View {
    let set: ImageSet
    let isCopied: Bool

    private var detail: String {
        let size = set.totalByteCount.formatted(.byteCount(style: .file))
        let count = set.variants.count
        return count > 1 ? "\(set.ext) · \(count) sizes · \(size)" : "\(set.ext) · \(size)"
    }

    var body: some View {
        HStack {
            if let smallest = set.smallest {
                ThumbnailView(url: smallest.url, version: smallest.modified)
            }
            VStack(alignment: .leading) {
                Text(set.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.secondary)
                .opacity(isCopied ? 1 : 0)
                .animation(Design.feedback, value: isCopied)
                .accessibilityLabel("Snippet copied")
                .accessibilityHidden(!isCopied)
        }
        .padding(.vertical, 2)
    }
}
