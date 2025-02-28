//
//  User.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//
import Foundation

class User: Identifiable, Codable {
    
    let userId: UUID
    var username: String
    var profilePic: String?
    var name: String?
    
}
