import SwiftUI
import TwoCentsInternal

struct ProfileView: View {
    // Hard-coded profile data
    @Environment(AppModel.self) var appModel

    // Two-column grid layout
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
    ]

    var body: some View {
        NavigationStack {
            if let user = appModel.currentUser {
                VStack {
                    // Profile Header
                    HStack(spacing: 16) {
                        // Profile Image
                        NavigationLink {
                            ProfilePictureUploadView()
                        } label: {
                            if let url = URL(string: user.profilePic ?? "") {
                                CachedImage(url: url) {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 128, height: 128)
                                }
                                .clipShape(Circle())
                                .frame(width: 128, height: 128)
                            } else {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 128, height: 128)
                            }
                        }

                        // Profile Name
                        Text(user.name ?? user.username)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accentColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .truncationMode(.tail)
                    }
                    //            .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(2, contentMode: .fit)
                    .background(.thickMaterial)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // Profile Details Grid
                    LazyVGrid(columns: columns, spacing: nil) {
                        // Adventure Days Card
                        // Inside your LazyVGrid or similar view code
                        if let dateCreated = user.dateCreated {
                            // Calculate the difference in days between now and the account's creation date.
                            let daysSinceCreation = Calendar.current.dateComponents([.day], from: dateCreated, to: Date()).day ?? 0

                            VStack {
                                Text("\(daysSinceCreation) days")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                Text("on TwoCents")
                                    .font(.headline)
                                    .fontWeight(.regular)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(.thickMaterial)
                            .cornerRadius(20)
                        }


                        // Friends Count Card
                        if let posts = user.posts {
                            VStack {
                                Text("\(posts)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.accentColor)
                                Text(posts == 1 ? "Post" : "Posts")
                                    .font(.headline)
                                    .fontWeight(.regular)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                            .background(.thickMaterial)
                            .cornerRadius(20)
                        }

                        // Friend Requests Card
                        /*
                        VStack {
                            if friendRequestsCount == 0 {
                                Label(
                                    "No Requests",
                                    systemImage: "person.crop.rectangle.stack"
                                )
                                .font(.headline)
                                .fontWeight(.regular)
                                .foregroundStyle(.secondary)
                            } else {
                                Label(
                                    "\(friendRequestsCount) Request\(friendRequestsCount == 1 ? "" : "s")",
                                    systemImage: "person.crop.rectangle.stack"
                                )
                                .font(.headline)
                                .fontWeight(.regular)
                                .foregroundColor(Color.accentColor)
                            }
                        }
                        .onAppear {
                            print(user.userId)
                            print(user.profilePic)
                            print(user.username)
                            print(user.dateCreated)
                            print(user.posts)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        .background(.thickMaterial)
                        .cornerRadius(20)
                         */
                        // Placeholder Card for Additional Actions
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.thickMaterial)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.thickMaterial)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                    }
                    .padding(.horizontal)

                    Spacer()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink {
                            SignOutView()
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
                .navigationTitle("Profile 🤠")
            }
        }

    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ProfileView()
        }
    }
}
