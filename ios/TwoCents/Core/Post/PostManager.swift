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
        // 1. Create the base URL: https://api.twocentsapp.com/v1/post/get-group-posts
        let baseURL = POST_URL.appendingPathComponent("get-group-posts")

        // 2. Construct URLComponents from the base URL
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        // 3. Add your query items
        components.queryItems = [
            URLQueryItem(name: "groupId", value: groupId.uuidString)
        ]

        // 4. Create the final URL with `?groupId=...`
        let finalURL = components.url!

        // 5. Use finalURL in your request
        let request: Request = Request<String>(
            method: .GET,
            contentType: .json,
            url: finalURL
        )
        
        // Print for debugging
        print(request.url.absoluteString)

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
