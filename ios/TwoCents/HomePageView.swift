//
//  ContentView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI
import UIKit

struct HomePageView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        VStack{
            TabView{
                ForUsPage()
                    .tabItem{
                        Image(systemName: "house.fill")
                    }
                //placeholder for upload page
                //CameraPickerView()
                Text("placeholder")
                    .tabItem{
                        Image(systemName: "plus.app")
                    }
                ProfilePage()
                    .tabItem{
                        Image(systemName: "person")
                    }
                //change later
                SignOutView()
                    .tabItem{
                        Image(systemName: "person.fill.badge.minus")
                    }
                PostTest()
                    .tabItem{
                        Image(systemName: "person.fill.badge.minus")
                    }
            }.accentColor(.black)
        }
    }
}

#Preview {
    HomePageView()
}
