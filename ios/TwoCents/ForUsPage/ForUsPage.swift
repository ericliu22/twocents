//
//  ForUsPage.swift
//  TwoCents
//
//  Created by Joshua Shen on 2/26/25.
//

import SwiftUI
import FirebaseCore

struct ForUsPage: View {
        var body: some View{
            List{
                PostView()
                PostView()
                PostView()
            }
    }
}

//fetch posts from database
