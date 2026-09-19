import Foundation

/// All the sizes of one image: `name-500.avif`, `name-800.avif` and so on.
nonisolated struct ImageSet: Identifiable, Hashable, Sendable {
    let name: String
    /// The filename extension, in its original case.
    let ext: String
    /// Sorted by width, ascending.
    let variants: [ImageVariant]

    var id: String { Self.id(name: name, ext: ext) }

    static func id(name: String, ext: String) -> String {
        "\(name).\(ext.lowercased())"
    }

    var largest: ImageVariant? { variants.last }
    var smallest: ImageVariant? { variants.first }
    var totalByteCount: Int { variants.reduce(0) { $0 + $1.byteCount } }
    var modified: Date { variants.map(\.modified).max() ?? .distantPast }
    var widths: [Int] { variants.compactMap(\.width) }
}
