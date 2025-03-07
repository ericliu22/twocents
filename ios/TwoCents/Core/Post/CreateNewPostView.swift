import SwiftUI
import AVKit
import PhotosUI
import UniformTypeIdentifiers

struct CreatePostView: View {
    @State private var caption: String = ""
    @State private var mediaType: Media = .LINK
    @State private var mediaURL: String = ""
    @State private var selectedMedia: [URL] = []  // Now holds multiple media URLs
    @State private var showMediaPicker = false
    @State private var isPosting = false
    
    let mediaOptions: [(icon: String, label: String, type: Media)] = [
        ("link", "Link", .LINK),
        ("photo.fill", "Image/Video", .IMAGE),
        ("textformat", "Text", .TEXT),
        ("ellipsis", "Other", .OTHER)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(mediaOptions, id: \.label) { option in
                                mediaButton(icon: option.icon, label: option.label, isSelected: mediaType == option.type) {
                                    mediaType = option.type
                                    if mediaType == .IMAGE { showMediaPicker.toggle() }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    TextField("Write a caption...", text: $caption, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                        .font(.body)
                    
                    Divider()
                    
                    switch mediaType {
                    case .LINK:
                        HStack {
                            TextField("Enter URL", text: $mediaURL)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            
                            Button("Paste") {
                                if let clipboard = UIPasteboard.general.string {
                                    mediaURL = clipboard
                                }
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        
                    case .IMAGE:
                        if selectedMedia.isEmpty {
                            Text("No media selected")
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(selectedMedia, id: \.self) { media in
                                        mediaPreview(selectedMedia: media)
                                    }
                                }
                            }
                        }
                        
                    case .TEXT:
                        EmptyView()
                        
                    default:
                        EmptyView() // Handles other cases safely
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
                    .disabled(isPosting || (mediaType == .LINK && mediaURL.isEmpty))
                }
                .padding(.horizontal)
                .padding(.top)
                .navigationTitle("Create Post")
                .sheet(isPresented: $showMediaPicker) {
                    MediaPicker(mediaURLs: $selectedMedia)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private func createPost() {
        isPosting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPosting = false
        }
    }
    
    private func mediaButton(icon: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(isSelected ? Color.blue : Color(.systemGray5)))
                Text(label)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
    
    private func mediaPreview(selectedMedia: URL) -> some View {
        Group {
            if isVideo(url: selectedMedia) {
                VideoPlayer(player: AVPlayer(url: selectedMedia))
                    .cornerRadius(10)
                    .frame(height: 100, alignment: .topLeading)
            } else {
                if let image = UIImage(contentsOfFile: selectedMedia.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .frame(height: 100, alignment: .topLeading)
                } else {
                    Color.gray
                        .cornerRadius(10)
                        .frame(height: 100, alignment: .topLeading)
                }
            }
        }
    }
    
    private func isVideo(url: URL) -> Bool {
        let asset = AVAsset(url: url)
        return asset.tracks(withMediaType: .video).count > 0
    }
}

struct MediaPicker: UIViewControllerRepresentable {
    @Binding var mediaURLs: [URL]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images  // Only images are selected; adjust to .any for images and videos.
        config.selectionLimit = 0  // 0 = unlimited selection
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPicker
        
        init(_ parent: MediaPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    dispatchGroup.enter()
                    result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                        if let url = url {
                            // Copy to a temporary URL to persist the file representation
                            let tempURL = FileManager.default.temporaryDirectory
                                .appendingPathComponent(UUID().uuidString)
                                .appendingPathExtension("jpg")
                            do {
                                try FileManager.default.copyItem(at: url, to: tempURL)
                                DispatchQueue.main.async {
                                    self.parent.mediaURLs.append(tempURL)
                                }
                            } catch {
                                print("Error copying file: \(error.localizedDescription)")
                            }
                        }
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                picker.dismiss(animated: true)
            }
        }
    }
}

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}
