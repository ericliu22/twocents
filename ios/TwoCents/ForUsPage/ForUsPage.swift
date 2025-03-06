import SwiftUI

struct ForUsPage: View {
    @State private var posts: [Post] = [
        Post(id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "First post"),
        Post(id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "Second post")
    ]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(posts, id: \.id) { post in
                    ForUsPostView(post: post)
                        .onAppear {
                            if post.id == posts.last?.id {
                                loadMorePosts()
                            }
                        }
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .scrollTargetBehavior(.paging)
    }
    
    func loadMorePosts() {
        guard posts.count < 10 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let newPosts = [
                Post(id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "Another post"),
                Post(id: UUID(), userId: UUID(), media: .IMAGE, dateCreated: Date(), caption: "Yet another post")
            ]
            posts.append(contentsOf: newPosts)
        }
    }
}

struct ForUsPostView: View {
    let post: Post
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Full-screen media view (gray placeholder)
            //Use makePostView(post: Post, postMedia: any Downloadable)
            Rectangle()
                .fill(Color.blue.gradient)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            // Overlay for user profile and interactions.
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                    
                    Text("User \(post.userId.uuidString.prefix(4))")
                        .font(.headline)
                }
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "heart")
                    }
                    Button(action: {}) {
                        Image(systemName: "bubble.right")
                    }
                    Button(action: {}) {
                        Image(systemName: "paperplane")
                    }
                }
                .font(.subheadline)
            }
            .padding()
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}

struct ForUsPage_Previews: PreviewProvider {
    static var previews: some View {
        ForUsPage()
    }
}
