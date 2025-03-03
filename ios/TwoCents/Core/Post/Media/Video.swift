//
//  Video.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//

import SwiftUI

class VideoUpload: Uploadable {
    
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
            mimeType: "video/mp4",
            url: PostManager.POST_URL.appending(path: "upload-video-post"))
    }
    
    
}

struct VideoDownload: Downloadable {
    let id: UUID
    let mediaUrl: String
}

struct VideoView: PostView {
    
    let post: Post
    let video: VideoDownload
    
    init(post: Post, video: VideoDownload) {
        self.post = post
        self.video = video
    }
    
    var body: some View {
        EmptyView()
    }
}
