//
//  ContentView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            TwoCentsEntryView(entry: TwoCentsEntry(
                date: Date(),
                text: "Preview Text",
                imageUrl: "https://cdn.nba.com/headshots/nba/latest/1040x760/1628369.png"
            ))
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
