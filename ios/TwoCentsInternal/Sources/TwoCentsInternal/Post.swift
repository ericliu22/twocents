//
//  Post.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//
import Foundation
import SwiftUI

public enum Media: String, Codable {
    case IMAGE
    case VIDEO
    case TEXT
    case LINK
    case OTHER
}

public class Post: Identifiable, Codable {
    public let id: UUID
    public let userId: UUID
    public var media: Media
    public var dateCreated: Date
    public var caption: String?

    // New initializer to create Post objects with specific values.
    public init(
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



public protocol Uploadable: Identifiable, Codable {

    func uploadPost() async throws -> Data
}

public protocol Downloadable: Identifiable, Codable {

}

public func makeUploadable(post: Post, data: Data) -> any Uploadable {
    switch post.media {
    case .IMAGE:
        return ImageUpload(post: post, data: data)
    case .VIDEO:
        return VideoUpload(post: post, data: data)
    case .LINK:
        return LinkUpload(post: post, data: data)
    case .TEXT:
        return TextUpload(post: post, data: data)
    case .OTHER:
        return ImageUpload(post: post, data: data)
    }
}

public struct PaginatedPostsResponse: Decodable {
    public let posts: [PostWithMedia]
    public let offset: UUID?
    public let hasMore: Bool
}

public struct PostWithMedia: Identifiable, Decodable {
    public let post: Post
    public let download: [any Downloadable]
    public let id: UUID
    
    public enum CodingKeys: String, CodingKey {
        case post
        case media
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        post = try container.decode(Post.self, forKey: .post)
        
        // Dynamically decode the media based on post.media type
        switch post.media {
        case .IMAGE:
            download = try container.decode([ImageDownload].self, forKey: .media)
        case .VIDEO:
            download = try container.decode([VideoDownload].self, forKey: .media)
        case .LINK:
            download = try container.decode([LinkDownload].self, forKey: .media)
        case .TEXT:
            download = try container.decode([TextDownload].self, forKey: .media)
        case .OTHER:
            download = []
        }
        self.id = post.id
    }
}
// Helper for dynamic key decoding
public struct DynamicCodingKeys: CodingKey {
    public var stringValue: String
    public var intValue: Int?
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
        return nil
    }
    
    public init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
        return nil
    }
}
