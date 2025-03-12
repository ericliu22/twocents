//
//  GroupManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/5.
//
import Foundation
import TwoCentsInternal

struct GroupManager {
    
    private init() {}
    
    static let GROUP_URL: URL = API_URL.appending(path: "group")
    
    /* If we need this function tell me -Eric
    static func fetchGroup(groupId: UUID) async throws -> Group {
        
    }
     */
    
    static func fetchGroupMembers(groupId: UUID) async throws -> [User] {
        let baseURL = GROUP_URL.appendingPathComponent("get-members")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "groupId", value: groupId.uuidString)
        ]
        
        guard let finalURL = components.url else {
            print("failed to construct url")
            throw URLError.init(URLError.Code(rawValue: 404))
        }
        let request = Request<String> (
            method: .GET,
            contentType: .json,
            url: finalURL
        )
        let data = try await request.sendRequest()
        return try TwoCentsDecoder().decode([User].self, from: data)
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
