//
//  Image.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/28.
//

import SwiftUI

class ImageUpload: Uploadable {
    
    let post: Post
    let data: Data

    init(post: Post, data: Data) {
        self.post = post
        self.data = data
    }
    
    func uploadPost() async throws -> Data{
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
    @State var image: ImageDownload?
    
    init(post: Post) {
        self.post = post
    }
    
    var body: some View {
        ZStack {
            if let image {
                if let url = URL(string: image.mediaUrl) {
                    CachedImage(imageUrl: url)
                }
            }
        }
        .task {
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            let images = try? JSONDecoder().decode([ImageDownload].self, from: data)
            image = images?.first
        }
    }
}
