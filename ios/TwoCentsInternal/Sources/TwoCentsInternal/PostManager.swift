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

public struct PostManager {
    
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
    
    public static func getGroupPosts(groupId: UUID) async throws -> Data {
        // Base URL: https://api.twocentsapp.com/v1/post/get-group-posts
        let baseURL = POST_URL.appendingPathComponent("get-group-posts")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "groupId", value: groupId.uuidString)
        ]
        
        guard let finalURL = components.url else {
            print("failed to construct url")
            throw URLError.init(URLError.Code(rawValue: 404))
        }

        print(finalURL.absoluteString)
        // Should print: https://api.twocentsapp.com/v1/post/get-group-posts?groupId=B343342A-D41B-4C79-A8A8-7E0B142BE6DA

        let request: Request = Request<String>(
            method: .GET,
            contentType: .textPlain,
            url: finalURL
        )
        return try await request.sendRequest()
    }

    @MainActor static func getMedia(post: Post) async throws -> Data {
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
