import Foundation

/// The knobs of `heic-to-hdr-avif.sh`. Defaults match the script.
nonisolated struct ProcessingSettings: Codable, Equatable, Sendable {
    /// XMP dc:Creator (`AUTHOR`).
    var author = "Joel Dueck"
    /// XMP dc:Rights (`RIGHTS`).
    var rights = "© 2025 Joel Dueck. All rights reserved."
    /// Base image quality, 0–100 (`QCOLOR`).
    var colorQuality = 80
    /// Gain map quality, 0–100 (`QGAIN`).
    var gainMapQuality = 80
    /// Encoder speed, 0–10; higher is faster with larger files (`SPEED`).
    var speed = 4
    /// Applied to the SDR base of B&W photos only (`BW_BRIGHTNESS_ADJUST`).
    var bwBrightness = 3
    /// Applied to the SDR base of B&W photos only (`BW_CONTRAST_ADJUST`).
    var bwContrast = 5
    /// Output widths in pixels (`SIZES`).
    var widths = [500, 800, 1000, 1200, 1600]

    /// Parses a width list such as "500 800, 1000". Drops anything that is not a
    /// positive integer, removes duplicates and sorts ascending.
    static func parseWidths(_ text: String) -> [Int] {
        let values = text
            .split(whereSeparator: { !$0.isNumber })
            .compactMap { Int($0) }
            .filter { $0 > 0 }
        return Set(values).sorted()
    }

    var widthsText: String {
        widths.map(String.init).joined(separator: " ")
    }
}
