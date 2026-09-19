import Foundation
import Testing
@testable import Poto

@MainActor
struct SnippetTemplateTests {
    private let set = SnippetTemplate.exampleSet

    @Test func defaultTemplateMakesThePhotoTag() {
        let snippet = SnippetTemplate.render(SnippetTemplate.defaultTemplate, for: set)
        #expect(snippet == "•photo[\"iceland-church-window\" #:ext \"avif\"]{}")
    }

    @Test func allPlaceholders() {
        let snippet = SnippetTemplate.render("{name}|{ext}|{file}|{width}|{widths}", for: set)
        #expect(snippet == "iceland-church-window|avif|iceland-church-window-1600.avif|1600|500 800 1000 1200 1600")
    }

    @Test func otherBracesPassThrough() {
        #expect(SnippetTemplate.render("{}{unknown}{ name }", for: set) == "{}{unknown}{ name }")
    }

    @Test func valuesAreNotExpandedAgain() {
        let odd = ImageSet(name: "{ext}", ext: "avif", variants: [])
        #expect(SnippetTemplate.render("{name}.{ext}", for: odd) == "{ext}.avif")
    }

    @Test func setWithoutWidths() {
        let plain = ImageSet(
            name: "maple",
            ext: "webp",
            variants: [ImageVariant(url: URL(filePath: "/maple.webp"), width: nil, byteCount: 0, modified: .distantPast)]
        )
        #expect(SnippetTemplate.render("{file} {width}|{widths}|", for: plain) == "maple.webp ||")
    }
}
