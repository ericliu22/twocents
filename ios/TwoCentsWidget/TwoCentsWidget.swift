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

let requiresFetching: [Media] = [.IMAGE, .VIDEO, .LINK]

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
        Task{
            do {
                //@TODO: Make a route for fetching only the top post
                let postData = try await PostManager.getTopPost(groupId: HARDCODED_GROUP.id) //Hardcoded also don't work
                let fetchedPost = try TwoCentsDecoder().decode(PostWithMedia.self, from: postData)
                
                var fetchedMedia: [FetchableMedia]
                let download = fetchedPost.download
                let entry: TwoCentsEntry
                fetchedMedia = await fetchMedia(download: download, media: fetchedPost.post.media)
                entry = TwoCentsEntry.init(date: Date(), post: fetchedPost.post, fetchedMedia: fetchedMedia)
                let entries = [entry]
                let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
                completion(timeline)
            } catch {
                print("Error fetching data")
            }
        }
        }
}

//IDK?????
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


//wtf going on with the UI
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
            //Don't touch this padding, otherwise caption breaks widget
        }
            .containerBackground(for: .widget) {
                Color(.white)
            }
    }
}

extension TwoCentsEntry {
    static var dummy: TwoCentsEntry {
        // Create a dummy post for the sake of the dummy entry.
        let dummyPost = Post(
            id: UUID(),
            userId: UUID(),
            media: .TEXT, // Use any Media type that fits
            dateCreated: Date(),
            caption: "Placeholder"
        )
        
        // Build the dummy entry.
        return TwoCentsEntry(
            date: Date(),
            post: dummyPost,
            fetchedMedia: ["This is widget shows the top post of the day"]
        )
    }
}

// Example subviews for different media types

struct DefaultWidgetView: View {
    let entry: TwoCentsEntry
    @State var posts: [Post] = []
    @State var users: IdentifiedCollection<User> = IdentifiedCollection()
    

    var body: some View {
        ZStack(alignment: .bottom) {
                Text("No post")
                .font(.largeTitle)
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
