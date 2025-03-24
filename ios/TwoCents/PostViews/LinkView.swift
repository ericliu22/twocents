//
//  LinkView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/17.
//
import TwoCentsInternal
import SwiftUI
import LinkPresentation

struct LinkView: PostView {
    
    let post: Post
    @State var link: LinkDownload?
    
    init(post: Post) {
        self.post = post
    }
    
    var body: some View {
        Group {
            if let link {
                if let url = URL(string: link.mediaUrl) {
                    LinkPreview(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            // Fetch media data asynchronously
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            let links = try? JSONDecoder().decode([LinkDownload].self, from: data)
            // Ensure state updates are performed on the main thread.
            await MainActor.run {
                link = links?.first
            }
        }
    }
}
struct LinkPreview: View {
    let url: URL
    @State private var metadata: LPLinkMetadata?
    @State private var previewImage: UIImage?
    
    // Fixed height for the image container.
//    private let imageContainerHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            // Image container with a fixed height.
            Group {
                if let previewImage = previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit() // Ensures the entire image is visible without stretching.
                        .frame(maxWidth:.infinity, maxHeight: .infinity )
                      
                } else {
                    // A placeholder when no image is available.
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth:.infinity, maxHeight: .infinity )
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                        )
                }
            }
            
            // Text container below the image.
            VStack(alignment: .leading, spacing: 4) {
                if let title = metadata?.title {
                    Text(title)
                        .font(.subheadline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                } else {
                    Text(url.absoluteString)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
//        .shadow(radius: 2)
        .onChange(of: metadata) { newMetadata in
            // Once metadata is updated, attempt to load the preview image.
            guard let newMetadata = newMetadata,
                  let imageProvider = newMetadata.imageProvider else { return }
            
            imageProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let error = error {
                    print("Error loading image: \(error)")
                } else if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        previewImage = image
                    }
                }
            }
        }
        .task {
            // Asynchronously fetch the LPLinkMetadata.
            let provider = LPMetadataProvider()
            do {
                let fetchedMetadata = try await provider.startFetchingMetadata(for: url)
                DispatchQueue.main.async {
                    metadata = fetchedMetadata
                }
            } catch {
                print("Error fetching metadata: \(error)")
            }
        }
    }
}
