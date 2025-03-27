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
    
    
    let isDetail: Bool
 


    
    
    init(post: Post, isDetail: Bool = false) {
        self.post = post
        self.isDetail = isDetail
    }
    
    var body: some View {
        Group {
            if let link {
                if let url = URL(string: link.mediaUrl) {
                    LinkPreview(url: url, isDetail: isDetail)
                        .frame(maxWidth: .infinity/*, maxHeight: .infinity*/)
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
    let isDetail: Bool
    
    // Fixed height for the image container.
//    private let imageContainerHeight: CGFloat = 200

    var body: some View {
        VStack(spacing: 0) {
            // Image container with a fixed height.
            Group {
                if let previewImage = previewImage {
                    VStack(spacing: 0) {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit() // Maintain aspect ratio
                            .frame(maxWidth: .infinity, maxHeight: isDetail ? nil : .infinity) // Allow full width, flexible height
                            
                            .background(
                                ZStack {
                                    Color.black
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .blur(radius: 5)
                                        .opacity(0.3)
                                }
                            )
                    }
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: isDetail ? (UIScreen.main.bounds.width / 16) * 9 : .infinity)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                        )
                }
            }

            
            // Text container below the image.
            VStack(alignment: .leading, spacing: 0) {
                
                HStack {
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
                    
                    if isDetail {
                        Button(action: {
                            
                            UIApplication.shared.open(url)
                            
                        }) {
                            Image(systemName: "arrow.up.right.square")
                        }
                        .padding(.leading, 5)
                        
                        
                        
                    }
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            
//            Spacer()
//                .frame(height: isDetail ? .infinity : 0)
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
