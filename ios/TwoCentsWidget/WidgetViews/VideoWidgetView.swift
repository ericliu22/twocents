import SwiftUI
import TwoCentsInternal
import AVKit

struct VideoWidgetView: View {

    let entry: TwoCentsEntry
    private var images: [IdentifiableImage] = []

    @Environment(\.widgetFamily) var widgetFamily

    init(entry: TwoCentsEntry) {
        self.entry = entry
        
        let uiImages = entry.fetchedMedia as? [UIImage] ?? []
        let targetSize = CGSize(width: 300, height: 300)
        self.images = uiImages.map { uiImage in
            let resizedImage = uiImage.resized(to: targetSize)
            return IdentifiableImage(image: resizedImage)
        }
    }

    var body: some View {
        ZStack {
            // Video preview image
            if let image = images.first?.image {
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
    }
}
