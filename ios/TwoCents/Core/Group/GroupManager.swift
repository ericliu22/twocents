//
//  GroupManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/5.
//
import Foundation

struct GroupManager {
    
    private init() {}
    
    static let GROUP_URL: URL = API_URL.appending(path: "group")
    
    /* If we need this function tell me -Eric
    static func fetchGroup(groupId: UUID) async throws -> Group {
        
    }
     */
    
    static func fetchGroupMembers(groupId: UUID) async throws -> [GroupMember] {
        let request = Request<String> (
            method: .GET,
            contentType: .json,
            url: GROUP_URL.appending(path: "get-members?groupId=\(groupId.uuidString)")
        )
        let data = try await request.sendRequest()
        return try TwoCentsDecoder().decode([GroupMember].self, from: data)
    }
    
    static func fetchUserGroups() async throws -> [FriendGroup] {
        let request = Request<String> (
            method: .GET,
            contentType: .json,
            url: GROUP_URL.appending(path: "get-user-posts")
        )
        
        let data = try await request.sendRequest()
        return try TwoCentsDecoder().decode([FriendGroup].self, from: data)
    }
}
