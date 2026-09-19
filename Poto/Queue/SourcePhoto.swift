import Foundation

/// A photo that was opened for processing.
nonisolated struct SourcePhoto: Identifiable, Equatable, Sendable {
    let id = UUID()
    let url: URL
    /// An iPhone HDR photo. It becomes an AVIF with a gain map; all others become SDR AVIF.
    let isHDR: Bool
    /// The base name of the output files. Starts as the source file name, as in the script.
    var outputName: String
    var status = SourcePhotoStatus.ready
    /// Where the finished set went, so the app can show it.
    var destinationID: OutputFolder.ID?

    init(url: URL, isHDR: Bool = false) {
        self.url = url
        self.isHDR = isHDR
        outputName = url.deletingPathExtension().lastPathComponent
    }

    /// The output name without characters that cannot be part of a file name.
    var sanitizedOutputName: String {
        outputName
            .replacing("/", with: "-")
            .replacing(":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The ID of the image set this photo becomes.
    var imageSetID: ImageSet.ID {
        ImageSet.id(name: sanitizedOutputName, ext: "avif")
    }
}
