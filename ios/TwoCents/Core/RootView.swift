//
//  ContentView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        @Bindable var appModel = appModel
        VStack {
            Text("hello")
            Button {
                do {
                    try AuthenticationManager.signOut()
                } catch let error {
                    print("Failed to sign out \(error.localizedDescription)")
                }
            } label: {
                Text("Sign Out")
            }
        }
        .padding()
        .onAppear{
            let authUser = try? AuthenticationManager.getAuthenticatedUser()
            
            if authUser == nil {
                appModel.activeSheet = .signIn
            }
        }
        .fullScreenCover(item: $appModel.activeSheet) { item in
            NavigationStack {
                switch item {
                case .signIn:
                    AuthenticationView()
                }
            }
        }
    }
}

#Preview {
    RootView()
}
