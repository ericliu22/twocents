//
//  Post.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//
import Foundation
import SwiftUI

enum Media: String, Codable {
    case IMAGE
    case VIDEO
    case LINK
    case OTHER
}

class Post: Codable {
    let id: UUID
    let userId: UUID
    var media: Media
    var dateCreated: Date
    var caption: String?

    // New initializer to create Post objects with specific values.
    init(
        id: UUID, userId: UUID, media: Media, dateCreated: Date,
        caption: String?
    ) {
        self.id = id
        self.userId = userId
        self.media = media
        self.dateCreated = dateCreated
        self.caption = caption
    }
}

protocol PostView: View {
    var post: Post { get }
}

protocol Uploadable: Identifiable, Codable {

    func uploadPost() async throws -> Data
}

protocol Downloadable: Codable {

}

func makeUploadable(post: Post, data: Data) -> any Uploadable {
    switch post.media {
    case .IMAGE:
        return ImageUpload(post: post, data: data)
    case .VIDEO:
        return VideoUpload(post: post, data: data)
    case .LINK:
        return LinkUpload(post: post, data: data)
    default:
        return ImageUpload(post: post, data: data)
    }
}

@ViewBuilder
func makePostView(post: Post) -> some View {
    switch post.media {
    case .IMAGE:
        ImageView(post: post)
    case .VIDEO:
        VideoView(post: post)
    case .LINK:
        LinkView(post: post)
    default:
        EmptyPostView(post: post)
    }
}

struct EmptyPostView: PostView {
    let post: Post

    init(post: Post) {
        self.post = post
    }

    var body: some View {
        EmptyView()
    }
}
