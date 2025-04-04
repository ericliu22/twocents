//
//  TextWidgetView.swift
//  TwoCents
//
//  Created by Eric Liu on 3/31/25.
//
import SwiftUI

struct TextWidgetView: View {
    let entry: TwoCentsEntry
    let lines: [String]
    
    init(entry: TwoCentsEntry) {
        self.entry = entry
        let texts = entry.fetchedMedia as? [String]
        let text = texts?.first
        self.lines = text?.components(separatedBy: .newlines) ?? []
    }

    var body: some View {
        ZStack(alignment: .bottom) {

            LazyVStack(alignment: .leading) {
                ForEach(lines, id: \.self) { line in
                    Text(line)
                        .padding(.vertical, 2)
                }
            }
            
            VStack {
                if let caption = entry.post.caption {
                    Text(caption)
                        .foregroundColor(.white)
                        .lineLimit(2)   // or however many lines you want
                        .truncationMode(.tail)
                }
            }
            .frame(height: 50)                // <--- Adjust as needed
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)   // blur effect         // space from the bottom edge
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ensures the ZStack itself spans the widget
        .containerBackground(.clear, for: .widget)
    }
}

