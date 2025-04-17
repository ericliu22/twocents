//
//  ImageView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/17.
//
import SwiftUI
import TwoCentsInternal
import Kingfisher

struct ImageView: PostView {
    let post: PostWithMedia
    let isDetail: Bool

    // Remove the state variable and compute images directly from post.download
    var images: [ImageDownload] {
        post.download as? [ImageDownload] ?? []
    }

    init(post: PostWithMedia, isDetail: Bool = false) {
        self.post = post
        self.isDetail = isDetail
    }

    var body: some View {
        Group {
            if images.isEmpty {
                Image(systemName: "photo")
                    .foregroundColor(.white)
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView {
                    ForEach(images, id: \.id) { imageDownload in
                        if let url = URL(string: imageDownload.mediaUrl) {
                            if isDetail {
                                KFImage(url)
                                    .resizable()
                                    .clipped()
                                    .scaledToFit() // ensures full image is visible, stretching width naturally.
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color(UIColor.systemGray6))
                            } else {
                                KFImage(url)
                                    .resizable()
                                    .clipped()
                                    .scaledToFill() // fills the frame even if it means cropping.
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .aspectRatio(3/4, contentMode: .fill)
                                    .clipped()
                                    .background(Color(UIColor.systemGray6))
                            }
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            }
        }
    }
}
