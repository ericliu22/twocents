//
//  ImageUpload.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/28.
//

import SwiftUI

class ImageUpload: Uploadable {
    
    let post: Post
    let caption: String?
    let data: Data

    init(post: Post, data: Data, caption: String?) {
        self.post = post
        self.data = data
        self.caption = caption
    }
    
    func uploadPost() async throws -> Data{
        return try await Request<String>.uploadMedia(
            post: post,
            fileData: data,
            mimeType: "image/jpeg",
            url: PostManager.POST_URL.appending(path: "upload-image-post"))
    }
    
    
}
