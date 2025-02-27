//
//  UserManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import Foundation

//We don't use shared
struct UserManager {
    
    private init() {}

    static let USER_URL: URL = API_URL.appending(path: "user")

    static func registerEmailUser(username: String, email: String, password: String) async throws {
        do {
            let authResult = try await AuthenticationManager.createEmailUser(email: email, password: password)
            try await AuthenticationManager.signInUser(email: email, password: password)
            
            let body = [
                "username": username,
            ]
            let request = Request (
                method: .POST,
                contentType: .json,
                url: USER_URL.appending(path: "register-user"),
                body: body
            )
            //@TODO: Add user type
            _ = try await request.sendRequest()
            
        } catch let error {
            /*
            We emergency delete the user incase it fails after creating Firebase account
            but before the account is sent to database
            */
            print(error)
            await AuthenticationManager.deleteUser()
            throw error
        }
    }
    
    static func fetchCurrentUser() async -> User? {
        let request = Request<String>(method: .GET, contentType: .textPlain, url: USER_URL.appending(path: "get-current-user"))
        
        guard let userData = try? await request.sendRequest() else {
            print("Failed to send request")
            return nil
        }
        
        guard let user = try? JSONDecoder().decode(User.self, from: userData) else {
            print("Failed to decode user")
            return nil
        }
        
        return user
    }
}
