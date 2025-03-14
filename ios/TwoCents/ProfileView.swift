import SwiftUI

struct ProfileView: View {
    // Hard-coded profile data
    let profileImageUrl: URL? = URL(string: "https://example.com/profile.jpg")
    let profileName: String = "John Doe"

    let adventureDays: Int = 100
    let friendCount: Int = 50
    let friendRequestsCount: Int = 2

    // Two-column grid layout
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack{
            VStack {
                // Profile Header
                HStack(spacing: 16) {
                    // Profile Image
                    if let url = profileImageUrl {
                        AsyncImage(url: url) { image in
                            image.resizable()
                                .scaledToFill()
                        } placeholder: {
                            Circle()
                                .fill(Color.accentColor)
                        }
                        .clipShape(Circle())
                        .frame(width: 128, height: 128)
                    } else {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 128, height: 128)
                    }
                    
                    // Profile Name
                    Text(profileName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
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
                    VStack {
                        Text("\(adventureDays) days")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                        Text("of adventure")
                            .font(.headline)
                            .fontWeight(.regular)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .background(.thickMaterial)
                    .cornerRadius(20)
                    
                    // Friends Count Card
                    VStack {
                        Text("\(friendCount)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(Color.accentColor)
                        Text(friendCount == 1 ? "Friend" : "Friends")
                            .font(.headline)
                            .fontWeight(.regular)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .background(.thickMaterial)
                    .cornerRadius(20)
                    
                    // Friend Requests Card
                    VStack {
                        if friendRequestsCount == 0 {
                            Label("No Requests", systemImage: "person.crop.rectangle.stack")
                                .font(.headline)
                                .fontWeight(.regular)
                                .foregroundStyle(.secondary)
                        } else {
                            Label("\(friendRequestsCount) Request\(friendRequestsCount == 1 ? "" : "s")",
                                  systemImage: "person.crop.rectangle.stack")
                            .font(.headline)
                            .fontWeight(.regular)
                            .foregroundColor(Color.accentColor)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .background(.thickMaterial)
                    .cornerRadius(20)
                    
                    // Placeholder Card for Additional Actions
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.thickMaterial)
                        Image(systemName: "plus")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Profile 🤠")
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
