//
//  User.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//
import Foundation

class User: Identifiable, Codable, Hashable, Equatable {
    let userId: UUID
    var username: String
    var profilePic: String?
    var name: String?
    
    var id: UUID {
        return userId
    }
    
    init(userId: UUID = UUID(), username: String, profilePic: String? = nil, name: String? = nil) {
        self.userId = userId
        self.username = username
        self.profilePic = profilePic
        self.name = name
    }
    
    // Equatable conformance
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
