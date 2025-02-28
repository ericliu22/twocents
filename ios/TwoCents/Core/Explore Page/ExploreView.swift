import SwiftUI

struct ExploreView: View {
    @State private var items: [ExploreItem] = ExploreItem.sampleData
    @State private var isLoading = false
    
    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        ExploreCard(item: item)
                            .onAppear {
                                if item == items.last {
                                    loadMoreContent()
                                }
                            }
                    }
                }
                .padding()
                
                if isLoading {
                    ProgressView()
                        .padding(.bottom, 20)
                }
            }
            .navigationTitle("Explore")
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AsyncImage(url: URL(string: item.imageUrl)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 200) // **3:4 Aspect Ratio**
                    .clipped()
                    .cornerRadius(12)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 150, height: 200)
                    .cornerRadius(12)
            }
            
            HStack {
                AsyncImage(url: URL(string: item.profileImageUrl)) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 24, height: 24)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 24, height: 24)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.caption)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        Label("\(item.likes)", systemImage: "heart.fill")
                            .foregroundColor(.red)
                        Label("\(item.comments)", systemImage: "bubble.right.fill")
                            .foregroundColor(.gray)
                    }
                    .font(.caption)
                }
            }
        }
        .frame(width: 150)
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
        ExploreItem(imageUrl: "https://source.unsplash.com/random/300x400/?nature",
                    profileImageUrl: "https://source.unsplash.com/random/100x100/?face",
                    caption: "A beautiful sunset in the mountains.",
                    likes: 120, comments: 45),
        ExploreItem(imageUrl: "https://source.unsplash.com/random/300x400/?city",
                    profileImageUrl: "https://source.unsplash.com/random/100x100/?profile",
                    caption: "Exploring the city streets at night.",
                    likes: 89, comments: 30),
        ExploreItem(imageUrl: "https://source.unsplash.com/random/300x400/?food",
                    profileImageUrl: "https://source.unsplash.com/random/100x100/?person",
                    caption: "Delicious homemade ramen with extra toppings.",
                    likes: 200, comments: 60),
    ]
    
    static func generateMoreData() -> [ExploreItem] {
        return [
            ExploreItem(imageUrl: "https://source.unsplash.com/random/300x400/?technology",
                        profileImageUrl: "https://source.unsplash.com/random/100x100/?avatar",
                        caption: "New AI advancements shaping the future.",
                        likes: 340, comments: 80),
            ExploreItem(imageUrl: "https://source.unsplash.com/random",
                        profileImageUrl: "https://source.unsplash.com/random/100x100/?human",
                        caption: "Latest fashion trends this season.",
                        likes: 175, comments: 45),
        ]
    }
}
