//
//  Group.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/5.
//
import Foundation

public enum Role: String, Codable {
    case ADMIN
    case MEMBER
}

class GroupMember: Codable {
    
    struct Member: Codable {
        let groupId: UUID
        let userId: UUID
        let joinedAt: Date
        let role: Role
    }
    
    let user: User
    let member: Member
    
}

public class FriendGroup: Identifiable, Codable {
    
    public let id: UUID
    public var name: String
    public let dateCreated: Date
    public let ownerId: UUID
    
    public init(id: UUID, name: String, dateCreated: Date, ownerId: UUID) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.ownerId = ownerId
    }
    
}
