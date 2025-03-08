//
//  PostManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//

import Foundation

struct PostRequest: Encodable {
    let media: Media
    let caption: String?
    let groups: [UUID]
}

//CanvasWidget: Post
//Media: Image

struct PostManager {
    
    private init() {}
    
    static let POST_URL: URL = API_URL.appending(path: "post")
    
    static func uploadPost(postRequest: PostRequest) async throws -> Post {
        let request: Request = Request(
            method: .POST,
            contentType: .json,
            url: POST_URL.appending(path: "create-post"),
            body: postRequest
        )
        let data = try await request.sendRequest()
        return try TwoCentsDecoder().decode(Post.self, from: data)
    }
    
    static func uploadMediaPost(post: Post, data: Data) async throws -> Data {
        //The media
        let uploadPost: any Uploadable = makeUploadable(post: post, data: data)
        //The downloadable
        let data: Data = try await uploadPost.uploadPost()
        return data
    }
    
    static func getGroupPosts(groupId: UUID) async throws -> Data {
        // Base URL: https://api.twocentsapp.com/v1/post/get-group-posts
        let baseURL = POST_URL.appendingPathComponent("get-group-posts")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "groupId", value: groupId.uuidString)
        ]
        
        guard let finalURL = components.url else {
            fatalError("Failed to construct URL")
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

    static func getMedia(post: Post) async throws -> Data {
        let request: Request = Request<String> (
            method: .GET,
            contentType: .json,
            url: POST_URL.appending(path: "get-media?postId=\(post.id)&media=\(post.media)"))
        return try await request.sendRequest()
    }
}
