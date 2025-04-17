//
//  PostView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/17.
//
import SwiftUI
import TwoCentsInternal

struct EmptyPostView: PostView {
    let post: PostWithMedia

    init(post: PostWithMedia) {
        self.post = post
    }

    var body: some View {
        EmptyView()
    }
}

@MainActor @ViewBuilder
public func makePostView(post: PostWithMedia, isDetail: Bool = false) -> some View {
    switch post.post.media {
    case .IMAGE:
        ImageView(post: post, isDetail: isDetail)
    case .VIDEO:
        VideoView(post: post)
    case .LINK:
        LinkView(post: post, isDetail: isDetail)
    case .TEXT:
        TextView(post: post)
    default:
        EmptyPostView(post: post)
    }
}

public protocol PostView: View {
    var post: PostWithMedia { get }
}
