import SwiftUI
import Kingfisher
import CropViewController  // Ensure TOCropViewController is added to your project

struct ProfilePictureUploadView: View {
    @Environment(AppModel.self) var appModel
    @State private var showImagePicker = false
    @State private var showCropper = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage? = nil
    @State private var croppedImage: UIImage? = nil
    @State private var currentProfilePic: String? = nil
    @State private var showActionSheet = false

    var body: some View {
        NavigationView {
            VStack {
                // Display the current (cropped) profile image or a placeholder.
                if let image = croppedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                        .shadow(radius: 5)
                        .padding()
                    
                    // Button to remove photo.
                    Button(action: {
                        self.croppedImage = nil
                    }) {
                        Text("Remove Photo")
                            .foregroundColor(.red)
                    }
                    .padding(.bottom)
                } else {
                    
                    if let profileUrl = currentProfilePic {
                        if let url = URL(string: profileUrl) {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 150, height: 150)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(style: StrokeStyle(lineWidth: 2)))
                                .shadow(radius: 5)
                        }
                    } else {
                        Color(UIColor.systemGray6)
                            .frame(width: 200, height: 200)
                            .clipShape(Circle())
                            .padding()
                            .overlay(
                                Image(systemName: "person.crop.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 150, height: 150)
                                    .foregroundColor(  Color(UIColor.systemGray4))
                                    .padding()
                            )
                    }
//
                    
//
//                        .foregroundColor(.gray)
//                        .padding()
                }

                // Button to trigger image selection.
                Button {
                    //Add functionality here
                    if let croppedImage {
                        if let data = croppedImage.jpegData(compressionQuality: 1.0) {
                            Task {
                                try? await UserManager.updateProfilePic(imageData: data)
                                 let newUser = await UserManager.fetchCurrentUser()
                                if let newUser {
                                    appModel.currentUser = newUser
                                }
                            }
                        }
                    } else {
                        self.showActionSheet = true
                    }
                } label: {
                    if let croppedImage {
                        Text("Upload Profile Picture")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    } else {
                        Text("Select Profile Picture")
                            .fontWeight(.semibold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding(.horizontal)
                    }
                }
                Spacer()
            }
            .navigationTitle("Profile Picture")
            // Action sheet to choose camera or library.
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(title: Text("Select Image"), message: nil, buttons: [
                    .default(Text("Take Photo")) {
                        self.sourceType = .camera
                        self.showImagePicker = true
                    },
                    .default(Text("Choose from Library")) {
                        self.sourceType = .photoLibrary
                        self.showImagePicker = true
                    },
                    .cancel()
                ])
            }
            // Present the image picker.
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: self.$selectedImage, sourceType: sourceType)
            }
            // Use .onChange to trigger the crop view when a new image is selected.
            .onChange(of: selectedImage) { newValue in
                if newValue != nil {
                    // Delay presentation to ensure image picker is fully dismissed.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showCropper = true
                    }
                }
            }
            // Present the cropping view.
            .sheet(isPresented: $showCropper) {
                if let imageToCrop = selectedImage {
                    ImageCropper(image: imageToCrop) { cropped in
                        self.croppedImage = cropped
                        self.selectedImage = nil  // Clear temporary image after cropping.
                    }
                }
            }
        }
        .onAppear {
            if let user = appModel.currentUser, user.profilePic != nil {
                croppedImage
            }
        }
    }
}

// MARK: - ImagePicker: UIKit integration for selecting images.
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - ImageCropper: Wrapper for TOCropViewController with 1:1 aspect ratio.
struct ImageCropper: UIViewControllerRepresentable {
    var image: UIImage
    var onCropped: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    // Wrap the CropViewController in a UINavigationController.
    func makeUIViewController(context: Context) -> UINavigationController {
        let cropController = CropViewController(image: image)
        cropController.aspectRatioPreset = .presetSquare
        cropController.aspectRatioLockEnabled = true
        cropController.resetAspectRatioEnabled = false
        cropController.delegate = context.coordinator
        
        return UINavigationController(rootViewController: cropController)
    }
    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
    
    class Coordinator: NSObject, CropViewControllerDelegate {
        var parent: ImageCropper
        init(_ parent: ImageCropper) {
            self.parent = parent
        }
        func cropViewController(_ cropViewController: CropViewController,
                                didCropToImage image: UIImage,
                                withRect cropRect: CGRect,
                                angle: Int) {
            parent.onCropped(image)
            cropViewController.dismiss(animated: true, completion: nil)
        }
        func cropViewControllerDidCancel(_ cropViewController: CropViewController) {
            cropViewController.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Preview Provider
struct ProfilePictureUploadView_Previews: PreviewProvider {
    static var previews: some View {
        ProfilePictureUploadView()
    }
}
