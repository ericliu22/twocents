//
//  ContentView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI

struct HomePageView: View {
    var body: some View {
        VStack{
            TabView{
                ForUsPage()
                    .tabItem{
                        Image(systemName: "house.fill")
                    }
                //placeholder for upload page
                Text("upload soon")
                    .tabItem{
                        Image(systemName: "plus.app")
                    }
                ProfilePage()
                    .tabItem{
                        Image(
                            systemName: "person"
                        )
                    }
            }.accentColor(.black)
        }
    }
}

#Preview {
    HomePageView()
}
