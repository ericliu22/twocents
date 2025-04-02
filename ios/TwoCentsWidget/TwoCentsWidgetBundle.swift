//
//  TwoCentsWidgetBundle.swift
//  TwoCentsWidget
//
//  Created by Joshua Shen on 2/25/25.
//

import WidgetKit
import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct TwoCentsWidgetBundle: WidgetBundle {
    
    init() {
        FirebaseApp.configure()
        
        do {
            try Auth.auth().useUserAccessGroup("432WVK3797.com.twocentsapp.newcents.keychain-group")
        } catch let error as NSError {
            print("Error changing user access group: ", error)
        }
    }
    
    var body: some Widget {
        TwoCentsWidget()
        TwoCentsWidgetControl()
        TwoCentsWidgetLiveActivity()
    }
}
