import SwiftUI
import AVKit
import PhotosUI
import UniformTypeIdentifiers
import TwoCentsInternal

// A model to store selected media information.
struct SelectedMedia: Identifiable, Equatable {
    // Use assetIdentifier if available; otherwise, fall back to the file URL string.
    var id: String { assetIdentifier ?? url.absoluteString }
    let assetIdentifier: String?
    let url: URL
}

struct CreatePostView: View {
    
    @State var viewModel = CreatePostViewModel()
    
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
                    // Media option buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(mediaOptions, id: \.label) { option in
                                mediaButton(icon: option.icon, label: option.label, isSelected: viewModel.mediaType == option.type) {
                                    viewModel.mediaType = option.type
                                    if viewModel.mediaType == .IMAGE && viewModel.selectedMedia == [] { viewModel.showMediaPicker.toggle() }
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Use the newer TextField initializer if available (iOS 16+).
                    TextField("Write a viewModel.caption...", text: $viewModel.caption, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                        .font(.body)
                    
                    Divider()
                    
                    // Switch based on selected media type.
                    switch viewModel.mediaType {
                    case .LINK:
                        HStack {
                            TextField("Enter URL", text: $viewModel.mediaURL)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .keyboardType(.URL)
                                .autocapitalization(.none)
                            
                            
                            Button(action: {
                                if let clipboard = UIPasteboard.general.string {
                                    viewModel.mediaURL = clipboard
                                }
                            }) {
                               Text("Paste")
                                    .padding(.vertical, 10)
                            }
                            .buttonStyle(.bordered)

                            .cornerRadius(10)
                        }
                        
                    case .IMAGE:
                        if viewModel.selectedMedia.isEmpty {
                            // Grey box with plus icon to add more images.
                            Button(action: {
                                viewModel.showMediaPicker.toggle()
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                    Image(systemName: "plus")
                                        .font(.title)
//                                        .foregroundColor(.blue)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // Display each selected image.
                                    ForEach(viewModel.selectedMedia) { media in
                                        mediaPreview(for: media)
                                            .onTapGesture {
                                                viewModel.fullScreenMedia = media
                                            }
                                    }
                                    // Grey box with plus icon to add more images.
                                    Button(action: {
                                        viewModel.showMediaPicker.toggle()
                                    }) {
                                        ZStack {
                                            Rectangle()
                                                .fill(Color(.systemGray6))
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(10)
                                            Image(systemName: "plus")
                                                .font(.title)
//                                                .foregroundColor(.blue)
                                        }
                                    }
//                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        
                    case .TEXT:
                        EmptyView()
                        
                    default:
                        EmptyView() // Handles other cases safely.
                    }
                    
                    Spacer()
                    
                    // Post button.
                    Button(action: {
                        Task {
                            await viewModel.createPost()
                        }
                    }) {
                        HStack {
                            if viewModel.isPosting {
                                ProgressView()
                            } else {
                                Text("Post")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isPosting || (viewModel.mediaType == .LINK && viewModel.mediaURL.isEmpty))
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.top)
                .navigationTitle("Create Post")
                // Media picker sheet – passes in the already selected asset identifiers.
                .sheet(isPresented: $viewModel.showMediaPicker) {
                    MediaPicker(mediaItems: $viewModel.selectedMedia)
                }
                // Full screen preview of tapped image.
                .fullScreenCover(item: $viewModel.fullScreenMedia) { media in
                    FullScreenImageView(selectedMedia: media, onDelete: {
                        if let index = viewModel.selectedMedia.firstIndex(of: media) {
                            viewModel.selectedMedia.remove(at: index)
                        }
                        viewModel.fullScreenMedia = nil
                    }, onDismiss: {
                        viewModel.fullScreenMedia = nil
                    })
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    
    // Media option button view.
    private func mediaButton(icon: String, label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
       
        VStack(spacing: 8) {
            if isSelected {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.title)
                        .frame(width: 48, height: 48)
                }
                .buttonBorderShape(.circle)
         
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.title)
                        .frame(width: 48, height: 48)
                }
                .buttonBorderShape(.circle)
                
                .buttonStyle(.bordered)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
       
   
    }
    
    // Preview view for each image or video.
    private func mediaPreview(for media: SelectedMedia) -> some View {
        Group {
            if isVideo(url: media.url) {
                VideoPlayer(player: AVPlayer(url: media.url))
                    .cornerRadius(10)
                    .frame(width: 100, height: 100, alignment: .topLeading)
            } else {
                if let image = UIImage(contentsOfFile: media.url.path) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    Color.gray
                        .cornerRadius(10)
                        .frame(width: 100, height: 100)
                }
            }
        }
    }
    
    private func isVideo(url: URL) -> Bool {
        let asset = AVAsset(url: url)
        return asset.tracks(withMediaType: .video).count > 0
    }
}

// Updated MediaPicker that now rebuilds the selection based on the current picker results,
// so if an image is deselected, it is removed from the selection.
struct MediaPicker: UIViewControllerRepresentable {
    @Binding var mediaItems: [SelectedMedia]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images  // Only images are allowed.
        config.selectionLimit = 0  // 0 for unlimited selection
        
        // Set preselectedAssetIdentifiers using those stored in mediaItems.
        config.preselectedAssetIdentifiers = mediaItems.compactMap { $0.assetIdentifier }
        
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
            // Build a new list of media items based solely on the current picker results.
            var newMediaItems: [SelectedMedia] = []
            let dispatchGroup = DispatchGroup()
            
            for result in results {
                // If the image was already selected, retain it.
                if let assetId = result.assetIdentifier,
                   let existingItem = parent.mediaItems.first(where: { $0.assetIdentifier == assetId }) {
                    newMediaItems.append(existingItem)
                } else {
                    // Otherwise, load the new image.
                    if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                        dispatchGroup.enter()
                        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { url, error in
                            if let url = url {
                                let tempURL = FileManager.default.temporaryDirectory
                                    .appendingPathComponent(UUID().uuidString)
                                    .appendingPathExtension("jpg")
                                do {
                                    try FileManager.default.copyItem(at: url, to: tempURL)
                                    let newItem = SelectedMedia(assetIdentifier: result.assetIdentifier, url: tempURL)
                                    DispatchQueue.main.async {
                                        newMediaItems.append(newItem)
                                    }
                                } catch {
                                    print("Error copying file: \(error.localizedDescription)")
                                }
                            }
                            dispatchGroup.leave()
                        }
                    }
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

struct CreatePostView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePostView()
    }
}
