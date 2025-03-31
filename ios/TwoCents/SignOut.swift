//
//  SignOut.swift
//  TwoCents
//
//  Created by Joshua Shen on 2/28/25.
//

import SwiftUI
import FirebaseCore

struct SignOutView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        @Bindable var appModel = appModel
        VStack {
            Button {
                do {
                    try AuthenticationManager.signOut()
                    
                    UIApplication.shared.unregisterForRemoteNotifications()
                    print("Unregistered for remote notifications")
                    Task {
                        try await UserManager.removeDeviceToken()
                        appModel.activeSheet = .signIn
                    }
                } catch let error {
                    print("Failed to sign out \(error.localizedDescription)")
                }
            } label: {
                Text("Sign Out")
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}
