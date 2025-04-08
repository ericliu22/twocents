//
//  AppModel.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import SwiftUI
import Combine
import Foundation

enum AppSheet: String, Hashable, Equatable, Identifiable {
    
    var id: String {
        self.rawValue
    }
    
    case signIn
    
}

//added "Observable Object"
@Observable @MainActor
final class AppModel {
    var currentUser: User?
    var activeSheet: AppSheet?
    var deepLinkPostID: UUID? = nil
    var selectedPostID: UUID? = nil
}
