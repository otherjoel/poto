import SwiftUI

/// The encode settings of the script: SIZES, QCOLOR, QGAIN, SPEED and the B&W adjust.
struct EncodingSettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var widthsText = ""

    var body: some View {
        @Bindable var model = model

        Form {
            Section {
                TextField("Widths", text: $widthsText, prompt: Text("500 800 1000 1200 1600"))
                    .onSubmit(commitWidths)
            } header: {
                Text("Sizes")
            } footer: {
                Text("Output widths in pixels, separated by spaces. One file is made for each width.")
                    .settingsFooter()
            }

            Section {
                NumberField(title: "Base image quality", value: $model.settings.colorQuality, range: 0...100)
                NumberField(title: "Gain map quality", value: $model.settings.gainMapQuality, range: 0...100)
                NumberField(title: "Encoder speed", value: $model.settings.speed, range: 0...10)
            } header: {
                Text("AVIF")
            } footer: {
                Text("Quality is 0 to 100. Only HDR photos have a gain map. Speed is 0 to 10; a higher speed is faster and makes larger files.")
                    .settingsFooter()
            }

            Section {
                NumberField(title: "Brightness", value: $model.settings.bwBrightness, range: 0...20)
                NumberField(title: "Contrast", value: $model.settings.bwContrast, range: 0...20)
            } header: {
                Text("Black & White HDR Photos")
            } footer: {
                Text("Applied to the SDR base image of black & white HDR photos only, so that it is not too dark in Firefox and Safari. Set both to 0 for no adjustment.")
                    .settingsFooter()
            }

            Section {
                Button("Restore Defaults", action: restoreDefaults)
            }
        }
        .formStyle(.grouped)
        .onAppear(perform: showWidths)
        .onDisappear(perform: commitWidths)
    }

    private func showWidths() {
        widthsText = model.settings.widthsText
    }

    /// An empty or invalid list keeps the old widths.
    private func commitWidths() {
        let widths = ProcessingSettings.parseWidths(widthsText)
        if !widths.isEmpty {
            model.settings.widths = widths
        }
        showWidths()
    }

    private func restoreDefaults() {
        let defaults = ProcessingSettings()
        model.settings.widths = defaults.widths
        model.settings.colorQuality = defaults.colorQuality
        model.settings.gainMapQuality = defaults.gainMapQuality
        model.settings.speed = defaults.speed
        model.settings.bwBrightness = defaults.bwBrightness
        model.settings.bwContrast = defaults.bwContrast
        showWidths()
    }
}
