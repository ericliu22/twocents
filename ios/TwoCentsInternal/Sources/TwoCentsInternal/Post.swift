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
