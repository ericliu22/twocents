import SwiftUI

struct ExploreView: View {
    @State private var items: [ExploreItem] = ExploreItem.sampleData
    @State private var isLoading = false

    let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 5)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 5) {
                    ForEach(items) { item in
                        ExploreCard(item: item)
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
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(3/4, contentMode: .fill)
                        .cornerRadius(12)
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
                            image.resizable()
                                .scaledToFill()
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
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

// MARK: - ExploreItem Model
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
