//
//  User.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//
import Foundation

class User: Codable {
    
    let id: UUID
    var username: String
    var profilePic: String?
    var name: String?
    
}
