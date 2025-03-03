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
    case OTHER
}

class Post: Codable {
    
    let id: UUID
    var media: Media
    var dateCreated: Date
    var caption: String
    
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
    default:
        return ImageUpload(post: post, data: data)
    }
}

@ViewBuilder
func makePostView(post: Post, postMedia: any Downloadable) -> some View {
    switch post.media {
    case .IMAGE:
        if let imageDownload = postMedia as? ImageDownload {
            ImageView(post: post, image: imageDownload)
        } else {
            EmptyPostView(post: post)
        }
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
