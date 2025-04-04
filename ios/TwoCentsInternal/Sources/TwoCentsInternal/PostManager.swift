//
//  PostManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//

import Foundation

public struct PostRequest: Encodable {
    public let media: Media
    public let caption: String?
    public let groups: [UUID]
    
    public init(media: Media, caption: String? = nil, groups: [UUID]) {
        self.media = media
        self.caption = caption
        self.groups = groups
    }
}

//CanvasWidget: Post
//Media: Image

public struct PostManager: Sendable {
    
    private init() {}
    
    public static let POST_URL: URL = API_URL.appending(path: "post")
    
    public static func uploadPost(postRequest: PostRequest) async throws -> Post {
        let request: Request = Request(
            method: .POST,
            contentType: .json,
            url: POST_URL.appending(path: "create-post"),
            body: postRequest
        )
        let data = try await request.sendRequest()
        return try TwoCentsDecoder().decode(Post.self, from: data)
    }
    
    public static func uploadMediaPost(post: Post, data: Data) async throws -> Data {
        //The media
        let uploadPost: any Uploadable = makeUploadable(post: post, data: data)
        //The downloadable
        let data: Data = try await uploadPost.uploadPost()
        return data
    }
    
    public static func getGroupPosts(groupId: UUID, limit: Int = 10, offset: UUID? = nil) async throws -> Data {
        let baseURL = POST_URL.appendingPathComponent("get-group-posts")
        var queryItems = [
            URLQueryItem(name: "groupId", value: groupId.uuidString),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let offset = offset {
            print("OFFSET")
            print(offset.uuidString)
            queryItems.append(URLQueryItem(name: "offset", value: offset.uuidString))
        }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            print("failed to construct url")
            throw URLError(.badURL)
        }
        
        let request = Request<String>(
            method: .GET,
            contentType: .textPlain,
            url: finalURL
        )
        return try await request.sendRequest()
    }
    
    public static func getTopPost(groupId: UUID) async throws -> Data {
        let baseURL = POST_URL.appendingPathComponent("get-top-post")
        var queryItems = [
            URLQueryItem(name: "groupId", value: groupId.uuidString),
        ]
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            print("failed to construct url")
            throw URLError(.badURL)
        }
        
        let request = Request<String>(
            method: .GET,
            contentType: .textPlain,
            url: finalURL
        )
        return try await request.sendRequest()
    }


    public static func getMedia(post: Post) async throws -> Data {
        let baseURL = POST_URL.appendingPathComponent("get-media")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "postId", value: post.id.uuidString),
            URLQueryItem(name: "media", value: post.media.rawValue)
        ]
        guard let finalURL = components.url else {
            print("failed to construct url")
            throw URLError.init(URLError.Code(rawValue: 404))
        }
        let request: Request = Request<String> (
            method: .GET,
            contentType: .json,
            url: finalURL
        )
        return try await request.sendRequest()
    }
}
