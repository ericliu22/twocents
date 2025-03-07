//
//  TwoCentsApp.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI
import FirebaseCore

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
        appModel = AppModel()

        return true
    }
}
