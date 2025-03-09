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
    let postId: UUID
    let mediaUrl: String
}

struct VideoView: PostView {

    let post: Post
    @State var videos: [VideoDownload] = []

    init(post: Post) {
        self.post = post
    }

    var body: some View {
        Group {
            if videos.isEmpty {
                ProgressView()
            } else {
                TabView {
                    ForEach(videos, id: \.id) { videoDownload in
                        if let url = URL(string: videoDownload.mediaUrl) {
                            CachedVideo(videoUrl: url)
                                .scaledToFill()
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
        }
        .task {
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            let newVideos = try? JSONDecoder().decode(
                [VideoDownload].self, from: data)
            if let newVideos {
                videos.append(contentsOf: newVideos)
            }
        }
    }
}

