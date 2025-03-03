//
//  Link.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//

import SwiftUI

class LinkUpload: Uploadable {
    
    let post: Post
    let data: Data

    init(post: Post, data: Data) {
        self.post = post
        self.data = data
    }
    
    func uploadPost() async throws -> Data {
        let boundary = UUID()
        var body = Data()
        let encoder = JSONEncoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"  // Adjust based on your pgtype.Date format
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        let postData = try encoder.encode(post)
        
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
    let mediaUrl: String
}

struct LinkView: PostView {
    
    let post: Post
    let link: LinkDownload
    
    init(post: Post, link: LinkDownload) {
        self.post = post
        self.link = link
    }
    
    var body: some View {
        EmptyView()
    }
}
