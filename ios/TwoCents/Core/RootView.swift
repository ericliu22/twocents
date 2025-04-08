//
//  ContentView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI


var HARDCODED_DATE: Date {
    var dateComponents = DateComponents()
    dateComponents.year = 2025
    dateComponents.month = 3
    dateComponents.day = 8
    return Calendar.current.date(from: dateComponents)!
}
let HARDCODED_GROUP = FriendGroup(id: UUID(uuidString: "b343342a-d41b-4c79-a8a8-7e0b142be6da")!, name: "TwoCents", dateCreated: HARDCODED_DATE, ownerId: UUID(uuidString: "bb444367-e219-41e0-bfe5-ccc2038d0492")!)
struct RootView: View {
    @Environment(AppModel.self) var appModel
    @AppStorage("didRequestNotifications") private var didRequestNotifications: Bool = false
    
    var body: some View {
        @Bindable var appModel = appModel
        
        TabView {
//            ForUsPage(group: HARDCODED_GROUP)
//                .tabItem {
//                    Label("Home", systemImage: "house.fill")
//                }
//                //.tag(Tab.defaulthome)
//            
            ExploreView(group: HARDCODED_GROUP)
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
            
            
            CreatePostView()
                .tabItem {
                    Label("Create", systemImage: "plus.app")
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
            } else {
                if !didRequestNotifications {
                    requestNotificationAuthorization()
                    didRequestNotifications = true
                }
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
        .tint(.green)
//        .onChange(of: appModel.deepLinkPostID) { newPostID in
//                    if let postID = newPostID {
//                        print("got here")
//                        print(appModel.selectedPostID)
//                        print(appModel.deepLinkPostID)
//                        // Propagate the deep link to the navigation state in ExploreView
//                        appModel.selectedPostID = postID
//                        // Optionally clear deepLinkPostID once handled
//                        appModel.deepLinkPostID = nil
//                    }
//                }
        .onOpenURL { url in
                    print("onOpenURL received: \(url)")
                    if url.scheme == "twocents", url.host == "post" {
                        let postIDString = url.lastPathComponent
                        if let postID = UUID(uuidString: postIDString) {
                            appModel.deepLinkPostID = postID
                            print("Navigating to post with ID: \(postID)")
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
//
//
//struct ProfileView: View {
//    var body: some View {
//        Text("Profile Screen")
//            .padding()
//    }
//}
