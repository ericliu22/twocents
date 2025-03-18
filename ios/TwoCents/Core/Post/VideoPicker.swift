//
//  VideoPicker.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/18.
//
import SwiftUI
import AVKit
import PhotosUI
import UniformTypeIdentifiers

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var mediaItems: [SelectedMedia]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        // Only allow videos.
        config.filter = .videos
        config.selectionLimit = 0
        // Preselect assets if available.
        config.preselectedAssetIdentifiers = mediaItems.compactMap { $0.assetIdentifier }
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) { }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            var newMediaItems: [SelectedMedia] = []
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                // Retain already-selected media.
                if let assetId = result.assetIdentifier,
                   let existingItem = parent.mediaItems.first(where: { $0.assetIdentifier == assetId }) {
                    newMediaItems.append(existingItem)
                } else if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    dispatchGroup.enter()
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                        if let url = url {
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString)
                                .appendingPathExtension("mp4")
                            do {
                                try FileManager.default.copyItem(at: url, to: tempURL)
                                let newItem = SelectedMedia(
                                    assetIdentifier: result.assetIdentifier,
                                    url: tempURL,
                                    fileMediaType: .video
                                )
                                DispatchQueue.main.async {
                                    newMediaItems.append(newItem)
                                }
                            } catch {
                                print("Error copying video file: \(error.localizedDescription)")
                            }
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                self.parent.mediaItems = newMediaItems
                picker.dismiss(animated: true)
            }
        }
    }
}
