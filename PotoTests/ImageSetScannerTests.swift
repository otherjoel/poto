import Foundation
import Testing
@testable import Poto

@MainActor
struct ImageSetScannerTests {
    private let knownWidths: Set<Int> = [500, 800, 1000, 1200, 1600]

    private func entries(_ names: String...) -> [ImageFileEntry] {
        names.map { ImageFileEntry(url: URL(filePath: "/images/\($0)"), byteCount: 100) }
    }

    @Test func groupsSizesIntoOneSet() throws {
        let sets = ImageSetScanner.group(
            entries(
                "iceland-church-window-1000.avif", "iceland-church-window-500.avif",
                "iceland-church-window-1600.avif", "iceland-church-window-800.avif",
                "iceland-church-window-1200.avif"
            ),
            knownWidths: knownWidths
        )
        let set = try #require(sets.first)
        #expect(sets.count == 1)
        #expect(set.name == "iceland-church-window")
        #expect(set.ext == "avif")
        #expect(set.widths == [500, 800, 1000, 1200, 1600])
        #expect(set.largest?.url.lastPathComponent == "iceland-church-window-1600.avif")
        #expect(set.totalByteCount == 500)
    }

    @Test func fileWithoutWidthIsItsOwnSet() throws {
        let sets = ImageSetScanner.group(entries("2023-Oct-maple.webp"), knownWidths: knownWidths)
        let set = try #require(sets.first)
        #expect(set.name == "2023-Oct-maple")
        #expect(set.variants.count == 1)
        #expect(set.variants.first?.width == nil)
    }

    @Test func loneUnknownNumberIsPartOfTheName() throws {
        let sets = ImageSetScanner.group(entries("trip-2023.jpg"), knownWidths: knownWidths)
        #expect(try #require(sets.first).name == "trip-2023")
    }

    @Test func loneKnownWidthIsASet() throws {
        let sets = ImageSetScanner.group(entries("glacier-1600.avif"), knownWidths: knownWidths)
        let set = try #require(sets.first)
        #expect(set.name == "glacier")
        #expect(set.widths == [1600])
    }

    @Test func sameNameWithDifferentExtensionsStaysApart() {
        let sets = ImageSetScanner.group(
            entries("a-500.avif", "a-800.avif", "a-500.jpg", "a-800.jpg"),
            knownWidths: knownWidths
        )
        #expect(Set(sets.map(\.id)) == ["a.avif", "a.jpg"])
    }

    @Test func splitWidthSuffix() {
        #expect(ImageSetScanner.splitWidthSuffix("iceland-glacier-1600")?.name == "iceland-glacier")
        #expect(ImageSetScanner.splitWidthSuffix("iceland-glacier-1600")?.width == 1600)
        #expect(ImageSetScanner.splitWidthSuffix("iceland-glacier") == nil)
        #expect(ImageSetScanner.splitWidthSuffix("-500") == nil)
        #expect(ImageSetScanner.splitWidthSuffix("photo-") == nil)
        #expect(ImageSetScanner.splitWidthSuffix("photo-0") == nil)
    }

    @Test func scansARealFolderAndSkipsOtherFiles() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "poto-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder.appending(path: "originals"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for name in ["a-500.avif", "a-800.avif", "notes.txt", ".hidden-500.avif", "originals/b-500.avif"] {
            try Data([1, 2, 3]).write(to: folder.appending(path: name))
        }

        let sets = try await ImageSetScanner.scan(folder: folder, knownWidths: knownWidths)
        #expect(sets.map(\.id) == ["a.avif"])
        #expect(sets.first?.totalByteCount == 6)
    }

    @Test func missingFolderThrows() async {
        await #expect(throws: (any Error).self) {
            try await ImageSetScanner.scan(folder: URL(filePath: "/no/such/folder-\(UUID().uuidString)"), knownWidths: [])
        }
    }
}
