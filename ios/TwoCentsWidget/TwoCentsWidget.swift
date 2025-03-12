//
//  TwoCentsWidget.swift
//  TwoCentsWidget
//
//  Created by Joshua Shen on 2/25/25.
//

import WidgetKit
import SwiftUI
import TwoCentsInternal

var HARDCODED_DATE: Date {
    var dateComponents = DateComponents()
    dateComponents.year = 2025
    dateComponents.month = 3
    dateComponents.day = 8
    return Calendar.current.date(from: dateComponents)!
}
let HARDCODED_GROUP = FriendGroup(id: UUID(uuidString: "b343342a-d41b-4c79-a8a8-7e0b142be6da")!, name: "TwoCents", dateCreated: HARDCODED_DATE, ownerId: UUID(uuidString: "bb444367-e219-41e0-bfe5-ccc2038d0492")!)

struct TwoCentsTimelineProvider: TimelineProvider{
    let group: FriendGroup
    func placeholder(in context: Context) -> TwoCentsEntry {
//            TwoCentsEntry((date: Date(), id: UUID(), userId: UUID(), media: .OTHER, dateCreated: Date(), caption: "Placeholder"))
        return TwoCentsEntry.dummy
        //replace with empty list
        }

    func getSnapshot(in context: Context, completion: @escaping (TwoCentsEntry) -> ()) {
        completion(TwoCentsEntry.dummy)
        //empty view
        }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TwoCentsEntry>) -> ()) {
//            let entries: [TwoCentsEntry] = [
//                TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "Image Post"),
//                TwoCentsEntry(date: Date().addingTimeInterval(300), id: UUID(), userId: UUID(), media: .VIDEO, dateCreated: Date(), caption: "Video Post"),
//                TwoCentsEntry(date: Date().addingTimeInterval(600), id: UUID(), userId: UUID(), media: .LINK, dateCreated: Date(), caption: "Link Post")
//            ]
        Task{
            var fetchedPosts: [Post] = []
            do {
                let postsData = try await PostManager.getGroupPosts(groupId: HARDCODED_GROUP.id)
                fetchedPosts = try TwoCentsDecoder().decode([Post].self, from: postsData)
                var entries: [TwoCentsEntry] = []
                for post in fetchedPosts {
                    let entry = TwoCentsEntry(date: Date(), posts: [post], id: post.id, userId: post.userId, media: post.media, dateCreated: post.dateCreated, caption: post.caption)
                    entries.append(entry)
                    // Add this entry to your timeline or wherever needed
                }
                let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
                    completion(timeline)
            } catch {
                print("Error fetching data")
            }
        }
//        let entry = TwoCentsEntry(date: Date(), posts: fetchedPosts)
//        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
//        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
//            completion(timeline)
        }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

//IDK?????
struct TwoCentsEntry: TimelineEntry {
    let date: Date
    let posts: [Post]
    let id: UUID
    let userId: UUID
    var media: Media
    var dateCreated: Date
    var caption: String?
}

//enum Media: String, Codable {
//    case IMAGE
//    case VIDEO
//    case LINK
//    case OTHER
//}

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
            case .TEXT:
                DefaultWidgetView(entry: entry)
            }
            //Don't touch this padding, otherwise caption breaks widget
        }.padding(EdgeInsets(top: -16, leading: 0, bottom: -16, trailing: 0))
    }
}

extension TwoCentsEntry {
    static var dummy: TwoCentsEntry {
        // Create a dummy post for the sake of the dummy entry.
        let dummyPost = Post(
            id: UUID(),
            userId: UUID(),
            media: .OTHER, // Use any Media type that fits
            dateCreated: Date(),
            caption: "Dummy post caption"
        )
        
        // Build the dummy entry.
        return TwoCentsEntry(
            date: Date(),
            posts: [dummyPost],
            id: UUID(),
            userId: UUID(),
            media: .OTHER,
            dateCreated: Date(),
            caption: "Dummy entry caption"
        )
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
        StaticConfiguration(kind: kind, provider: TwoCentsTimelineProvider(group: HARDCODED_GROUP)) { entry in
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

//#Preview(as: .systemLarge) {
//    TwoCentsWidget()
//} timeline: {
//    TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "Photo Test")
//    TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .VIDEO, dateCreated: Date(), caption: "Video test")
//    TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .LINK, dateCreated: Date(), caption: "Link test")
//    TwoCentsEntry(date: Date(), id: UUID(), userId: UUID(), media: .OTHER, dateCreated: Date(), caption: "Other test")
//}
