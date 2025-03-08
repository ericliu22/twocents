//
//  ContentView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI
import UIKit

var HARDCODED_DATE: Date {
    var dateComponents = DateComponents()
    dateComponents.year = 2025
    dateComponents.month = 3
    dateComponents.day = 8
    return Calendar.current.date(from: dateComponents)!
}
let HARDCODED_GROUP = FriendGroup(id: UUID(uuidString: "b343342a-d41b-4c79-a8a8-7e0b142be6da")!, name: "TwoCents", dateCreated: HARDCODED_DATE, ownerId: UUID(uuidString: "bb444367-e219-41e0-bfe5-ccc2038d0492")!)
//We skip the fetch and just roll with this
struct HomePageView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        VStack{
            TabView{
                ForUsPage(group: HARDCODED_GROUP)
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
