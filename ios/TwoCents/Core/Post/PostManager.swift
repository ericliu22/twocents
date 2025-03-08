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
    
    static func uploadPost(postRequest: PostRequest) async throws -> Data {
        let request: Request = Request(
            method: .POST,
            contentType: .json,
            url: POST_URL.appending(path: "create-post"),
            body: postRequest
        )
        return try await request.sendRequest()
    }
    
    static func uploadMediaPost(postRequest: PostRequest, data: Data) async throws -> (Post, Data) {
        //The DBPost
        let postData: Data = try await uploadPost(postRequest: postRequest)
        
        let post: Post = try TwoCentsDecoder().decode(Post.self, from: postData)

        //The media
        let uploadPost: any Uploadable = makeUploadable(post: post, data: data)
        //The downloadable
        let data: Data = try await uploadPost.uploadPost()
        return (post, data)
    }
    
    static func getGroupPosts(groupId: UUID) async throws -> Data {
        let request: Request = Request<String> (
            method: .GET,
            contentType: .json,
            url: POST_URL.appending(path: "get-group-posts?groupId=\(groupId)"))
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
