//
//  TwoCentsWidget.swift
//  TwoCentsWidget
//
//  Created by Joshua Shen on 2/25/25.
//

import WidgetKit
import SwiftUI

struct TwoCentsTimelineProvider: TimelineProvider{
    func placeholder(in context: Context) -> TwoCentsEntry {
            TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .OTHER, dateCreated: Date(), caption: "Placeholder")
        }

    func getSnapshot(in context: Context, completion: @escaping (TwoCentsEntry) -> ()) {
            let entry = TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "Snapshot Example")
            completion(entry)
        }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TwoCentsEntry>) -> ()) {
            let entries: [TwoCentsEntry] = [
                TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "Image Post"),
                TwoCentsEntry(date: Date().addingTimeInterval(300), id: UUID(), userId: UUID(), media: .VIDEO, dateCreated: Date(), caption: "Video Post"),
                TwoCentsEntry(date: Date().addingTimeInterval(600), id: UUID(), userId: UUID(), media: .LINK, dateCreated: Date(), caption: "Link Post")
            ]

            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

//IDK?????
struct TwoCentsEntry: TimelineEntry {
    let date: Date
    let id: UUID
    let userId: UUID
    var media: Media
    var dateCreated: Date
    var caption: String?
}

enum Media: String, Codable {
    case IMAGE
    case VIDEO
    case LINK
    case OTHER
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

//wtf going on with the UI
struct TwoCentsWidgetEntryView: View {
    let entry: TwoCentsEntry

    var body: some View {
        VStack {
            switch entry.media {
            case .IMAGE:
                ImageWidgetView(entry: entry)
            case .VIDEO:
                VideoWidgetView(entry: entry)
            case .LINK:
                LinkWidgetView(entry: entry)
            case .OTHER:
                DefaultWidgetView(entry: entry)
            }
        }.padding(EdgeInsets(top: -16, leading: 0, bottom: -16, trailing: 0))
    }
}

// Example subviews for different media types

struct ImageWidgetView: View {
    let entry: TwoCentsEntry

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1) Background fills entire widget
            AsyncImage(url: URL(string: "https://media.tacdn.com/media/attractions-splice-spp-674x446/12/62/15/f1.jpg")) { phase in
                switch phase {
                case .empty:
                    // Use a full-size placeholder
                    Rectangle()
                        .fill(Color.blue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaledToFill()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    Color.clear
                }
            }

            // 2) A fixed-height bottom bar
            //    so the bottom edge never moves,
            //    even if the text changes length.
            VStack {
                if let caption = entry.caption {
                    Text(caption)
                        .foregroundColor(.white)
                        .lineLimit(2)   // or however many lines you want
                        .truncationMode(.tail)
                }
            }
            // This frame ensures the bar is always the same height
            .frame(height: 50)                // <--- Adjust as needed
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)   // blur effect         // space from the bottom edge
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ensures the ZStack itself spans the widget
        .containerBackground(.clear, for: .widget)
    }
}


struct VideoWidgetView: View {
    let entry: TwoCentsEntry

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1) Background fills entire widget
            AsyncImage(url: URL(string: "https://media.tacdn.com/media/attractions-splice-spp-674x446/12/62/15/f1.jpg")) { phase in
                switch phase {
                case .empty:
                    // Use a full-size placeholder
                    Rectangle()
                        .fill(Color.blue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaledToFill()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    Color.clear
                }
            }

            // 2) A fixed-height bottom bar
            //    so the bottom edge never moves,
            //    even if the text changes length.
            VStack {
                if let caption = entry.caption {
                    Text(caption)
                        .foregroundColor(.white)
                        .lineLimit(2)   // or however many lines you want
                        .truncationMode(.tail)
                }
            }
            // This frame ensures the bar is always the same height
            .frame(height: 50)                // <--- Adjust as needed
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)   // blur effect         // space from the bottom edge
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ensures the ZStack itself spans the widget
        .containerBackground(.clear, for: .widget)
    }
}

struct LinkWidgetView: View {
    let entry: TwoCentsEntry

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1) Background fills entire widget
            AsyncImage(url: URL(string: "https://media.tacdn.com/media/attractions-splice-spp-674x446/12/62/15/f1.jpg")) { phase in
                switch phase {
                case .empty:
                    // Use a full-size placeholder
                    Rectangle()
                        .fill(Color.blue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaledToFill()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    Color.clear
                }
            }

            // 2) A fixed-height bottom bar
            //    so the bottom edge never moves,
            //    even if the text changes length.
            VStack {
                if let caption = entry.caption {
                    Text(caption)
                        .foregroundColor(.white)
                        .lineLimit(2)   // or however many lines you want
                        .truncationMode(.tail)
                }
            }
            // This frame ensures the bar is always the same height
            .frame(height: 50)                // <--- Adjust as needed
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)   // blur effect         // space from the bottom edge
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ensures the ZStack itself spans the widget
        .containerBackground(.clear, for: .widget)
    }
}

struct DefaultWidgetView: View {
    let entry: TwoCentsEntry

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1) Background fills entire widget
            AsyncImage(url: URL(string: "https://media.tacdn.com/media/attractions-splice-spp-674x446/12/62/15/f1.jpg")) { phase in
                switch phase {
                case .empty:
                    // Use a full-size placeholder
                    Rectangle()
                        .fill(Color.blue)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaledToFill()
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.red)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                @unknown default:
                    Color.clear
                }
            }

            // 2) A fixed-height bottom bar
            //    so the bottom edge never moves,
            //    even if the text changes length.
            VStack {
                if let caption = entry.caption {
                    Text(caption)
                        .foregroundColor(.white)
                        .lineLimit(2)   // or however many lines you want
                        .truncationMode(.tail)
                }
            }
            // This frame ensures the bar is always the same height
            .frame(height: 50)                // <--- Adjust as needed
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)   // blur effect         // space from the bottom edge
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ensures the ZStack itself spans the widget
        .containerBackground(.clear, for: .widget)
    }
}

struct TwoCentsWidget: Widget {
    let kind: String = "TwoCentsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TwoCentsTimelineProvider()) { entry in
            TwoCentsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("TwoCents Widget")
        .description("Displays content based on media type.")
    }
}

//extension ConfigurationAppIntent {
//    fileprivate static var smiley: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "😀"
//        return intent
//    }
//    
//    fileprivate static var starEyes: ConfigurationAppIntent {
//        let intent = ConfigurationAppIntent()
//        intent.favoriteEmoji = "🤩"
//        return intent
//    }
//}

#Preview(as: .systemLarge) {
    TwoCentsWidget()
} timeline: {
    TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "Photo Test")
    TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .VIDEO, dateCreated: Date(), caption: "Video test")
    TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .LINK, dateCreated: Date(), caption: "Link test")
    TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .OTHER, dateCreated: Date(), caption: "Other test")
}
