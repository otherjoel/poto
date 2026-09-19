import Foundation
import Testing
@testable import Poto

@MainActor
struct ProcessingSettingsTests {
    @Test func defaultsMatchTheScript() {
        let settings = ProcessingSettings()
        #expect(settings.widths == [500, 800, 1000, 1200, 1600])
        #expect(settings.colorQuality == 80)
        #expect(settings.gainMapQuality == 80)
        #expect(settings.speed == 4)
        #expect(settings.bwBrightness == 3)
        #expect(settings.bwContrast == 5)
    }

    @Test(arguments: [
        ("500 800 1000", [500, 800, 1000]),
        ("1600, 500,800", [500, 800, 1600]),
        ("500 500 0 abc -20", [20, 500]),
        ("", []),
    ])
    func parsesWidths(text: String, expected: [Int]) {
        #expect(ProcessingSettings.parseWidths(text) == expected)
    }

    @Test func surviveACodableRoundTrip() throws {
        var settings = ProcessingSettings()
        settings.widths = [640]
        settings.author = "Someone"
        let decoded = try JSONDecoder().decode(ProcessingSettings.self, from: JSONEncoder().encode(settings))
        #expect(decoded == settings)
    }

    @Test func cicpLabelFollowsTheProfile() {
        #expect(ConversionPipeline.cicpBase(forProfile: "Display P3") == "12/13/1")
        #expect(ConversionPipeline.cicpBase(forProfile: "sRGB IEC61966-2.1") == "1/13/1")
        #expect(ConversionPipeline.cicpBase(forProfile: "") == "1/13/1")
        #expect(ConversionPipeline.cicpBase(forProfile: "Adobe RGB (1998)") == "1/13/1")
    }

    @Test func onlyDotHEICFilesUseTheScriptDecoder() {
        #expect(ConversionPipeline.usesScriptDecoder(URL(filePath: "/a/IMG_1.HEIC")))
        #expect(ConversionPipeline.usesScriptDecoder(URL(filePath: "/a/img.heic")))
        #expect(!ConversionPipeline.usesScriptDecoder(URL(filePath: "/a/img.heif")))
        #expect(!ConversionPipeline.usesScriptDecoder(URL(filePath: "/a/IMG_1396.jpeg")))
    }

    @Test func promisedFilesComeBackOnceAndInDragOrder() {
        let collector = PromisedFileCollector(expected: 3)
        #expect(collector.add(URL(filePath: "/inbox/c.heic"), order: 2) == nil)
        #expect(collector.add(nil, order: 1) == nil)
        #expect(collector.add(URL(filePath: "/inbox/a.heic"), order: 0)?.map(\.lastPathComponent) == ["a.heic", "c.heic"])
    }

    @Test func toolErrorSummaryKeepsTheLastWholeLines() {
        let traceback = """
        Traceback (most recent call last):
          File "/cache/bin/apple-hdr-heic-decoder", line 12, in <module>
            sys.exit(main())
                     ^^^^^^
          File "/cache/lib.py", line 95, in load_as_displayp3_linear
            assert hdr_metadata.profile_desc == "Display P3"
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        AssertionError

        """
        #expect(ProcessRunner.summary(of: traceback, maxLines: 2) == """
        assert hdr_metadata.profile_desc == "Display P3"
        AssertionError
        """)
        #expect(ProcessRunner.summary(of: "") == "")
    }
}
