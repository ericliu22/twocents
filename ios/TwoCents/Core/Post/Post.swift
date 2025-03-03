//
//  Post.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//
import Foundation

enum Media: String, Codable {
    case IMAGE
    case VIDEO
    case OTHER
}

class Post: Codable {
    
    let id: UUID
    var media: Media
    var dateCreated: Date
    
}

protocol Uploadable: Identifiable, Codable {
    
    func uploadPost() async throws -> Data
}

func makeUploadable(post: Post, data: Data, caption: String?) -> any Uploadable {
    switch post.media {
    case .IMAGE:
        return ImageUpload(post: post, data: data, caption: caption)
    default:
        return ImageUpload(post: post, data: data, caption: caption)
    }
}
