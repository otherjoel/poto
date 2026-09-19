import SwiftUI

@main
struct PotoApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Window("Poto", id: "main") {
            ContentView()
                .environment(appDelegate.model)
        }
        .defaultSize(width: 1100, height: 720)
        .commands {
            AppCommands(model: appDelegate.model)
        }

        Settings {
            SettingsView()
                .environment(appDelegate.model)
        }
    }
}
