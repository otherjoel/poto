import AppKit

/// Owns the model, so files that arrive from Finder or the Dock can reach it.
final class AppDelegate: NSObject, NSApplicationDelegate {
    let model = AppModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // The list of photos does not persist, so neither do their inbox copies.
        Inbox.removeAll()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        model.open(urls)
    }
}
