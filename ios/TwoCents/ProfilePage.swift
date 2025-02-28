//
//  ProfilePage.swift
//  TwoCents
//
//  Created by Joshua Shen on 2/26/25.
//

import SwiftUI
import FirebaseCore

// need viewmodel

struct ProfilePage: View {
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    ZStack {
                        AsyncImage(url: URL(string: "https://media.tacdn.com/media/attractions-splice-spp-674x446/12/62/15/f1.jpg"))
                            .frame(width: 120, height: 120)
                            .cornerRadius(64)
                    }
                    Spacer()
                    VStack {
                        Text("@" + "user_name")
                            .font(.title)
                    }
                    Spacer()
                }
                .padding(.vertical)
                
                ZStack {
                    //if not self, should say add friend
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.thinMaterial)
                        .frame(height: 60)
                        .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
                    Button(action: {
                        print("tapped edit profile")
                    }) {
                        Text("Edit Profile")
                            .foregroundStyle(.black)
                            .font(.system(size: 20))
                    }
                }
                
                HStack {
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.thinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                        Button(action: {
                            print("tapped new group")
                        }) {
                            Text("Groups")
                                .foregroundStyle(.black)
                                .font(.system(size: 20))
                                .padding()
                        }
                    }
                    Spacer()
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.thinMaterial)
                            .aspectRatio(1, contentMode: .fit)
                        Button(action: {
                            print("Tapped Requests")
                        }) {
                            Text("Requests")
                                .foregroundStyle(.black)
                                .font(.system(size: 20))
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline) // Forces inline style, making toolbar visible
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("Tapped settings")
                    }) {
                        Image(systemName: "gear")
                            .imageScale(.large)
                            .foregroundStyle(.black)
                    }
                }
            }
        }
    }
}


#Preview {
    ProfilePage()
}
