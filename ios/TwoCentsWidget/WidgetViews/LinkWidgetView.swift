import SwiftUI
import LinkPresentation


struct LinkWidgetView: View {
    let entry: TwoCentsEntry
    var linkMetadatas: [IdentifiableLink] = []

    @Environment(\.widgetFamily) var widgetFamily

    init(entry: TwoCentsEntry) {
        self.entry = entry
        let links = entry.fetchedMedia as? [TwoCentsLinkMetadata] ?? []
        self.linkMetadatas = links.map { link in
            IdentifiableLink(linkMetadata: link)
        }

    }

    var body: some View {
        ZStack {
            // Link image as background
            if let image = linkMetadatas.first?.linkMetadata.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            }

            // Caption (if not small)
            if let caption = entry.post.caption, !caption.isEmpty, widgetFamily != .systemSmall {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(caption)
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.clear, for: .widget)
    }
}

struct IdentifiableLink: Identifiable {
    let id = UUID()
    let linkMetadata: TwoCentsLinkMetadata
}


