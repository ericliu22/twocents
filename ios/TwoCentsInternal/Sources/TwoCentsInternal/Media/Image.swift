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

public struct ImageDownload: Downloadable {
    public let id: UUID
    public let postId: UUID
    public let mediaUrl: String
}
