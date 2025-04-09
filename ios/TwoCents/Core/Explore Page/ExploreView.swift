import Kingfisher
import SwiftUI
import TwoCentsInternal

struct ExploreView: View {
    let group: FriendGroup
    @State private var postsWithMedia: [PostWithMedia] = []
    @State private var users: IdentifiedCollection<User> =
        IdentifiedCollection()
    @State private var isLoading = false
    @State private var selectedPost: PostWithMedia? = nil  // For full screen detail
    @State private var offset: UUID?
    @State private var hasMore = true
    @Environment(AppModel.self) var appModel
    @State private var postsGroupedByDate: [(date: Date, posts: [PostWithMedia])] = []

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // Customize as needed (e.g. "MMM d, yyyy")
        return formatter
    }

    //added this for deeplinking

    let columns = [
        GridItem(.flexible(minimum: 150, maximum: .infinity), spacing: 5),
        GridItem(.flexible(minimum: 150, maximum: .infinity), spacing: 5),
    ]

    var body: some View {
        //added for deeplinking
        @Bindable var appModel = appModel
        NavigationView {
            ZStack {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(postsGroupedByDate, id: \.date) { group in
                            // Date separator header.
                            if group != postsGroupedByDate.first! {
                                HStack {
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(
                                            Color(UIColor.systemGray)
                                        )
                                        .padding(.horizontal, 2)
                                    Text(dateFormatter.string(from: group.date))
                                        .font(.caption)
                                        .foregroundColor(
                                            Color(UIColor.systemGray)
                                        )
                                        .padding(.horizontal, 4)
                                        .frame(maxWidth: .infinity)
                                        .background(.clear)
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(
                                            Color(UIColor.systemGray)
                                        )
                                        .padding(.horizontal, 2)
                                }
                                .padding(.vertical, 8)
                            }

                            // Day's posts in a grid.
                            LazyVGrid(columns: columns, spacing: 5) {
                                // To handle the potential single post on the last row,
                                // iterate over the indices.
                                ForEach(group.posts.indices, id: \.self) {
                                    index in
                                    let post = group.posts[index]

                                    // Lookup user for the post.
                                    if let user = users[id: post.post.userId] {
                                        // If this is the last post in a group with an odd count,
                                        // make it span two columns.
                                        if group.posts.count % 2 != 0
                                            && index == group.posts.count - 1
                                        {
                                            ExploreCard(
                                                post: post, user: user,
                                                selectedPost: $selectedPost
                                            )
                                            .gridCellColumns(2)
                                            .onAppear {
                                                if post.post.id
                                                    == postsWithMedia.last?.post
                                                    .id && hasMore && !isLoading
                                                {
                                                    loadMoreContent()
                                                }
                                            }
                                        } else {
                                            ExploreCard(
                                                post: post, user: user,
                                                selectedPost: $selectedPost
                                            )
                                            .onAppear {
                                                if post.post.id
                                                    == postsWithMedia.last?.post
                                                    .id && hasMore && !isLoading
                                                {
                                                    loadMoreContent()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        if isLoading {
                            ProgressView()
                                .padding(.bottom, 20)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 5)
                }
            }
            .refreshable {
                // Reset pagination and fetch first page
                offset = nil
                do {
                    try await fetchInitialPosts()
                } catch {
                    print("Error refreshing posts: \(error)")
                }
            }
            .onChange(of: appModel.currentUser) {
                offset = nil
                Task {
                    do {
                        postsWithMedia = []
                        try await fetchInitialPosts()
                    } catch {
                        print("Error refreshing posts: \(error)")
                    }
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
            .onChange(of: appModel.deepLinkPostID) { newID in
                if let newID = newID {
                    print(
                        "Deep link detected in ExploreView with post ID: \(newID)"
                    )
                    // Look for the matching post in the loaded posts
                    if let matchingPost = postsWithMedia.first(where: {
                        $0.post.id == newID
                    }) {
                        selectedPost = matchingPost  // This will trigger navigation
                    } else {
                        print("Deep link post not found among loaded posts")
                        // Optionally: Fetch the post from the backend here.
                    }
                    // Clear the deep link after handling it.
                    appModel.deepLinkPostID = nil
                }
            }

        }

    }

    //Added this for navigation
    @ViewBuilder
    private func destinationView() -> some View {
        if let post = selectedPost, let user = users[id: post.post.userId] {
            ExploreDetailView(post: post, user: user) {
                withAnimation(.spring()) {
                    selectedPost = nil
                }
            }
        } else {
            EmptyView()
        }
    }
    private func updatePostsGroupedByDate() {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: postsWithMedia) {
            calendar.startOfDay(for: $0.post.dateCreated)
        }
        postsGroupedByDate = groups.map { (date: $0.key, posts: $0.value.sorted { $0.post.dateCreated > $1.post.dateCreated }) }
                                   .sorted { $0.date > $1.date }
    }


    private func fetchInitialPosts() async throws {
        // Fetch users first to display them properly with posts
        let members = try await GroupManager.fetchGroupMembers(
            groupId: group.id)
        users = IdentifiedCollection(members)

        // Then fetch the first page of posts
        let postsData = try await PostManager.getGroupPosts(groupId: group.id)
        let response = try TwoCentsDecoder().decode(
            PaginatedPostsResponse.self, from: postsData)

        postsWithMedia = response.posts
        updatePostsGroupedByDate()
        offset = response.offset
        hasMore = response.hasMore
    }

    private func loadMoreContent() {
        guard !isLoading && hasMore, let cursor = offset else { return }

        isLoading = true

        Task {
            do {
                let postsData = try await PostManager.getGroupPosts(
                    groupId: group.id, offset: cursor)
                let response = try TwoCentsDecoder().decode(
                    PaginatedPostsResponse.self, from: postsData)

                // Update state on the main thread
                await MainActor.run {
                    postsWithMedia.append(contentsOf: response.posts)
                    updatePostsGroupedByDate()
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

            ZStack {
                // Main post image
                makePostView(post: post)
                    .aspectRatio(3 / 4, contentMode: .fill)
                    .frame(maxWidth: (UIScreen.main.bounds.width - 15) / 2)
                    .clipped()
                    .cornerRadius(12)

                // Caption overlay
                if let caption = post.post.caption, !caption.isEmpty {
                    VStack {
                        Spacer()

                        // Blurred glass background for caption
                        VisualEffectBlur(
                            blurStyle: .systemUltraThinMaterialDark
                        )
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 12, style: .continuous)
                        )
                        .overlay(
                            Text(caption)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .padding(.horizontal, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        )
                        .padding(6)  // Add padding from image edges
                    }
                    .frame(
                        maxWidth: (UIScreen.main.bounds.width - 15) / 2,
                        maxHeight: .infinity)

                }
            }

            .onTapGesture {
                withAnimation(.spring()) {
                    selectedPost = post
                }
            }

            VStack(alignment: .leading, spacing: 5) {

                HStack(spacing: 0) {
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

                    Text(post.post.dateCreated.timeAgoShort())
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.leading, 8)
                        .foregroundColor(Color(UIColor.systemGray))

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

    // Computed background opacity for fading out
    private var backgroundOpacity: Double {
        return 1 - min(1, Double(dragOffset / 150))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Invisible background to capture gestures
                Color.black.opacity(0.001)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {

                    Spacer()
                        .frame(height: 48)

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
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                        }
                        Text(user.name ?? user.username)
                            .font(.title3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(UIColor.systemBackground))
                    .clipShape(CustomCornerRadius(radius: 20, corners: [.topLeft, .topRight]))


                    // Show the post’s content using your media-aware factory.
                    // In ExploreDetailView's body:
                    makePostView(post: post, isDetail: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(UIColor.systemGray6))

                    // Optionally show the caption, if any.
                    if let caption = post.post.caption {
                        Text(caption)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.systemBackground))
                            .clipShape(RoundedCorner(radius: 20, corners: [.bottomLeft, .bottomRight]))
                    }

                    Spacer()
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .cornerRadius(12)
                .scaleEffect(scale)
                .offset(y: dragOffset)
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
                                withAnimation(
                                    .spring(response: 0.4, dampingFraction: 0.8)
                                ) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
            .background(
                Color(UIColor.systemBackground)
                    .opacity(backgroundOpacity)
            ).ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")

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

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

extension Date {
    func timeAgoShort() -> String {
        let secondsAgo = Int(Date().timeIntervalSince(self))

        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day

        if secondsAgo < 60 {
            return "\(secondsAgo)s"
        } else if secondsAgo < hour {
            return "\(secondsAgo / minute)m"
        } else if secondsAgo < day {
            return "\(secondsAgo / hour)h"
        } else if secondsAgo < week {
            return "\(secondsAgo / day)d"
        } else {
            return "\(secondsAgo / week)w"
        }
    }
}

struct CustomCornerRadius: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        // Create a UIBezierPath with rounded corners.
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        // Convert the UIBezierPath to a SwiftUI Path.
        return Path(path.cgPath)
    }
}
