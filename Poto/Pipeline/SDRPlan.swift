import Foundation

/// What `prepareSDR` learned about a source, for the per-width encode.
nonisolated struct SDRPlan: Sendable {
    enum Color: Sendable {
        /// Drop the ICC profile and label the file with this CICP code, as the HDR path does.
        case cicp(String)
        /// Keep the ICC profile of the source.
        case embeddedProfile
    }

    let color: Color
    /// More than 8 bits per channel.
    let isDeep: Bool
    let hasAlpha: Bool

    var pngFormat: String {
        Self.pngFormat(isDeep: isDeep, hasAlpha: hasAlpha)
    }

    /// An explicit PNG format stops ImageMagick from writing a gray or palette file.
    static func pngFormat(isDeep: Bool, hasAlpha: Bool) -> String {
        switch (isDeep, hasAlpha) {
        case (false, false): "PNG24"
        case (false, true): "PNG32"
        case (true, false): "PNG48"
        case (true, true): "PNG64"
        }
    }
}
