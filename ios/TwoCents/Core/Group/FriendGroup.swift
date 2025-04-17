//
//  Group.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/5.
//
import Foundation
import TwoCentsInternal

enum Role: String, Codable {
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

class FriendGroup: Identifiable, Codable {
    
    let id: UUID
    var name: String
    let dateCreated: Date
    let ownerId: UUID
    
    init(id: UUID, name: String, dateCreated: Date, ownerId: UUID) {
        self.id = id
        self.name = name
        self.dateCreated = dateCreated
        self.ownerId = ownerId
    }
    
}
