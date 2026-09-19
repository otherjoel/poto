import Foundation
import Testing
@testable import Poto

@MainActor
struct AppModelTests {
    /// A private defaults domain, so tests do not touch the real settings.
    private func makeDefaults() -> UserDefaults {
        let name = "poto-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func foldersAndSettingsPersist() {
        let defaults = makeDefaults()
        let model = AppModel(defaults: defaults)
        model.addFolder(URL(filePath: "/tmp/images"))
        model.folders[0].snippetTemplate = "<img src=\"{file}\">"
        model.settings.speed = 7

        let reloaded = AppModel(defaults: defaults)
        #expect(reloaded.folders.map(\.url.path) == ["/tmp/images"])
        #expect(reloaded.folders.first?.snippetTemplate == "<img src=\"{file}\">")
        #expect(reloaded.settings.speed == 7)
        #expect(reloaded.destinationID == model.folders[0].id)
    }

    @Test func firstFolderBecomesTheDestination() {
        let model = AppModel(defaults: makeDefaults())
        #expect(model.destinationFolder == nil)
        #expect(!model.canProcess)
        model.addFolder(URL(filePath: "/tmp/one"))
        model.addFolder(URL(filePath: "/tmp/two"))
        #expect(model.destinationFolder?.url.path == "/tmp/one")
    }

    @Test func sameFolderIsNotAddedTwice() {
        let model = AppModel(defaults: makeDefaults())
        model.addFolder(URL(filePath: "/tmp/one"))
        model.addFolder(URL(filePath: "/tmp/one/"))
        #expect(model.folders.count == 1)
    }

    @Test func removingTheDestinationPicksTheNextFolder() {
        let model = AppModel(defaults: makeDefaults())
        model.addFolder(URL(filePath: "/tmp/one"))
        model.addFolder(URL(filePath: "/tmp/two"))
        model.removeFolder(model.folders[0].id)
        #expect(model.destinationFolder?.url.path == "/tmp/two")
        #expect(model.selection == .folder(model.folders[0].id))
    }

    @Test func outputNameIsSanitized() {
        var photo = SourcePhoto(url: URL(filePath: "/photos/IMG_1234.HEIC"))
        #expect(photo.outputName == "IMG_1234")
        photo.outputName = "  iceland/church:window "
        #expect(photo.sanitizedOutputName == "iceland-church-window")
        #expect(photo.imageSetID == "iceland-church-window.avif")
    }

    @Test func sourceScannerAcceptsBitmapImages() {
        for name in ["IMG_1.HEIC", "img.heif", "img.jpg", "img.png", "img.tiff", "img.webp", "img.avif"] {
            #expect(SourceScanner.isSource(URL(filePath: "/a/\(name)")), "\(name)")
        }
        for name in ["folder", "notes.txt", "logo.svg", "IMG_2.dng", "doc.pdf"] {
            #expect(!SourceScanner.isSource(URL(filePath: "/a/\(name)")), "\(name)")
        }
        #expect(SourceScanner.isHEIF(URL(filePath: "/a/IMG_1.HEIC")))
        #expect(!SourceScanner.isHEIF(URL(filePath: "/a/img.jpg")))
    }

    @Test func revealSelectsTheSetOfAFinishedPhoto() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "poto-reveal-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        for name in ["a-500.avif", "a-800.avif", "b-500.avif", "b-800.avif"] {
            try Data([1]).write(to: folder.appending(path: name))
        }

        let model = AppModel(defaults: makeDefaults())
        model.addFolder(folder)
        model.selection = .queue
        var photo = SourcePhoto(url: URL(filePath: "/photos/b.heic"))
        photo.destinationID = model.folders[0].id

        model.reveal(photo)
        await model.reloadSets()
        #expect(model.selection == .folder(model.folders[0].id))
        #expect(model.selectedSet?.name == "b")
    }
}
