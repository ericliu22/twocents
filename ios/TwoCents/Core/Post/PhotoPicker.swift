//
//  PhotoPicker.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/18.
//
import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var mediaItems: [SelectedMedia]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        // Allow both images and videos.
        config.filter = PHPickerFilter.any(of: [.images])
        config.selectionLimit = 0  // 0 for unlimited selection
        
        // Set preselectedAssetIdentifiers using those stored in mediaItems.
        config.preselectedAssetIdentifiers = mediaItems.compactMap { $0.assetIdentifier }
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Build a new list of media items based solely on the current picker results.
            var newMediaItems: [SelectedMedia] = []
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                // If the asset was already selected, retain it.
                if let assetId = result.assetIdentifier,
                   let existingItem = parent.mediaItems.first(where: { $0.assetIdentifier == assetId }) {
                    newMediaItems.append(existingItem)
                } else {
                    // Check for images.
                    if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        dispatchGroup.enter()
                        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                            if let url = url {
                                let tempURL = FileManager.default.temporaryDirectory
                                    .appendingPathComponent(UUID().uuidString)
                                    .appendingPathExtension("jpg")
                                do {
                                    try FileManager.default.copyItem(at: url, to: tempURL)
                                    let newItem = SelectedMedia(
                                        assetIdentifier: result.assetIdentifier,
                                        url: tempURL,
                                        fileMediaType: .image
                                    )
                                    DispatchQueue.main.async {
                                        newMediaItems.append(newItem)
                                    }
                                } catch {
                                    print("Error copying image file: \(error.localizedDescription)")
                                }
                            }
                            dispatchGroup.leave()
                        }
                    }
                    // Check for videos.
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                // Update the binding with the newly selected items.
                self.parent.mediaItems = newMediaItems
                picker.dismiss(animated: true)
            }
        }
    }
}
