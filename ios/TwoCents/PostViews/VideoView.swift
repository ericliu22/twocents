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
        if let downloadArray = post.download as? [Any] {
            self._videos = State(initialValue: downloadArray.compactMap { $0 as? VideoDownload })
        } else {
            self._videos = State(initialValue: [])
        }
        if videos.isEmpty {
            print("FUCKING EMPTY")
        }
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

