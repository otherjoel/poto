import Foundation
import Testing
import UniformTypeIdentifiers
@testable import Poto

@MainActor
struct OriginalsAndDropTests {
    private func makeFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "poto-originals-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    @Test func archiveCopiesTheSourceUnderTheOutputName() async throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appending(path: "IMG_1234.HEIC")
        let bytes = Data((0..<4096).map { UInt8($0 % 251) })
        try bytes.write(to: source)

        let originals = folder.appending(path: "originals/nested")
        let copy = try await OriginalArchiver.archive(source, outputName: "iceland-church-window", in: originals)
        #expect(copy.lastPathComponent == "iceland-church-window.HEIC")
        #expect(try Data(contentsOf: copy) == bytes)
        #expect(try Data(contentsOf: source) == bytes)
    }

    @Test func archiveReplacesAnOlderCopyAndLeavesNoPartialFile() async throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appending(path: "new.jpg")
        try Data([2, 2, 2]).write(to: source)
        let originals = folder.appending(path: "originals")
        try FileManager.default.createDirectory(at: originals, withIntermediateDirectories: true)
        try Data([1]).write(to: originals.appending(path: "photo.jpg"))

        try await OriginalArchiver.archive(source, outputName: "photo", in: originals)
        #expect(try Data(contentsOf: originals.appending(path: "photo.jpg")) == Data([2, 2, 2]))
        #expect(try FileManager.default.contentsOfDirectory(atPath: originals.path) == ["photo.jpg"])
    }

    @Test func archiveDoesNothingWhenTheSourceIsAlreadyTheOriginal() async throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let source = folder.appending(path: "photo.heic")
        try Data([7, 7]).write(to: source)

        try await OriginalArchiver.archive(source, outputName: "photo", in: folder)
        #expect(try Data(contentsOf: source) == Data([7, 7]))
    }

    @Test func archiveFailsForAMissingSource() async throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        await #expect(throws: (any Error).self) {
            try await OriginalArchiver.archive(folder.appending(path: "gone.heic"), outputName: "x", in: folder)
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: folder.path).isEmpty)
    }

    @Test func foldersSavedBeforeTheOriginalsSettingStillLoad() throws {
        let old = #"[{"id":"E00F0D6C-0000-4000-8000-000000000001","url":"file:///tmp/images/","customName":"","snippetTemplate":"{name}"}]"#
        let folders = try JSONDecoder().decode([OutputFolder].self, from: Data(old.utf8))
        #expect(folders.first?.originalsURL == nil)
        #expect(folders.first?.snippetTemplate == "{name}")
    }

    @Test func originalsFolderMustNotBeTheOutputFolder() {
        var folder = OutputFolder(url: URL(filePath: "/tmp/images/"))
        #expect(!folder.originalsFolderIsOutputFolder)
        folder.originalsURL = URL(filePath: "/tmp/images")
        #expect(folder.originalsFolderIsOutputFolder)
        folder.originalsURL = URL(filePath: "/tmp/images/originals")
        #expect(!folder.originalsFolderIsOutputFolder)
    }

    @Test func inboxKeepsACopyUntilItIsDiscarded() throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let promised = folder.appending(path: "IMG_0001.HEIC")
        try Data([9]).write(to: promised)

        let first = try Inbox.adopt(promised)
        let second = try Inbox.adopt(promised)
        #expect(first != second)
        #expect(first.lastPathComponent == "IMG_0001.HEIC")
        #expect(Inbox.contains(first))
        #expect(!Inbox.contains(promised))

        Inbox.discard(promised)
        #expect(FileManager.default.fileExists(atPath: promised.path))
        Inbox.discard(first)
        #expect(!FileManager.default.fileExists(atPath: first.path))
        #expect(FileManager.default.fileExists(atPath: second.path))
        Inbox.discard(second)
    }

    @Test func promisedFileMovesIntoTheInboxAndItsFolderGoesAway() throws {
        let promiseFolder = URL.cachesDirectory.appending(path: "\(Inbox.promiseFolderPrefix)\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: promiseFolder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: promiseFolder) }
        let promised = promiseFolder.appending(path: "IMG_0002.HEIC")
        try Data([5]).write(to: promised)
        #expect(Inbox.isInPromiseFolder(promised))

        let adopted = try Inbox.adoptPromisedFile(promised)
        defer { Inbox.discard(adopted) }
        #expect(Inbox.contains(adopted))
        #expect(try Data(contentsOf: adopted) == Data([5]))
        #expect(!FileManager.default.fileExists(atPath: promiseFolder.path))
    }

    @Test func onlyTheSwiftUIPromiseFolderCountsAsOne() {
        #expect(!Inbox.isInPromiseFolder(URL.cachesDirectory.appending(path: "SomeApp/photo.heic")))
        #expect(!Inbox.isInPromiseFolder(URL(filePath: "/Users/someone/\(Inbox.promiseFolderPrefix)X/photo.heic")))
        #expect(!Inbox.isInPromiseFolder(URL(filePath: "/Users/someone/Pictures/photo.heic")))
    }

    @Test func dropPrefersHEICThenTheOrderOfTheSource() {
        #expect(DropImporter.preferredImageType(among: ["public.jpeg", "public.heic"]) == .heic)
        #expect(DropImporter.preferredImageType(among: ["com.apple.photos.thing", "public.jpeg", "public.png"]) == .jpeg)
        #expect(DropImporter.preferredImageType(among: ["public.file-url", "public.utf8-plain-text"]) == nil)
    }

    @Test func dropSkipsTypesPotoCannotOpen() {
        #expect(DropImporter.preferredImageType(among: ["com.adobe.raw-image", "public.jpeg"]) == .jpeg)
        #expect(DropImporter.preferredImageType(among: ["public.svg-image"]) == nil)
    }

    @Test func inboxNamesAFileAfterItsSuggestedName() {
        let file = URL(filePath: "/tmp/3F2A9C.heic")
        #expect(Inbox.fileName(for: file, suggestedName: "IMG_1234") == "IMG_1234.heic")
        #expect(Inbox.fileName(for: file, suggestedName: "IMG_1234.HEIC") == "IMG_1234.heic")
        #expect(Inbox.fileName(for: file, suggestedName: "Trip v1.2") == "Trip v1.2.heic")
        #expect(Inbox.fileName(for: file, suggestedName: "a/b") == "a-b.heic")
        #expect(Inbox.fileName(for: file, suggestedName: nil) == "3F2A9C.heic")
        #expect(Inbox.fileName(for: file, suggestedName: " ") == "3F2A9C.heic")
    }
}
