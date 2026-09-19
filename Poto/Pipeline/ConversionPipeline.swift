import Foundation

/// Makes one AVIF per width from a source photo.
///
/// iPhone HDR photos go through a port of `heic-to-hdr-avif.sh`: the same tools with
/// the same arguments, so the output for a `.heic` matches the script. Keep the two in
/// step. A gain-map photo in another format (JPEG) differs only in how `hdr.png` is made.
/// Every other image goes through `convertSDR`, which shares the resize and metadata
/// steps and encodes with `avifenc`.
nonisolated struct ConversionPipeline: Sendable {
    let settings: ProcessingSettings
    let tools: [Tool: URL]

    /// - Throws: `PipelineError.missingTools` if a tool was not found.
    init(settings: ProcessingSettings, tools: [Tool: URL] = ToolLocator.locateAll()) throws {
        let missing = Tool.allCases.filter { tools[$0] == nil }
        guard missing.isEmpty else { throw PipelineError.missingTools(missing) }
        self.settings = settings
        self.tools = tools
    }

    static func outputFileName(name: String, width: Int) -> String {
        "\(name)-\(width).avif"
    }

    /// Converts one photo into one AVIF per width, named `<outputName>-<width>.avif`,
    /// and moves them into `destination`. Existing files are replaced, as `mv` does.
    /// Widths above the source width upscale, as in the script, so that every set has
    /// every size. The source is not modified.
    @concurrent
    func convert(
        source: URL,
        outputName: String,
        destination: URL,
        progress: AsyncStream<ConversionProgress>.Continuation
    ) async throws -> [URL] {
        defer { progress.finish() }

        let manager = FileManager.default
        let work = manager.temporaryDirectory.appending(path: "poto-\(UUID().uuidString)")
        try manager.createDirectory(at: work, withIntermediateDirectories: true)
        defer { try? manager.removeItem(at: work) }

        let isHDR = SourceInspector.hasAppleHDRGainMap(source)
        let widths = settings.widths
        var tracker = ProgressTracker(totalUnits: widths.count + (isHDR ? 3 : 2), continuation: progress)

        let buildOne: @Sendable (Int) async throws -> Void
        if isHDR {
            let cicpBase = try await prepareHDR(source: source, in: work, tracker: &tracker)
            buildOne = { try await buildOneHDR(width: $0, outputName: outputName, cicpBase: cicpBase, in: work) }
        } else {
            let plan = try await prepareSDR(source: source, in: work, tracker: &tracker)
            buildOne = { try await buildOneSDR(width: $0, outputName: outputName, plan: plan, in: work) }
        }

        // Every width in parallel
        tracker.report(.encoding)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for width in widths {
                group.addTask {
                    try await buildOne(width)
                    try await writeMetadata(to: Self.outputFileName(name: outputName, width: width), from: source, in: work)
                }
            }
            for try await _ in group {
                tracker.complete(.encoding)
            }
        }

        tracker.report(.finishing)
        try manager.createDirectory(at: destination, withIntermediateDirectories: true)
        var outputs: [URL] = []
        for width in widths {
            let fileName = Self.outputFileName(name: outputName, width: width)
            let built = work.appending(path: fileName)
            guard manager.fileExists(atPath: built.path) else { throw PipelineError.missingOutput(fileName) }
            let target = destination.appending(path: fileName)
            if manager.fileExists(atPath: target.path) {
                try manager.removeItem(at: target)
            }
            try manager.moveItem(at: built, to: target)
            outputs.append(target)
        }
        tracker.complete(.finishing)
        return outputs
    }

    /// The script's decoder stops on any file name that does not end in ".heic".
    /// Those sources get the HDR image from `NativeHDRDecoder`.
    static func usesScriptDecoder(_ source: URL) -> Bool {
        source.pathExtension.lowercased() == "heic"
    }

    /// Display P3 is labelled CICP 12/13/1; sRGB, no profile, or anything unexpected 1/13/1.
    static func cicpBase(forProfile description: String) -> String {
        description == "Display P3" ? "12/13/1" : "1/13/1"
    }

    // MARK: - HDR (the script)

    /// Steps 1 to 3 of the script. Leaves `hdr.png` and `sdr.png` in `work`.
    /// - Returns: The CICP label for the SDR base.
    private func prepareHDR(source: URL, in work: URL, tracker: inout ProgressTracker) async throws -> String {
        // 1) Full HDR image as a 16-bit PQ/BT.2020 PNG
        tracker.report(.decodingHDR)
        if Self.usesScriptDecoder(source) {
            do {
                try await run(.uv, ["tool", "run", "--from", "apple-hdr-heic", "apple-hdr-heic-decoder", source.path, "hdr.png"], in: work)
            } catch PipelineError.toolFailed(_, _, let message) {
                throw PipelineError.hdrDecodeFailed(message)
            }
        } else {
            try NativeHDRDecoder.writePQImage(from: source, to: work.appending(path: "hdr.png"))
        }
        tracker.complete(.decodingHDR)

        // 2) SDR base image (no aux images)
        tracker.report(.extractingSDR)
        if SourceScanner.isHEIF(source) {
            try await run(.heifConvert, ["--no-colons", source.path, "sdr.png"], in: work)
        } else {
            // A JPEG with a gain map: the JPEG itself is the SDR base. Rotate the pixels,
            // as the HDR image has its orientation applied too.
            try await run(.magick, ["\(source.path)[0]", "-auto-orient", "sdr.png"], in: work)
        }
        tracker.complete(.extractingSDR)

        // The SDR base keeps its source primaries, so label it to match its ICC profile
        var cicpBase = Self.cicpBase(forProfile: try await profileDescription(of: "sdr.png", in: work))

        // 3) B&W photos: force RGB so the gain map encodes correctly
        let type = try await run(.magick, ["identify", "-format", "%[type]", "sdr.png"], in: work)
        if type.contains("Grayscale") {
            tracker.report(.fixingGrayscale)
            var arguments = ["sdr.png"]
            if settings.bwBrightness > 0 || settings.bwContrast > 0 {
                arguments += ["-brightness-contrast", "\(settings.bwBrightness)x\(settings.bwContrast)"]
            }
            arguments += ["+profile", "icc", "-type", "TrueColor", "-colorspace", "sRGB", "PNG24:sdr-rgb.png"]
            try await run(.magick, arguments, in: work)
            try replace("sdr.png", with: "sdr-rgb.png", in: work)
            // Profile stripped above; neutral values are the same in sRGB and P3
            cicpBase = "1/13/1"
        }
        return cicpBase
    }

    /// The resize and encode steps of the script's `build_one`.
    private func buildOneHDR(width: Int, outputName: String, cicpBase: String, in work: URL) async throws {
        let sdr = "sdr_\(width).png"
        let hdr = "hdr_\(width).png"

        // Forcing RGB (PNG48 keeps the 16-bit PQ data, PNG24 for the 8-bit SDR) and
        // preventing auto-grayscale optimizations on grayscale source images
        try await resize("hdr.png", to: width, output: "PNG48:\(hdr)", in: work)
        try await resize("sdr.png", to: width, output: "PNG24:\(sdr)", in: work)

        try await run(.avifgainmaputil, [
            "combine", sdr, hdr, Self.outputFileName(name: outputName, width: width),
            "--ignore-profile",
            "--cicp-base", cicpBase,
            "--cicp-alternate", "9/16/9",
            "--yuv", "420",
            "--depth", "10",
            "--depth-gain-map", "8",
            "--qcolor", "\(settings.colorQuality)",
            "--qgain-map", "\(settings.gainMapQuality)",
            "--speed", "\(settings.speed)",
        ], in: work)
    }

    // MARK: - SDR (every other image)

    /// Decodes the source to `sdr.png` with its orientation applied, and decides how
    /// to label its color.
    private func prepareSDR(source: URL, in work: URL, tracker: inout ProgressTracker) async throws -> SDRPlan {
        tracker.report(.preparing)
        if SourceScanner.isHEIF(source) {
            // The same decoder as the HDR path. It applies the HEIC rotation.
            try await run(.heifConvert, ["--no-colons", source.path, "sdr.png"], in: work)
        } else {
            // [0]: the first frame of an animation, the first page of a TIFF.
            // The metadata step strips the orientation tag, so rotate the pixels now.
            try await run(.magick, ["\(source.path)[0]", "-auto-orient", "sdr.png"], in: work)
        }

        // Type, bit depth and alpha, in one call
        let facts = try await run(.magick, ["identify", "-format", "%[type]|%z|%A", "sdr.png"], in: work)
            .split(separator: "|", omittingEmptySubsequences: false)
            .map(String.init)
        let type = facts.first ?? ""
        let isDeep = (facts.dropFirst().first.flatMap { Int($0) } ?? 8) > 8
        let hasAlpha = ["True", "Blend"].contains(facts.dropFirst(2).first ?? "")
        let profile = try await profileDescription(of: "sdr.png", in: work)

        var color = SDRPlan.Color.cicp("1/13/1")
        if type.contains("Gray") || type == "Bilevel" {
            // As for HDR: force RGB, so that no tool in the chain treats the gray
            // values as linear. No brightness adjust; that is for the gain map fallback.
            try await run(.magick, [
                "sdr.png", "+profile", "icc", "-type", hasAlpha ? "TrueColorAlpha" : "TrueColor",
                "-colorspace", "sRGB", "\(SDRPlan.pngFormat(isDeep: isDeep, hasAlpha: hasAlpha)):sdr-rgb.png",
            ], in: work)
            try replace("sdr.png", with: "sdr-rgb.png", in: work)
        } else if profile == "Display P3" {
            color = .cicp("12/13/1")
        } else if !profile.isEmpty, !profile.hasPrefix("sRGB") {
            // Adobe RGB, ProPhoto and so on have no CICP code. Keep the ICC profile.
            color = .embeddedProfile
        }

        tracker.complete(.preparing)
        return SDRPlan(color: color, isDeep: isDeep, hasAlpha: hasAlpha)
    }

    private func buildOneSDR(width: Int, outputName: String, plan: SDRPlan, in work: URL) async throws {
        let resized = "sdr_\(width).png"
        try await resize("sdr.png", to: width, output: "\(plan.pngFormat):\(resized)", in: work)

        var arguments = [
            "--yuv", "420",
            "--depth", "10",
            "--qcolor", "\(settings.colorQuality)",
            "--speed", "\(settings.speed)",
            "--jobs", "1", // the widths already run in parallel
            "--ignore-exif", "--ignore-xmp",
        ]
        if plan.hasAlpha {
            arguments += ["--qalpha", "\(settings.colorQuality)"]
        }
        if case .cicp(let code) = plan.color {
            arguments += ["--ignore-icc", "--cicp", code]
        }
        try await run(.avifenc, arguments + [resized, Self.outputFileName(name: outputName, width: width)], in: work)
    }

    // MARK: - Shared steps

    /// The resize of the script's `build_one`: Lanczos, and no auto-grayscale.
    private func resize(_ input: String, to width: Int, output: String, in work: URL) async throws {
        try await run(.magick, [
            input, "-filter", "Lanczos", "-define", "filter:blur=0.95", "-resize", "\(width)x",
            "-define", "colorspace:auto-grayscale=off",
            "-define", "png:compression-level=1", output,
        ], in: work)
    }

    /// Strip all EXIF/XMP (container HDR/CICP remains), then re-inject curated
    /// EXIF from the source plus XMP author/rights.
    private func writeMetadata(to file: String, from source: URL, in work: URL) async throws {
        try await run(.exiftool, [
            "-overwrite_original", "-all=",
            "-TagsFromFile", source.path,
            "-EXIF:Make", "-EXIF:Model", "-EXIF:FNumber", "-EXIF:ExposureTime", "-EXIF:ISO",
            "-EXIF:FocalLength", "-EXIF:FocalLengthIn35mmFormat", "-EXIF:LensModel",
            "-EXIF:ExposureProgram", "-EXIF:MeteringMode",
            "-EXIF:DateTimeOriginal", "-EXIF:CreateDate", "-EXIF:OffsetTimeOriginal", "-EXIF:OffsetTimeDigitized",
            "-XMP-dc:Creator=\(settings.author)",
            "-XMP-dc:Rights=\(settings.rights)",
            file,
        ], in: work)
    }

    private func profileDescription(of file: String, in work: URL) async throws -> String {
        try await run(.exiftool, ["-s3", "-ICC_Profile:ProfileDescription", file], in: work)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func replace(_ file: String, with newFile: String, in work: URL) throws {
        try FileManager.default.removeItem(at: work.appending(path: file))
        try FileManager.default.moveItem(at: work.appending(path: newFile), to: work.appending(path: file))
    }

    @discardableResult
    private func run(_ tool: Tool, _ arguments: [String], in directory: URL) async throws -> String {
        guard let executable = tools[tool] else { throw PipelineError.missingTools([tool]) }
        return try await ProcessRunner.run(executable, arguments, in: directory)
    }
}
