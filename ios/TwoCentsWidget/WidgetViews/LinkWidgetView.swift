//
//  LinkWidgetView.swift
//  TwoCents
//
//  Created by Eric Liu on 3/31/25.
//
import SwiftUI
import LinkPresentation

struct LinkWidgetView: View {
    let entry: TwoCentsEntry
    var linkMetadatas: [IdentifiableLink] = []
    
    init(entry: TwoCentsEntry) {
        self.entry = entry
        let links = entry.fetchedMedia as? [TwoCentsLinkMetadata] ?? []
        self.linkMetadatas = links.map { link in
            return IdentifiableLink(linkMetadata: link)
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {

            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(linkMetadatas) { link in
                            Image(uiImage: link.linkMetadata.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width)
                        }
                    }
                }
                .scrollTargetBehavior(.paging)  // Enable paging
            }
        
            if let caption = entry.post.caption {
                    
                VStack {
                    Text(caption)
                }
                .frame(height: 50)                // <--- Adjust as needed
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)   // blur effect         // space from the bottom edge
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Ensures the ZStack itself spans the widget
        .containerBackground(.clear, for: .widget)
    }
}

struct IdentifiableLink: Identifiable {
    let id = UUID()
    let linkMetadata: TwoCentsLinkMetadata
}
