import SwiftUI
import TwoCentsInternal

struct ImageWidgetView: View {
    let entry: TwoCentsEntry
    let isDetail: Bool
    private var images: [IdentifiableImage] = []

    @Environment(\.widgetFamily) var widgetFamily

    init(entry: TwoCentsEntry, isDetail: Bool = false) {
        self.isDetail = isDetail
        self.entry = entry
        let uiImages = entry.fetchedMedia as? [UIImage] ?? []
        let targetSize = CGSize(width: 300, height: 300)
        self.images = uiImages.map { IdentifiableImage(image: $0.resized(to: targetSize)) }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background image
                if let image = images.first?.image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                }

                // Caption
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
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
}

// MARK: - Identifiable Image Wrapper
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
