//
//  UserManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import Foundation
import TwoCentsInternal

//We don't use shared
struct UserManager {
    
    private init() {}

    static let USER_URL: URL = API_URL.appending(path: "user")

    static func registerEmailUser(username: String, email: String, password: String) async throws -> User {
        do {
            let _ = try await AuthenticationManager.createEmailUser(email: email, password: password)
            _ = try await AuthenticationManager.signInUser(email: email, password: password)
            
            let body = [
                "username": username,
            ]
            let request = Request (
                method: .POST,
                contentType: .json,
                url: USER_URL.appending(path: "register-user"),
                body: body
            )
            
            let userData = try await request.sendRequest()
            let user = try JSONDecoder().decode(User.self, from: userData)
            return user
            
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
        let request = Request<String>(
            method: .GET,
            contentType: .textPlain,
            url: USER_URL.appending(path: "get-current-user")
        )
        
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
    
    static func uploadDeviceToken(token: String) async throws {
        let body = [
            "deviceToken": token,
        ]
        let request = Request (
            method: .POST,
            contentType: .json,
            url: USER_URL.appending(path: "register-device-token"),
            body: body
        )
        _ = try await request.sendRequest()
    }
    
    static func removeDeviceToken() async throws {
        
        // Retrieve the stored device token.
        if let token = UserDefaults.standard.string(forKey: "DeviceToken") {
            // Call your API endpoint to remove the token from your server.
            let body = [
                "deviceToken": token,
            ]
            let request = Request (
                method: .POST,
                contentType: .json,
                url: USER_URL.appending(path: "remove-device-token"),
                body: body
            )
            _ = try await request.sendRequest()
        }
    }
    
    static func updateProfilePic(imageData: Data) async throws {
        //We use a boundary because we don't want any part of the image data to contain said boundary or else it escapes early -Eric
        let boundary: UUID = UUID()
        
        var request = URLRequest(url: USER_URL.appending(path: "update-profile-pic"))
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let firebaseToken = try await AuthenticationManager.getJwtToken()
        request.setValue("Bearer \(firebaseToken)", forHTTPHeaderField: "Authorization")

        var body = Data()
        let mimeType: String = "image/jpeg"
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"myimage.jpg\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(imageData)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print(response)
            print(data)
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print(response)
            print(data)
            throw APIError.unexpectedStatusCode(httpResponse.statusCode)
        }
        
        if data.isEmpty {
            print(response)
            print(data)
            throw APIError.noData
        }
        return
    }
}
