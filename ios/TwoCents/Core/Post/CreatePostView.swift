import SwiftUI
import AVKit
import PhotosUI
import UniformTypeIdentifiers
import TwoCentsInternal

// New enum to differentiate between image and video files.
enum FileMediaType: Equatable {
    case image
    case video
}

// A model to store selected media information.
struct SelectedMedia: Identifiable, Equatable {
    // Use assetIdentifier if available; otherwise, fall back to the file URL string.
    var id: String { assetIdentifier ?? url.absoluteString }
    let assetIdentifier: String?
    let url: URL
    let fileMediaType: FileMediaType
}

struct CreatePostView: View {
    
    @State var viewModel = CreatePostViewModel()
    
    let mediaOptions: [(icon: String, label: String, type: Media)] = [
        ("link", "Link", .LINK),
        ("photo.fill", "Image", .IMAGE),
        ("video.fill", "Video", .VIDEO),
        ("textformat", "Text", .TEXT),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Media option buttons
                        HStack {
                            ForEach(mediaOptions, id: \.label) { option in
                                mediaButton(icon: option.icon, label: option.label, isSelected: viewModel.mediaType == option.type)
                                {
                                    viewModel.mediaType = option.type
//                                    if viewModel.mediaType == .IMAGE && viewModel.selectedMedia == [] { viewModel.showMediaPicker.toggle() }
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                         
                    
                    Divider()
                    
                    // Use the newer TextField initializer if available (iOS 16+).
                    
                    
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
                                viewModel.showPhotoPicker.toggle()
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                    Image(systemName: "plus")
                                        .font(.title)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // Display each selected image or video.
                                    ForEach(viewModel.selectedMedia) { media in
                                        mediaPreview(for: media)
                                            .onTapGesture {
                                                viewModel.fullScreenMedia = media
                                            }
                                    }
                                    // Grey box with plus icon to add more media.
                                    Button(action: {
                                        viewModel.showPhotoPicker.toggle()
                                    }) {
                                        ZStack {
                                            Rectangle()
                                                .fill(Color(.systemGray6))
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(10)
                                            Image(systemName: "plus")
                                                .font(.title)
                                        }
                                    }
                                }
                            }
                        }
                    case .VIDEO:
                        if viewModel.selectedMedia.isEmpty {
                            // Grey box with plus icon to add more images.
                            Button(action: {
                                viewModel.showVideoPicker.toggle()
                            }) {
                                ZStack {
                                    Rectangle()
                                        .fill(Color(.systemGray6))
                                        .frame(width: 100, height: 100)
                                        .cornerRadius(10)
                                    Image(systemName: "plus")
                                        .font(.title)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    // Display each selected image or video.
                                    ForEach(viewModel.selectedMedia) { media in
                                        mediaPreview(for: media)
                                            .onTapGesture {
                                                viewModel.fullScreenMedia = media
                                            }
                                    }
                                    // Grey box with plus icon to add more media.
                                    Button(action: {
                                        viewModel.showPhotoPicker.toggle()
                                    }) {
                                        ZStack {
                                            Rectangle()
                                                .fill(Color(.systemGray6))
                                                .frame(width: 100, height: 100)
                                                .cornerRadius(10)
                                            Image(systemName: "plus")
                                                .font(.title)
                                        }
                                    }
                                }
                            }
                        }
                        
                    case .TEXT:
                        EmptyView()
                        
                    default:
                        EmptyView() // Handles other cases safely.
                    }
                    
                    Divider()
                    TextField("Add a caption...", text: $viewModel.caption, axis: .vertical)
                        .lineLimit(5, reservesSpace: true)
                        .font(.body)

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
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isPosting
                              || (viewModel.mediaType == .LINK && viewModel.mediaURL.isEmpty)
                              || (viewModel.mediaType == .IMAGE && viewModel.selectedMedia.isEmpty)
                              || (viewModel.mediaType == .TEXT && viewModel.caption.isEmpty)
                              || (viewModel.mediaType == .VIDEO && viewModel.selectedMedia.isEmpty)
                    )
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)
                .padding(.top)
                .navigationTitle("Create Post")
                // Media picker sheet – passes in the already selected asset identifiers.
                .sheet(isPresented: $viewModel.showPhotoPicker) {
                    PhotoPicker(mediaItems: $viewModel.selectedMedia)
                }
                .sheet(isPresented: $viewModel.showVideoPicker) {
                    VideoPicker(mediaItems: $viewModel.selectedMedia)
                }
                // Full screen preview of tapped media.
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
            if media.fileMediaType == .video {
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
}

