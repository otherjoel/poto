import SwiftUI

/// The detail column for an image set: the preview, the size picker and the snippet.
/// Give it `.id(set.id)` so the size picker starts at the largest size for each set.
struct ImageSetDetailView: View {
    @Environment(AppModel.self) private var model
    let imageSet: ImageSet
    let snippet: String

    @State private var variantID: ImageVariant.ID?
    @State private var pixelSize: String?

    private var variant: ImageVariant? {
        imageSet.variants.first { $0.id == variantID } ?? imageSet.largest
    }

    var body: some View {
        @Bindable var model = model

        Group {
            if let variant {
                PreviewImageView(
                    url: variant.url,
                    version: variant.modified,
                    hdr: model.prefersHDRPreview,
                    accessibilityName: imageSet.name,
                    onLoad: showPixelSize
                )
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SnippetBar(
                snippet: snippet,
                info: info,
                isCopied: model.isCopied(imageSet),
                copy: model.copySnippet
            )
        }
        .toolbar {
            ToolbarItem {
                Picker("Size", selection: $variantID) {
                    ForEach(imageSet.variants) { variant in
                        Text(variant.label).tag(ImageVariant.ID?.some(variant.id))
                    }
                }
                .accessibilityLabel("Size")
                .help("The size to show")
                .disabled(imageSet.variants.count < 2)
            }
            ToolbarItem {
                Toggle("HDR", systemImage: "sun.max", isOn: $model.prefersHDRPreview)
                    .help("Show the preview in HDR. Turn off to see the SDR base image.")
            }
            ToolbarItem {
                Button("Quick Look", systemImage: "eye", action: quickLook)
                    .help("Quick Look (Space)")
            }
            ToolbarItem {
                Button("Show in Finder", systemImage: "finder", action: showInFinder)
                    .help("Show the files in Finder")
            }
        }
        .onAppear(perform: selectLargest)
    }

    private var info: String {
        let size = variant?.byteCount.formatted(.byteCount(style: .file)) ?? ""
        return [pixelSize, size].compactMap(\.self).joined(separator: " · ")
    }

    private func selectLargest() {
        if variantID == nil {
            variantID = imageSet.largest?.id
        }
    }

    private func showPixelSize(_ decoded: DecodedImage) {
        pixelSize = "\(decoded.pixelWidth) × \(decoded.pixelHeight)"
    }

    private func quickLook() {
        model.quickLookURL = variant?.url
    }

    private func showInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting(imageSet.variants.map(\.url))
    }
}
