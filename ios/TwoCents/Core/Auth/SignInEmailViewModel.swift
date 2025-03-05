//
//  SignInEmailViewModel.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//
import SwiftUI

enum SignInError: Error {
    case emptyField
}

extension SignInError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyField:
            return NSLocalizedString("No email or password found.", comment: "")
        }
    }
}

@Observable @MainActor
final class SignInEmailViewModel {
    
    var email: String = ""
    var password: String = ""
    var errorMessage: String = ""
    
    func signIn() async throws -> User? {
        guard !email.isEmpty, !password.isEmpty else {
            throw SignInError.emptyField
        }
        
        _ = try await AuthenticationManager.signInUser(email: email, password: password)
        return await UserManager.fetchCurrentUser()
    }
}
