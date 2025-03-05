//
//  AuthenticationManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//
import FirebaseAuth

struct AuthDataResultModel {
    let uid: String
    let email: String?

    init(user: FirebaseAuth.User) {
        self.uid = user.uid
        self.email = user.email
    }
}

struct AuthenticationManager {

    private init() {}

    static func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user: FirebaseAuth.User = Auth.auth().currentUser else {
            throw AuthErrorCode.nullUser
        }

        return AuthDataResultModel(user: user)
    }

    //Don't use this unless absolutely necessary. This shit is essentially the user's password
    static func getJwtToken() async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw AuthErrorCode.nullUser
        }

        return try await user.getIDToken()
    }

    //WITH EMAIL
    static func createEmailUser(email: String, password: String) async throws
        -> AuthDataResultModel
    {
        let authDataResult = try await Auth.auth().createUser(
            withEmail: email, password: password)

        return AuthDataResultModel(user: authDataResult.user)
    }

    static func signInUser(email: String, password: String) async throws
        -> AuthDataResultModel
    {
        let authDataResult = try await Auth.auth().signIn(
            withEmail: email, password: password)

        return AuthDataResultModel(user: authDataResult.user)
    }

    static func deleteUser() async {
        guard await ((try? Auth.auth().currentUser?.delete()) != nil) else {
            return
        }

        return
    }

    static func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    static func updateEmail(email: String) async throws {
        guard let user: FirebaseAuth.User = Auth.auth().currentUser else {
            throw AuthErrorCode.nullUser
        }

        try await user.sendEmailVerification(beforeUpdatingEmail: email)
    }

    static func updatePassword(password: String) async throws {
        guard let user: FirebaseAuth.User = Auth.auth().currentUser else {
            throw AuthErrorCode.nullUser
        }

        try await user.updatePassword(to: password)
    }

    static func signOut() throws {
        try Auth.auth().signOut()
    }

}
