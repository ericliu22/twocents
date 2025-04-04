//
//  ImageWidgetView.swift
//  TwoCents
//
//  Created by Eric Liu on 3/31/25.
//
import SwiftUI
import TwoCentsInternal

struct ImageWidgetView: View {
    let entry: TwoCentsEntry
    let isDetail: Bool
    private var images: [IdentifiableImage] = []

    init(entry: TwoCentsEntry, isDetail: Bool = false) {
        self.isDetail = isDetail
        self.entry = entry
        let uiImages = entry.fetchedMedia as? [UIImage] ?? []
        
        // Define a target size that fits within the allowed area, e.g., 1024x768
        let targetSize = CGSize(width: 300, height: 300)
        
        self.images = uiImages.map { uiImage in
            let resizedImage = uiImage.resized(to: targetSize)
            return IdentifiableImage(image: resizedImage)
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geometry in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(images) { image in
                            Image(uiImage: image.image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width)
                        }
                    }
                }
                .scrollTargetBehavior(.paging)  // Enable paging
            }

            // Caption overlay remains unchanged
            if let caption = entry.post.caption {
                VStack {
                    Text(caption)
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

// MARK: - Identifiable Image Wrapper
struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
