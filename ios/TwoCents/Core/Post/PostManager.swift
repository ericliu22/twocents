//
//  PostManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//

import Foundation

fileprivate struct CreatePostRequest: Encodable {
    
    let id: UUID
    let media: Media
    
}

struct PostManager {
    
    private init() {}
    
    static let POST_URL: URL = API_URL.appending(path: "post")
    
    static func createImagePost(media: Media, imageData: Data, fileName: String) async throws {
        let boundary: UUID = UUID()
        
        let request = Request (
            method: .POST,
            contentType: .json,
            url: POST_URL.appending(path: "create-post"),
            body: CreatePostRequest(id: boundary, media: .IMAGE)
        )
        do {
            try await request.sendRequest()
            try await Request<String>.uploadMedia(fileData: imageData, fileName: fileName, mimeType: "image/jpeg", url: POST_URL.appending(path: "upload-image-post"), boundary: boundary)
        } catch let error {
            
            throw error
        }
        
    }
}
