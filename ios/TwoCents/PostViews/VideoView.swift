//
//  VideoView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/17.
//
import SwiftUI
import TwoCentsInternal

struct VideoView: PostView {

    let post: PostWithMedia
    @State var videos: [VideoDownload] = []

    init(post: PostWithMedia) {
        self.post = post
        self.videos = post.download as? [VideoDownload] ?? []
    }

    var body: some View {
        Group {
            if videos.isEmpty {
                ProgressView()
            } else {
                TabView {
                    ForEach(videos, id: \.id) { videoDownload in
                        if let url = URL(string: videoDownload.mediaUrl) {
                            CachedVideo(url: url)
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
    }
}

