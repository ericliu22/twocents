import SwiftUI
import TwoCentsInternal
import Kingfisher

struct ExploreView: View {
    let group: FriendGroup
    @State private var postsWithMedia: [PostWithMedia] = []
    @State private var users: IdentifiedCollection<User> = IdentifiedCollection()
    @State private var isLoading = false
    @State private var selectedPost: PostWithMedia? = nil    // For full screen detail
    @State private var offset: UUID?
    @State private var hasMore = true
    
    let columns = [
        GridItem(.flexible(minimum: 150, maximum: .infinity), spacing: 5),
        GridItem(.flexible(minimum: 150, maximum: .infinity), spacing: 5)
    ]
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(postsWithMedia, id: \.post.id) {     post in
                        
                        if let user = users[id: post.post.userId] {
                            ExploreCard(post: post, user: user, selectedPost: $selectedPost)
                                .onAppear {
                                    // If we're nearing the end of the current posts, load more
                                    if let lastPostId = postsWithMedia.last?.post.id,
                                       post.post.id == lastPostId,
                                       hasMore && !isLoading {
                                        loadMoreContent()
                                    }
                                }
                            
                        }
                        
                    }
                    .padding(.bottom, 5)
                }
                .padding(.horizontal, 5)
                
                
                
                if isLoading {
                    ProgressView()
                        .padding(.bottom, 20)
                        .frame(maxWidth: .infinity)
                }
            }
            //            .navigationTitle("Explore")
            //            .navigationBarTitleDisplayMode(.large)
        }
        .refreshable {
            // Reset pagination and fetch first page
            print("RAN REFRESH")
            offset = nil
            do {
                try await fetchInitialPosts()
            } catch {
                print("Error refreshing posts: \(error)")
            }
        }
        .task {
            do {
                try await fetchInitialPosts()
            } catch {
                print("Error fetching initial posts: \(error)")
            }
        }
        .fullScreenCover(item: $selectedPost) { post in
            if let user = users[id: post.post.userId] {
                
                ExploreDetailView(post: post, user: user) {
                    withAnimation(.spring()) {
                        selectedPost = nil
                    }
                    
                }
                
                
                
            }
        }
        
        
    }
    
    private func fetchInitialPosts() async throws {
        // Fetch users first to display them properly with posts
        let members = try await GroupManager.fetchGroupMembers(groupId: group.id)
        users = IdentifiedCollection(members)
        
        // Then fetch the first page of posts
        let postsData = try await PostManager.getGroupPosts(groupId: group.id)
        let response = try TwoCentsDecoder().decode(PaginatedPostsResponse.self, from: postsData)
        
        postsWithMedia = response.posts
        print(postsWithMedia.first)
        offset = response.offset
        hasMore = response.hasMore
    }

       
    private func loadMoreContent() {
        guard !isLoading && hasMore, let cursor = offset else { return }
        
        isLoading = true
        
        Task {
            do {
                let postsData = try await PostManager.getGroupPosts(groupId: group.id, offset: cursor)
                let response = try TwoCentsDecoder().decode(PaginatedPostsResponse.self, from: postsData)
                
                // Update state on the main thread
                await MainActor.run {
                    postsWithMedia.append(contentsOf: response.posts)
                    offset = response.offset
                    hasMore = response.hasMore
                    isLoading = false
                }
            } catch {
                print("Error loading more posts: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

struct ExploreCard: View {
    let post: PostWithMedia
    let user: User
    @Binding var selectedPost: PostWithMedia?
                        // Use the factory to generate the appropriate view for each post.
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            
            ZStack(alignment: .bottom) {
                // Post content (image or view)
                makePostView(post: post)
                    .aspectRatio(3/4, contentMode: .fill)
                    .frame(maxWidth: (UIScreen.main.bounds.width - 15) / 2)
                    .clipped()
                    .cornerRadius(12)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            selectedPost = post
                        }
                    }

                // Blurred background behind caption
                
                

                // Caption text
                if let caption = post.post.caption, !caption.isEmpty {
                  
                        
                        
                        
                    ZStack{
                        
                        makePostView(post: post)
                            .aspectRatio(3/4, contentMode: .fill)
                            .frame(maxWidth: (UIScreen.main.bounds.width - 15) / 2)
                            .overlay(
                                    Color.black.opacity(0.2) // Adjust opacity to control darkness
                                )
                            .mask(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: .black.opacity(1), location: 0),
                                        .init(color: .black.opacity(1), location: 0.2),
                                        .init(color: .clear, location: 0.3)
                                    ]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                          
                            .compositingGroup() // ← flatten it first
                            .blur(radius: 1.5) // ← then blur the entire result
                            .clipShape(
                                RoundedCorner(radius: 12, corners: [.bottomLeft, .bottomRight])
                            )
                          
                            
                        
                        Text(caption)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                          
                            
                        
                    }
                    
                }
            }

            
            
            
            VStack(alignment: .leading, spacing: 5) {

                    
                
                HStack (spacing: 0){
                    if let url = URL(string: user.profilePic ?? "") {
                        KFImage(url)
                            .resizable()
                            .clipped()
                            .scaledToFill()
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 24, height: 24)
                        
                    }
                    
                    Text(user.name ?? user.username)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.leading, 8)
                        .foregroundColor(Color(UIColor.systemGray))
                    
                    Spacer()
                   
//                    Label("\(100)", systemImage: "heart.fill")
//                        .font(.caption)
//                        .foregroundColor(.red)
                        
                    
                    
                }
            }
            .padding(.horizontal, 5)
        }
     
        .ignoresSafeArea()

        
    }
}

struct ExploreDetailView: View {
    let post: PostWithMedia
    let user: User
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
                    
                   Spacer()
                        .frame(height:48)
                    
                    // Header with profile image and username.
                    HStack {
                        // For demo purposes, a placeholder URL is used.
                        if let url = URL(string: user.profilePic ?? "") {
                            KFImage(url)
                                .resizable()
                                .clipped()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        Text(user.name ?? user.username)
                            .font(.title3)
                    }
                    .padding()
                    
                    // Show the post’s content using your media-aware factory.
                    // In ExploreDetailView's body:
                    makePostView(post: post, isDetail: true)

                    // Optionally show the caption, if any.
                    if let caption = post.post.caption {
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
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                            
                    }
                }

            }
        }
        .ignoresSafeArea()
        .presentationBackground(.clear)
        
    }
}


struct RoundedCorner: Shape {
    var radius: CGFloat = 0
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
