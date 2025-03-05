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
        
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                //.tag(Tab.defaulthome)
            
            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
            CameraPickerView()
            //Text("placeholder")
                .tabItem{
                    Image(systemName: "plus.app")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .task {
            let authUser = try? AuthenticationManager.getAuthenticatedUser()
            
            if authUser == nil {
                appModel.activeSheet = .signIn
            } else if appModel.currentUser == nil {
                appModel.currentUser = await UserManager.fetchCurrentUser()
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
        .environment(AppModel())
}

// Example placeholder views
struct HomeView: View {
    var body: some View {
        VStack {
            Text("Home Screen")
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
    }
}


struct ProfileView: View {
    var body: some View {
        Text("Profile Screen")
            .padding()
    }
}
