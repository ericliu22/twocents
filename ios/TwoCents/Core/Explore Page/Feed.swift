import SwiftUI

struct FeedItemView: View {
    var body: some View {
        TabView {
            Color.green
                .ignoresSafeArea()
            Color.orange
                .ignoresSafeArea()
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))  // horizontal swipe between green/orange :contentReference[oaicite:0]{index=0}
    }
}

struct FeedView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Repeat as many “posts” as you like:
                ForEach(0..<5) { _ in
                    FeedItemView()
                        .frame(height: UIScreen.main.bounds.height)
                }
            }
            .scrollTargetLayout()          // mark each child of the stack as a snap target :contentReference[oaicite:1]{index=1}
        }
        .scrollTargetBehavior(.paging)    // snap vertically page‑by‑page :contentReference[oaicite:2]{index=2}
        .ignoresSafeArea()
    }
}
