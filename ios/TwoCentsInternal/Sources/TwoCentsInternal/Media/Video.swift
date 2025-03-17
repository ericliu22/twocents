//
//  Video.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//

import SwiftUI

public class VideoUpload: Uploadable {
    
    public let post: Post
    public let data: Data

    public init(post: Post, data: Data) {
        self.post = post
        self.data = data
    }
    
    public func uploadPost() async throws -> Data{
        return try await Request<String>.uploadMedia(
            post: post,
            fileData: data,
            mimeType: "video/mp4",
            url: PostManager.POST_URL.appending(path: "upload-video-post"))
    }
    
    
}

public struct VideoDownload: Downloadable {
    public let id: UUID
    public let postId: UUID
    public let mediaUrl: String
}
