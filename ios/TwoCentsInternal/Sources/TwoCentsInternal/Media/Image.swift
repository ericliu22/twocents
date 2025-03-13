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
    let isDetail: Bool
    @State var images: [ImageDownload] = []

    init(post: Post, isDetail: Bool = false) {
        self.post = post
        self.isDetail = isDetail
    }

    var body: some View {
        Group {
            if images.isEmpty {
                ProgressView()
            } else {
                TabView {
                    ForEach(images, id: \.id) { imageDownload in
                        if let url = URL(string: imageDownload.mediaUrl) {
                            if isDetail {
                                CachedImage(url: url)
                                    .scaledToFit() // ensures full image is visible, stretching width naturally.
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(UIColor.systemGray6))
                            } else {
                                CachedImage(url: url)
                                    .scaledToFill() // fills the frame even if it means cropping.
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(3/4, contentMode: .fill)
                                    .clipped()
                                    .background(Color(UIColor.systemGray6))
                            }
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
            if let newImages = try? JSONDecoder().decode([ImageDownload].self, from: data) {
                images = newImages
            }
        }
    }

}
