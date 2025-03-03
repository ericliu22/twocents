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
}

struct PostManager {
    
    private init() {}
    
    static let POST_URL: URL = API_URL.appending(path: "post")
    
    static func uploadPost(media: Media, caption: String? = nil) async throws -> Data {
        let requestBody: PostRequest = PostRequest(media: media, caption: caption)
        let request: Request = Request(
            method: .POST,
            contentType: .json,
            url: POST_URL.appending(path: "create-post"),
            body: try JSONEncoder().encode(requestBody)
        )
        return try await request.sendRequest()
    }
    
    static func uploadMediaPost(media: Media, data: Data, caption: String? = nil) async throws -> Data {
        let postData: Data = try await uploadPost(media: media)
        let post: Post = try JSONDecoder().decode(Post.self, from: postData)
        
        let uploadPost: any Uploadable = makeUploadable(post: post, data: data)
        let data: Data = try await uploadPost.uploadPost()
        return data
    }
}
