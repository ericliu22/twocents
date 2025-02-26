//
//  AppModel.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import SwiftUI

enum AppSheet: String, Hashable, Equatable, Identifiable {
    
    var id: String {
        self.rawValue
    }
    
    case signIn
    
}

@Observable @MainActor
final class AppModel {
    var user: DBUser?
    var activeSheet: AppSheet?
}
