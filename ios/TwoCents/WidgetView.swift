//
//  WidgetView.swift
//  TwoCents
//
//  Created by Joshua Shen on 2/24/25.
//

import SwiftUI
import Foundation
import WidgetKit

struct TwoCentsEntry: TimelineEntry {
    let date: Date
    let text: String
    let imageUrl: String // URL string for a remote image
}

struct TwoCentsEntryProvider: TimelineProvider {
    func placeholder(in context: Context) -> TwoCentsEntry {
        TwoCentsEntry(
            date: Date(),
            text: "Loading...",
            imageUrl: "https://example.com/placeholderImage.jpg"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TwoCentsEntry) -> Void) {
        let entry = TwoCentsEntry(
            date: Date(),
            text: "Snapshot text",
            imageUrl: "https://example.com/snapshotImage.jpg"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TwoCentsEntry>) -> Void) {
        var entries: [TwoCentsEntry] = []
        let currentDate = Date()
        // Generate entries for the next few hours (update frequency as needed)
        for hourOffset in 0..<5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = TwoCentsEntry(
                date: entryDate,
                text: "Updated text \(hourOffset)",
                imageUrl: "https://example.com/exampleImage.jpg"
            )
            entries.append(entry)
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct TwoCentsEntryView: View {
    var entry: TwoCentsEntryProvider.Entry

    var body: some View {
        VStack {
            Text(entry.text)
                .font(.headline)
            
            // Load the image using AsyncImage from a remote URL.
            if let url = URL(string: entry.imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        // Placeholder while the image loads
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    case .failure:
                        // Fallback image on failure
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                // Fallback view if URL is invalid
                Color.gray
            }
        }
        .padding()
    }
}

struct TwoCentsWidget: Widget {
    let kind: String = "TwoCentsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TwoCentsEntryProvider()) { entry in
            TwoCentsEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This widget displays text and a photo. Tap to open the app.")
    }
}

#Preview(as: .systemMedium, widget: {
    TwoCentsWidget()
}, timeline: {
    TwoCentsEntry(
        date: Date(),
        text: "Preview Text",
        imageUrl: "https://cdn.nba.com/headshots/nba/latest/1040x760/1628369.png"
    )
})
