//
//  Text.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/8.
//

import SwiftUI

public class TextUpload: Uploadable {
    
    public let post: Post
    public let data: Data

    public init(post: Post, data: Data) {
        self.post = post
        self.data = data
    }
    
    public func uploadPost() async throws -> Data {
        let body = try TwoCentsDecoder().decode([String: String].self, from: data)
        let request = Request (
            method: .POST,
            contentType: .json,
            url: PostManager.POST_URL.appending(path: "upload-text-post"),
            body: body
        )
        return try await request.sendRequest()
    }
    
}

public struct TextDownload: Downloadable {
    public let id: UUID
    public let postId: UUID
    public let text: String
}
