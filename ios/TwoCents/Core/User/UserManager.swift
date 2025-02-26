//
//  UserManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import Foundation

//We don't use shared
struct UserManager {

    static let USER_URL: URL = API_URL.appending(path: "user")

    static func registerUser(userId: String, username: String, email: String, password: String) async throws {
        
        do {
            try await AuthenticationManager.createEmailUser(email: email, password: password)
            try await AuthenticationManager.signInUser(email: email, password: password)
            
            let body = [
                "userId": userId,
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
            await AuthenticationManager.deleteUser()
            throw error
        }
    }
}
