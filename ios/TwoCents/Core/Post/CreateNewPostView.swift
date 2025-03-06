import SwiftUI
import AVKit

struct CreatePostView: View {
    @State private var caption: String = ""
    @State private var mediaType: Media = .IMAGE
    @State private var mediaURL: String = ""
    @State private var selectedMedia: URL? = nil
    @State private var showMediaPicker = false
    @State private var isPosting = false
    
    let mediaOptions: [(icon: String, label: String, type: Media)] = [
        ("photo.fill", "Image/Video", .IMAGE),
        ("link", "Link", .LINK),
        ("ellipsis", "Other", .OTHER)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("Write a caption...", text: $caption)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .font(.body)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(mediaOptions, id: \ .label) { option in
                            mediaButton(icon: option.icon, label: option.label) {
                                mediaType = option.type
                                if mediaType == .IMAGE { showMediaPicker.toggle() }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                if mediaType == .LINK {
                    TextField("Enter URL", text: $mediaURL)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .padding(.horizontal)
                } else if mediaType == .IMAGE {
                    if let selectedMedia = selectedMedia {
                        mediaPreview(selectedMedia: selectedMedia)
                    }
                }
                
                Spacer()
                
                Button(action: createPost) {
                    HStack {
                        if isPosting {
                            ProgressView()
                        } else {
                            Text("Post")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(isPosting || (mediaType == .LINK && mediaURL.isEmpty))
            }
            .padding(.top)
            .navigationTitle("Create Post")
            .sheet(isPresented: $showMediaPicker) {
                MediaPicker(mediaURL: $selectedMedia)
            }
        }
    }
    
    private func createPost() {
        isPosting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPosting = false
        }
    }
    
    private func mediaButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.blue)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color(.systemGray5)))
                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func mediaPreview(selectedMedia: URL) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(height: 150)
                .overlay(
                    Group {
                        if isVideo(url: selectedMedia) {
                            VideoPlayer(player: AVPlayer(url: selectedMedia))
                                .frame(height: 150)
                        } else {
                            Image(uiImage: UIImage(contentsOfFile: selectedMedia.path) ?? UIImage())
                                .resizable()
                                .scaledToFit()
                                .frame(height: 150)
                        }
                    }
                )
        }
        .padding(.horizontal)
    }
    
    private func isVideo(url: URL) -> Bool {
        let asset = AVAsset(url: url)
        return asset.tracks(withMediaType: .video).count > 0
    }
}

struct MediaPicker: UIViewControllerRepresentable {
    @Binding var mediaURL: URL?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: MediaPicker
        init(_ parent: MediaPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let mediaURL = info[.mediaURL] as? URL {
                parent.mediaURL = mediaURL
            } else if let image = info[.originalImage] as? UIImage {
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
                if let data = image.jpegData(compressionQuality: 1.0) {
                    try? data.write(to: fileURL)
                    parent.mediaURL = fileURL
                }
            }
            picker.dismiss(animated: true)
        }
    }
}

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}
