//
//  PostManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//

import Foundation

fileprivate struct CreateImagePostRequest: Encodable {
    let id: UUID
    let media: Media = .IMAGE
    
    init(id: UUID = UUID()) {
        self.id = id
    }
}

struct PostManager {
    
    private init() {}
    
    static let POST_URL: URL = API_URL.appending(path: "post")
    
    static func createImagePost(media: Media, imageData: Data) {
        let boundary: UUID = UUID()
        let request = Request (
            method: .POST,
            contentType: .json,
            url: POST_URL,
            body: CreateImagePostRequest(id: boundary)
        )
    }
    
}
