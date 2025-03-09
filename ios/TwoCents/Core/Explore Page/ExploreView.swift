import SwiftUI

struct ExploreView: View {
    let group: FriendGroup
    @State private var posts: [Post] = []         // Now using backend Post objects
    @State private var isLoading = false
    @State private var selectedPost: Post? = nil    // For full screen detail
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 5)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(posts, id: \.id) {     post in

                        ExploreCard(post: post, selectedPost: $selectedPost)

                    }
                }
                .padding(5)
                
                if isLoading {
                    ProgressView()
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Explore")
        }
        .task {
            do {
                // Fetch posts from the backend
                let postsData = try await PostManager.getGroupPosts(groupId: group.id)
                let fetchedPosts = try TwoCentsDecoder().decode([Post].self, from: postsData)
                posts = fetchedPosts.sorted { $0.dateCreated > $1.dateCreated }
            } catch {
                print("Error fetching posts: \(error)")
            }
        }
        .fullScreenCover(item: $selectedPost) { post in
            ExploreDetailView(post: post) {
                withAnimation(.spring()) {
                    selectedPost = nil
                }
            }
        }
    }
    
    private func loadMoreContent() {
        guard !isLoading else { return }
        isLoading = true
        
        // Simulate load-more delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
        }
    }
}

struct ExploreCard: View {
    let post: Post
    @Binding var selectedPost: Post?
                        // Use the factory to generate the appropriate view for each post.
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            makePostView(post: post)
                .frame(maxWidth: 150, minHeight: 200)
                .aspectRatio(3/4, contentMode: .fill)
                .clipped()
                .cornerRadius(12)
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedPost = post
                    }
                }
            VStack(alignment: .leading, spacing: 4) {
                if let caption = post.caption {
                    Text(caption)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    if let url = URL(string: "https://source.unsplash.com/100x100/?avatar") {
                        CachedImage(url: url)
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                        
                    }
                    
                    HStack(spacing: 8) {
                        Label("\(100)", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Label("\(100)", systemImage: "bubble.right.fill")
                            .foregroundColor(.gray)
                    }
                    .font(.caption)
                }
            }
            .padding(.horizontal, 4)
        }
        
    }
}

struct ExploreDetailView: View {
    let post: Post
    var onDismiss: () -> Void
    
    // For a drag-to-dismiss gesture
    @State private var dragOffset: CGFloat = 0
    
    private var scale: CGFloat {
        let cappedOffset = min(dragOffset, 150)
        return 1 - (cappedOffset / 150 * 0.15)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Invisible background to capture gestures
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header with profile image and username.
                    HStack {
                        // For demo purposes, a placeholder URL is used.
                        if let url = URL(string: "https://source.unsplash.com/100x100/?avatar") {
                            CachedImage(url: url)
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        Text("User \(post.userId.uuidString.prefix(4))")
                            .font(.title3)
                    }
                    .padding()
                    
                    // Show the post’s content using your media-aware factory.
                    makePostView(post: post)
                    
                    // Optionally show the caption, if any.
                    if let caption = post.caption {
                        Text(caption)
                            .font(.headline)
                            .padding()
                    }
                    
                    Spacer()
                }
                .frame(width: UIScreen.main.bounds.width)
                .background(Color.white)
                .cornerRadius(12)
                .scaleEffect(scale)
                .offset(y: dragOffset)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { _ in
                            if dragOffset > 150 {
                                onDismiss()
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}
