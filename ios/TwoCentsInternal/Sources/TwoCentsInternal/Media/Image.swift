//
//  Image.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/28.
//

import SwiftUI

public class ImageUpload: Uploadable {

    public let post: Post
    public let data: Data

    public init(post: Post, data: Data) {
        self.post = post
        self.data = data
    }

    public func uploadPost() async throws -> Data {
        return try await Request<String>.uploadMedia(
            post: post,
            fileData: data,
            mimeType: "image/jpeg",
            url: PostManager.POST_URL.appending(path: "upload-image-post"))
    }
}

struct ImageDownload: Downloadable {
    let id: UUID
    let postId: UUID
    let mediaUrl: String
}

struct ImageView: PostView {

    let post: Post
    @State var images: [ImageDownload] = []

    init(post: Post) {
        self.post = post
    }

    var body: some View {
        Group {
            if images.isEmpty {
                ProgressView()
            } else {
                TabView {
                    ForEach(images, id: \.id) { imageDownload in
                        if let url = URL(string: imageDownload.mediaUrl) {
                            CachedImage(url: url)
//                                .resizable()
                                .aspectRatio(3/4, contentMode: .fill)
                //                .frame(width: 150, height: 200)
                                .frame(maxWidth:.infinity)
                                .scrollClipDisabled(false)
//
//                                .aspectRatio(contentMode: .fit)
//                                .frame(maxWidth: .infinity)
                                .clipped()
                                .ignoresSafeArea()
                                .frame(maxHeight: .infinity)
                                .background(Color(UIColor.systemGray6))

                            
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            }
        }
        .task {
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            let newImages = try? JSONDecoder().decode(
                [ImageDownload].self, from: data)
            //Reloads each time user comes back not sure if good or bad
            if let newImages {
                images = []
                images.append(contentsOf: newImages)
            }
        }
    }
}
