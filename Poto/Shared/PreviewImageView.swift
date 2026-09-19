import SwiftUI

/// The large preview. It scales the image to fit and shows HDR when asked.
struct PreviewImageView: View {
    let url: URL
    var version = Date.distantPast
    let hdr: Bool
    let accessibilityName: String
    /// Reports the pixel size of the file after each load.
    var onLoad: (DecodedImage) -> Void = { _ in }

    @State private var decoded: DecodedImage?
    @State private var didFail = false

    var body: some View {
        ZStack {
            if let decoded {
                Image(decorative: decoded.image, scale: 1)
                    .resizable()
                    .allowedDynamicRange(hdr ? .high : .standard)
                    .aspectRatio(decoded.aspectRatio, contentMode: .fit)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 2)
                    .accessibilityElement()
                    .accessibilityLabel("Preview of \(accessibilityName)")
                    .accessibilityAddTraits(.isImage)
            } else if didFail {
                ContentUnavailableView(
                    "Cannot Show Preview",
                    systemImage: "eye.slash",
                    description: Text("The file could not be read as an image.")
                )
            } else {
                ProgressView()
            }
        }
        .padding(Design.previewPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: PreviewRequest(url: url, version: version, hdr: hdr)) {
            let result = await ImageDecoder.decode(url, maxPixelSize: Design.previewPixelSize, hdr: hdr)
            guard !Task.isCancelled else { return }
            decoded = result
            didFail = result == nil
            if let result {
                onLoad(result)
            }
        }
    }
}
