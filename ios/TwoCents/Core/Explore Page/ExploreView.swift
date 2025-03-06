import SwiftUI

struct ExploreView: View {
    @State private var items: [ExploreItem] = ExploreItem.sampleData
    @State private var isLoading = false
    @State private var selectedItem: ExploreItem? = nil
    @Namespace private var namespace
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 5)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(items) { item in
                        ExploreCard(item: item, namespace: namespace)
                            .onTapGesture {
                                // Animate to detail view when tapped
                                withAnimation(.spring()) {
                                    selectedItem = item
                                }
                            }
                            .onAppear {
                                if item == items.last {
                                    loadMoreContent()
                                }
                            }
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
        // Present full-screen detail view when an item is selected
        .fullScreenCover(item: $selectedItem) { item in
            ExploreDetailView(item: item, namespace: namespace, onDismiss: {
                withAnimation(.spring()) {
                    selectedItem = nil
                }
            })
        }
    }
    
    private func loadMoreContent() {
        guard !isLoading else { return }
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            items.append(contentsOf: ExploreItem.generateMoreData())
            isLoading = false
        }
    }
}

struct ExploreCard: View {
    let item: ExploreItem
    let namespace: Namespace.ID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            AsyncImage(url: URL(string: item.imageUrl)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, minHeight: 200)
                        .aspectRatio(3/4, contentMode: .fill)
                        .clipped()
                        .cornerRadius(12)
                        .matchedGeometryEffect(id: "image-\(item.id)", in: namespace)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(3/4, contentMode: .fill)
                        .cornerRadius(12)
                        .matchedGeometryEffect(id: "image-\(item.id)", in: namespace)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.caption)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack {
                    AsyncImage(url: URL(string: item.profileImageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .matchedGeometryEffect(id: "profile-\(item.id)", in: namespace)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .matchedGeometryEffect(id: "profile-\(item.id)", in: namespace)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Label("\(item.likes)", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Label("\(item.comments)", systemImage: "bubble.right.fill")
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
    let item: ExploreItem
    let namespace: Namespace.ID
    var onDismiss: () -> Void
    
    // Track vertical drag offset
    @State private var dragOffset: CGFloat = 0
    
    // Compute a scale factor that reduces as the user drags down.
    private var scale: CGFloat {
        let cappedOffset = min(dragOffset, 150)
        return 1 - (cappedOffset / 150 * 0.15)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background to capture gestures
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    // Header with profile image and name
                    HStack {
                        AsyncImage(url: URL(string: item.profileImageUrl)) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                                    .matchedGeometryEffect(id: "profile-\(item.id)", in: namespace)
                            } else {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                    .matchedGeometryEffect(id: "profile-\(item.id)", in: namespace)
                            }
                        }
                        
                        Text("Firstname Lastname")
                            .font(.title3)
                    }
                    .padding()
                    
                    // Main image
                    AsyncImage(url: URL(string: item.imageUrl)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFit()
                                .matchedGeometryEffect(id: "image-\(item.id)", in: namespace)
                        } else {
                            Rectangle()
                                .fill(Color.yellow.gradient.opacity(0.3))
                                .matchedGeometryEffect(id: "image-\(item.id)", in: namespace)
                        }
                    }
                    .aspectRatio(3/4, contentMode: .fill)
                    
                    // Likes, comments, and caption
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Likes: \(item.likes)")
                        Text("Comments: \(item.comments)")
                        Text(item.caption)
                            .font(.headline)
                            .fontWeight(.regular)
                    }
                    .padding()
                    
                    Spacer()
                }
                // Use UIScreen.main.bounds.width for the default width
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

struct ExploreItem: Identifiable, Equatable {
    let id = UUID()
    let imageUrl: String
    let profileImageUrl: String
    let caption: String
    let likes: Int
    let comments: Int
    
    static let sampleData: [ExploreItem] = [
        ExploreItem(imageUrl: "https://source.unsplash.com/600x800/?nature",
                    profileImageUrl: "https://source.unsplash.com/100x100/?face",
                    caption: "A beautiful sunset in the mountains.",
                    likes: 120, comments: 45),
        ExploreItem(imageUrl: "https://source.unsplash.com/600x800/?city",
                    profileImageUrl: "https://source.unsplash.com/100x100/?profile",
                    caption: "Exploring the city streets at night.",
                    likes: 89, comments: 30),
        ExploreItem(imageUrl: "https://source.unsplash.com/600x800/?food",
                    profileImageUrl: "https://source.unsplash.com/100x100/?person",
                    caption: "Delicious homemade ramen with extra toppings.",
                    likes: 200, comments: 60),
    ]
    
    static func generateMoreData() -> [ExploreItem] {
        return [
            ExploreItem(imageUrl: "https://source.unsplash.com/600x800/?technology",
                        profileImageUrl: "https://source.unsplash.com/100x100/?avatar",
                        caption: "New AI advancements shaping the future.",
                        likes: 340, comments: 80),
            ExploreItem(imageUrl: "https://source.unsplash.com/600x800/?fashion",
                        profileImageUrl: "https://source.unsplash.com/100x100/?human",
                        caption: "Latest fashion trends this season.",
                        likes: 175, comments: 45),
        ]
    }
}

struct ExploreView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
