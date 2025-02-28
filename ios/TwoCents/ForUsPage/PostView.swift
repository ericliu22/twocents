//
//  Post.swift
//  TwoCents
//
//  Created by Joshua Shen on 2/26/25.
//

import SwiftUI
import FirebaseCore

struct PostView: View {
    var body: some View {
        VStack{
            Text("Mock Post")
                .padding()
                .background(Color.gray)
            Button(action: {
                print("tapped like")
            }) {
                Image(systemName: "heart.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .foregroundColor(.red)
            }
        }.padding()
    }
}
