//
//  User.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//
import Foundation

public class User: Identifiable, Codable, Hashable, Equatable {
    public let userId: UUID
    public var username: String
    public var profilePic: String?
    public var name: String?
    public var dateCreated: Date?
    public var posts: Int?
    
    public var id: UUID {
        return userId
    }
    
    public init(userId: UUID = UUID(), username: String, profilePic: String? = nil, name: String? = nil) {
        self.userId = userId
        self.username = username
        self.profilePic = profilePic
        self.name = name
        self.dateCreated = Date()
        self.posts = 0
    }
    
    // Equatable conformance
    public static func == (lhs: User, rhs: User) -> Bool {
        return lhs.userId == rhs.userId
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
    }
}
