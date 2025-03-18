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
    
    var body: some View {
        VStack(alignment: .leading) {
            if let metadata = metadata {
                // If an image is available, show it at the top
                if let previewImage = previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .clipped()
                }
                // Show the title if available
                if let title = metadata.title {
                    Text(title)
                        .font(.headline)
                        .padding(.top, 4)
                }
                // Show the URL text as a subheadline
                if let linkURL = metadata.url?.absoluteString {
                    Text(linkURL)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                }
            } else {
                // Placeholder while metadata is being fetched
                Text(url.absoluteString)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .onChange(of: metadata) {
            // Once metadata is updated, load the image from the imageProvider if available.
            guard let metadata = metadata,
                  let imageProvider = metadata.imageProvider else { return }
            
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
            // Fetch the LPLinkMetadata asynchronously
            let provider = LPMetadataProvider()
            do {
                let fetchedMetadata = try await provider.startFetchingMetadata(for: url)
                // Update the metadata on the main thread
                DispatchQueue.main.async {
                    metadata = fetchedMetadata
                }
            } catch {
                print("Error fetching metadata: \(error)")
            }
        }
    }
}
