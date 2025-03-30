//
//  TwoCentsApp.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct TwoCentsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(delegate.appModel!)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var appModel: AppModel?
    
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        do {
            try Auth.auth().useUserAccessGroup("432WVK3797.com.twocentsapp.newcents.keychain-group")
        } catch let error as NSError {
            print("Error changing user access group: ", error)
        }
        appModel = AppModel()

        return true
    }
}
