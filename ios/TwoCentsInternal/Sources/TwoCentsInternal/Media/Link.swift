//
//  Link.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//

import SwiftUI
import LinkPresentation

public class LinkUpload: Uploadable {
    
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
        Group {
            if let link {
                Text(link.mediaUrl)
                    .frame(maxWidth: .infinity, maxHeight:.infinity)
            } else {
                ProgressView().progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight:.infinity)
            }
        }
        .task {
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            let links = try? JSONDecoder().decode([LinkDownload].self, from: data)
            link = links?.first
        }
    }
}
