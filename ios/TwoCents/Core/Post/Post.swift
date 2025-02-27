//
//  Post.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//
import Foundation

enum Media: String, Codable {
    case IMAGE
    case VIDEO
    case OTHER
}

class Post: Codable {
    
    let id: UUID
    var media: Media
    var mediaUrl: URL
    var dateCreated: Date
    
}
