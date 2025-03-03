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
                MockPost()
                MockPost()
                MockPost()
            }
    }
}

//fetch posts from database
