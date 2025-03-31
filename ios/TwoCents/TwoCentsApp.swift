//
//  TwoCentsApp.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import TwoCentsInternal

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
        UNUserNotificationCenter.current().delegate = self
        
        requestNotificationAuthorization()
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification authorization status: \(settings.authorizationStatus)")
        }
        appModel = AppModel()

        return true
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        print("RAN delegate THIS")
        
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        
        let tokenString = tokenParts.joined()
        
        print("Device Token: \(tokenString)")
        
        // TODO: Send this token to your server, e.g. via an HTTPS request.
        Task {
            try await UserManager.uploadDeviceToken(token: tokenString)
        }
    }

}
extension AppDelegate: UNUserNotificationCenterDelegate {
    // This is called if a notification is delivered while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Decide how to present alert, sound, badge, etc.
        completionHandler([.banner, .sound, .badge])
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
}

func requestNotificationAuthorization() {
        print("RAN THIS")
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            guard error == nil else {
                print("Error requesting authorization: \(String(describing: error))")
                return
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("UI Application registered for remote notifications.")
                }
            } else {
                print("User denied notification permissions.")
            }
        }
}
