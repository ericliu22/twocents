//
//  PhotoVideoUpload.swift
//  TwoCents
//
//  Created by Joshua Shen on 2/28/25.
//
import SwiftUI
import UIKit
import AVKit
import UniformTypeIdentifiers // For UTType usage

struct CameraPickerView: View {
    @State private var isShowingCamera = true
    @State private var selectedImage: UIImage?
    @State private var selectedVideoURL: URL?

    var body: some View {
        VStack {
            if let image = selectedImage {
                // Display the chosen/captured image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else if let videoURL = selectedVideoURL {
                // Play the chosen/captured video
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(width: 300, height: 300)
            } else {
                Text("Capture or select media")
            }
        }
        // Automatically present the camera when the view appears
        .onAppear {
            isShowingCamera = true
        }
        // Present the UIImagePickerController
        .fullScreenCover(isPresented: $isShowingCamera) {
            CameraPicker(
                selectedImage: $selectedImage,
                selectedVideoURL: $selectedVideoURL
            )
        }.ignoresSafeArea()
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var selectedVideoURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Use the camera as the source
        picker.sourceType = .camera
        
        // Allow both images and movies
        // Using UTType for iOS 14+ to avoid deprecation
        if #available(iOS 14, *) {
            picker.mediaTypes = [
                UTType.image.identifier,
                UTType.movie.identifier
            ]
        } else {
            // Fallback for older iOS (if you still need it):
            // picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            print("older types not available")
        }

        // Default to high video quality, if user switches to video
        picker.videoQuality = .typeHigh
        // Default capture mode is photo; user can switch to video in UI
        picker.cameraCaptureMode = .photo
        
        // Let the user switch to photo library or between photo/video
        picker.showsCameraControls = true
        
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed in this example
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
        ) {
            // Check if the user picked an image
            if let mediaType = info[.mediaType] as? String {
                if #available(iOS 14, *), let utType = UTType(mediaType) {
                    handleSelectedMedia(using: utType, info: info)
                } else {
                    // If on older iOS, fall back to checking strings directly
                    print("deprecated media")
                }
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        // MARK: - Helpers
        
        @available(iOS 14, *)
        private func handleSelectedMedia(using utType: UTType, info: [UIImagePickerController.InfoKey : Any]) {
            if utType.conforms(to: .image) {
                // It's an image
                if let image = info[.originalImage] as? UIImage {
                    parent.selectedImage = image
                    parent.selectedVideoURL = nil
                }
            } else if utType.conforms(to: .movie) {
                // It's a video
                if let videoURL = info[.mediaURL] as? URL {
                    parent.selectedVideoURL = videoURL
                    parent.selectedImage = nil
                }
            }
        }
    }
}

struct CameraPickerView_Previews: PreviewProvider {
    static var previews: some View {
        CameraPickerView()
    }
}

