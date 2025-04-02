import SwiftUI
import TwoCentsInternal

struct ExploreView: View {
    let group: FriendGroup
    @State private var posts: [Post] = []         // Now using backend Post objects
    @State private var users: IdentifiedCollection<User> = IdentifiedCollection()
    @State private var isLoading = false
    @State private var selectedPost: Post? = nil    // For full screen detail
    
    let columns = [
        GridItem(.flexible(minimum: 150, maximum: .infinity), spacing: 5),
        GridItem(.flexible(minimum: 150, maximum: .infinity), spacing: 5)
    ]

    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(posts, id: \.id) {     post in

                        if let user = users[id: post.userId] {
                            ExploreCard(post: post, user: user, selectedPost: $selectedPost)
                             
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
        .refreshable(action: {
            do {
                // Fetch posts from the backend
                let postsData = try await PostManager.getGroupPosts(groupId: group.id)
                let fetchedPosts = try TwoCentsDecoder().decode([Post].self, from: postsData)
                posts = fetchedPosts.sorted { $0.dateCreated > $1.dateCreated }
                let members = try await GroupManager.fetchGroupMembers(groupId: group.id)
                users = IdentifiedCollection(members)
            } catch {
                print("Error fetching posts: \(error)")
            }
        })
        .task {
            do {
                // Fetch posts from the backend
                let postsData = try await PostManager.getGroupPosts(groupId: group.id)
                let fetchedPosts = try TwoCentsDecoder().decode([Post].self, from: postsData)
                posts = fetchedPosts.sorted { $0.dateCreated > $1.dateCreated }
                let members = try await GroupManager.fetchGroupMembers(groupId: group.id)
                users = IdentifiedCollection(members)
            } catch {
                print("Error fetching posts: \(error)")
            }
        }
        .fullScreenCover(item: $selectedPost) { post in
            if let user = users[id: post.userId] {
                
                ExploreDetailView(post: post, user: user) {
                    withAnimation(.spring()) {
                        selectedPost = nil
                    }
                    
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
    let user: User
    @Binding var selectedPost: Post?
                        // Use the factory to generate the appropriate view for each post.
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            makePostView(post: post)
                .aspectRatio(3/4, contentMode: .fill)
                .frame( maxWidth: (UIScreen.main.bounds.width - 15 ) / 2 )
                .clipped()
                .cornerRadius(12)
                .onTapGesture {
                    withAnimation(.spring()) {
                        selectedPost = post
                    }
                }

            VStack(alignment: .leading, spacing: 5) {
                if let caption = post.caption {
                    Text(caption)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                }
                
                HStack (spacing: 0){
                    if let url = URL(string: user.profilePic ?? "") {
                        CachedImage(url: url)
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
    let post: Post
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
                            CachedImage(url: url)
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
