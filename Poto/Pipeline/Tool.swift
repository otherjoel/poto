import Foundation

/// The command-line tools the pipeline runs. The same set as the shell script.
nonisolated enum Tool: String, CaseIterable, Identifiable, Sendable {
    case uv
    case heifConvert = "heif-convert"
    case magick
    case avifgainmaputil
    case avifenc
    case exiftool

    var id: String { rawValue }

    var purpose: String {
        switch self {
        case .uv: "Runs apple-hdr-heic-decoder to decode the HDR image of iPhone HDR HEIC photos"
        case .heifConvert: "Decodes HEIC photos"
        case .magick: "Resizes images and fixes black & white photos"
        case .avifgainmaputil: "Encodes HDR photos as AVIF with a gain map"
        case .avifenc: "Encodes all other photos as AVIF"
        case .exiftool: "Reads the color profile and writes metadata"
        }
    }

    var installHint: String {
        switch self {
        case .uv: "brew install uv && uv tool install git+https://github.com/johncf/apple-hdr-heic.git"
        case .heifConvert: "brew install libheif"
        case .magick: "brew install imagemagick"
        case .avifgainmaputil, .avifenc: "brew install libavif"
        case .exiftool: "brew install exiftool"
        }
    }
}
