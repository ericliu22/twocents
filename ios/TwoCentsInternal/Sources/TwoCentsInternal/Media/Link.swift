//
//  Link.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//

import SwiftUI

public class LinkUpload: Uploadable {
    
    public let post: Post
    public let data: Data

    public init(post: Post, data: Data) {
        self.post = post
        self.data = data
    }
    
    public func uploadPost() async throws -> Data {
        let boundary = UUID()
        var body = Data()
        let postData = try TwoCentsEncoder().encode(post)
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"post\"\r\n")
        body.append("Content-Type: application/json\r\n\r\n")
        body.append(postData)
        body.append("\r\n")
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"link\"\r\n")
        body.append("Content-Type: application/json\r\n\r\n")
        body.append(data)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        
        let request = Request (
            method: .POST,
            contentType: .json,
            url: PostManager.POST_URL.appending(path: "upload-link-post"),
            body: body
        )
        return try await request.sendRequest()
    }
    
}

struct LinkDownload: Downloadable {
    let id: UUID
    let postId: UUID
    let mediaUrl: String
}

struct LinkView: PostView {
    
    let post: Post
    @State var link: LinkDownload?
    
    init(post: Post) {
        self.post = post
    }
    
    var body: some View {
        Text("Not implemented yet")
    }
}
