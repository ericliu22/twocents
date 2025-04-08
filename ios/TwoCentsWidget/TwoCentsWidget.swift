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

let HARDCODED_GROUP = FriendGroup(
    id: UUID(uuidString: "b343342a-d41b-4c79-a8a8-7e0b142be6da")!,
    name: "TwoCents",
    dateCreated: HARDCODED_DATE,
    ownerId: UUID(uuidString: "bb444367-e219-41e0-bfe5-ccc2038d0492")!
)

let requiresFetching: [Media] = [.IMAGE, .VIDEO, .LINK]

struct TwoCentsTimelineProvider: TimelineProvider {
    let group: FriendGroup
    
    func placeholder(in context: Context) -> TwoCentsEntry {
        return TwoCentsEntry.dummy
    }

    func getSnapshot(in context: Context, completion: @escaping (TwoCentsEntry) -> ()) {
        completion(TwoCentsEntry.dummy)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TwoCentsEntry>) -> ()) {
        Task {
            do {
                // @TODO: Make a route for fetching only the top post
                let postData = try await PostManager.getTopPost(groupId: HARDCODED_GROUP.id)
                let fetchedPost = try TwoCentsDecoder().decode(PostWithMedia.self, from: postData)
                
                let download = fetchedPost.download
                let fetchedMedia = await fetchMedia(download: download, media: fetchedPost.post.media)
                let entry = TwoCentsEntry(date: Date(), post: fetchedPost.post, fetchedMedia: fetchedMedia)
                let entries = [entry]
                let nextUpdate = Calendar.current.date(byAdding: .second, value: 60, to: Date())!
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                print("Error fetching data")
            }
        }
    }
}

struct TwoCentsEntry: TimelineEntry {
    let date: Date
    let post: Post
    let fetchedMedia: [FetchableMedia]
    
    init(date: Date, post: Post, fetchedMedia: [FetchableMedia]) {
        self.date = date
        self.post = post
        self.fetchedMedia = fetchedMedia
    }
}

struct TwoCentsWidgetEntryView: View {
    let entry: TwoCentsEntry

    var body: some View {
        VStack {
            switch entry.post.media {
            case .IMAGE:
                ImageWidgetView(entry: entry)
            case .VIDEO:
                VideoWidgetView(entry: entry)
            case .LINK:
                LinkWidgetView(entry: entry)
            case .TEXT:
                TextWidgetView(entry: entry)
            case .OTHER:
                DefaultWidgetView(entry: entry)
            }
            // Don't modify the padding below; it's needed for the caption.
        }
        .containerBackground(for: .widget) {
            Color(.white)
        }
    }
}

extension TwoCentsEntry {
    static var dummy: TwoCentsEntry {
        // Use media type .OTHER so the default view is shown in placeholders.
        let dummyPost = Post(
            id: UUID(),
            userId: UUID(),
            media: .OTHER,
            dateCreated: Date(),
            caption: "Placeholder"
        )
        return TwoCentsEntry(
            date: Date(),
            post: dummyPost,
            fetchedMedia: []
        )
    }
}

// Updated Default View: Display a placeholder image with "hihihi"
struct DefaultWidgetView: View {
    let entry: TwoCentsEntry
    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background placeholder image. Ensure "placeholder" is added in your assets.
                Image("placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Overlay text ("hihihi") styled similarly to your ImageWidgetView.
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("That is bonkers!")
                            .font(.caption)
                            .foregroundColor(.white)
                            .lineLimit(widgetFamily == .systemLarge ? 2 : 1)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Group {
                                    if widgetFamily == .systemLarge {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                    .fill(Color.black.opacity(0.3))
                                            )
                                    } else {
                                        Capsule()
                                            .fill(.ultraThinMaterial)
                                            .overlay(
                                                Capsule()
                                                    .fill(Color.black.opacity(0.3))
                                            )
                                    }
                                }
                            )
                        Spacer()
                    }
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.clear, for: .widget)
    }
}

struct TwoCentsWidget: Widget {
    let kind: String = "TwoCentsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TwoCentsTimelineProvider(group: HARDCODED_GROUP)) { entry in
            TwoCentsWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .configurationDisplayName("Top Post")
        .description("Your friend group’s daily highlight, front and center.")


    }
}
