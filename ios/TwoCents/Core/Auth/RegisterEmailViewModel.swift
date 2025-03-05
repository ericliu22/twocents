//
//  SignUpViewModel.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import Foundation

enum RegisterEmailError: Error {
    case emptyField, passwordNotEqual
}

extension RegisterEmailError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyField:
            return NSLocalizedString("Fields are empty", comment: "")
        case .passwordNotEqual:
            return NSLocalizedString("Password and Confirm password are not the same", comment: "")
        }
    }
}
@Observable @MainActor
final class RegisterEmailViewModel {
    
    var name = ""
    var username = ""
    var email = ""
    var password = ""
    var confirmPassword = ""
    var errorMessage = ""
  
    
    func signUp() async throws -> User? {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty, /*!username.isEmpty,*/ !confirmPassword.isEmpty else {
            throw RegisterEmailError.emptyField
        }
        
        guard password == confirmPassword else {
            throw RegisterEmailError.passwordNotEqual
        }
        
        do {
            return try await UserManager.registerEmailUser(username: username, email: email, password: password)
        } catch let error {
            print(error.localizedDescription)
            throw error
        }
    }
    
}
