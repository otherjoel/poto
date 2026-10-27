import PhotosUI
import SwiftUI

/// The system Photos picker. It shows the whole library, iCloud photos included, and
/// needs no library permission: Poto gets only the photos the user adds.
///
/// It hands back item providers, so the photos take the same path as a drop.
struct PhotosPickerSheet: NSViewControllerRepresentable {
    /// Called once, with no providers when the user cancels.
    let onCompletion: ([NSItemProvider]) -> Void

    func makeNSViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0
        configuration.selection = .ordered
        // `.current` gives the file as the library holds it: the full-size HEIC with its
        // gain map. The default, `.automatic`, can give a converted, compatible file.
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateNSViewController(_ picker: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let onCompletion: ([NSItemProvider]) -> Void

        init(onCompletion: @escaping ([NSItemProvider]) -> Void) {
            self.onCompletion = onCompletion
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            onCompletion(results.map(\.itemProvider))
        }
    }
}
