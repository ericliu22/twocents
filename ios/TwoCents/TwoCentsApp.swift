//
//  TwoCentsApp.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
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

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    var appModel: AppModel?
    
    //Deeplink Function:
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("deeplink application func reached")
        // Check if the URL matches your custom scheme and host
        if url.scheme == "twocents", url.host == "post" {
            // Extract the post ID from the path
            let postIDString = url.lastPathComponent
            if let postID = UUID(uuidString: postIDString) {
                appModel?.deepLinkPostID = postID
                print("Navigating to post with ID: \(postID)")
                return true
            }
        }
        return false
    }
    
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        print("second application function reached")
        do {
            try Auth.auth().useUserAccessGroup("432WVK3797.com.twocentsapp.newcents.keychain-group")
        } catch let error as NSError {
            print("Error changing user access group: ", error)
        }
        appModel = AppModel()
        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: { _, _ in }
        )

        application.registerForRemoteNotifications()

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = parseDeviceToken(from: deviceToken)
        print("DEVICE TOKEN \(token)")
        Task {
            try await UserManager.uploadDeviceToken(token: token)
        }
    }

    func parseDeviceToken(from data: Data) -> String {
        return data.map { String(format: "%02.2hhx", $0) }.joined()
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError
                     error: Error) {
        // Try again later.
        print("FAILED TO REGISTER FOR NOTIFICATIONS")
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let deviceToken: [String: String] = ["token": fcmToken ?? ""]
        Task {
            try await UserManager.uploadDeviceToken(token: fcmToken ?? "")
        }
    }
}
extension AppDelegate {
    // This is called if a notification is delivered while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Decide how to present alert, sound, badge, etc.
        completionHandler([.banner, .sound, .badge])
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
