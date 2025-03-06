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
    @State var video: VideoDownload?
    
    init(post: Post) {
        self.post = post
    }
    
    var body: some View {
        ZStack {
            if let video {
                if let url = URL(string: video.mediaUrl) {
                    CachedVideo(videoUrl: url)
                }
            }
        }
        .task {
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            video = try? JSONDecoder().decode(VideoDownload.self, from: data)
        }
    }
}
