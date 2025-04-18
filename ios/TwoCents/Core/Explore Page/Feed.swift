import SwiftUI
import AVKit

struct VideoPost {
    let id = UUID()
    let username: String
    let profileImage: String // System name for SF Symbol
    let videoURL: URL
}

class VideoPlayerManager: ObservableObject {
    @Published var progress: Double = 0
    var player: AVPlayer?
    private var timeObserver: Any?
    
    func setupPlayer(url: URL) {
        player = AVPlayer(url: url)
        
        // Add time observer to update progress
        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            guard let self = self,
                  let duration = self.player?.currentItem?.duration.seconds,
                  !duration.isNaN, duration > 0 else { return }
            
            self.progress = time.seconds / duration
        }
        
        // Add observer for when video ends
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    @objc func playerDidFinishPlaying() {
        progress = 1.0
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

struct FeedItemView: View {
    let post: VideoPost
    @StateObject private var playerManager = VideoPlayerManager()
    @State private var isVideoFinished = false
    @State private var isPaused = false
    
    var body: some View {
        ZStack {
            // Video Player
            ZStack {
                if let player = playerManager.player {
                    VideoPlayer(player: player)
                        .disabled(true) // Disable default video controls
                        .overlay(
                            ZStack {
                                // Red overlay that fades in when video ends
                                Color.red
                                    .opacity(isVideoFinished ? 0.3 : 0)
                                    .animation(.easeInOut(duration: 1.0), value: isVideoFinished)
                                
                                // Pause indicator
                                if isPaused {
                                    Image(systemName: "play.circle.fill")
                                        .resizable()
                                        .frame(width: 80, height: 80)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        )
                } else {
                    Color.black
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        )
                }
            }
            
            // UI Elements
            VStack {
                Spacer()
                
                // User info and controls
                HStack(alignment: .bottom) {
                    // Left side - User info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            Image(systemName: post.profileImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(post.username)
                                    .font(.system(size: 16, weight: .semibold))
                                
                                Text("2h ago")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Text("Check out this amazing video!")
                            .font(.system(size: 14))
                            .padding(.top, 2)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Right side - Interaction buttons
                    VStack(spacing: 20) {
                        Button(action: {}) {
                            VStack(spacing: 2) {
                                Image(systemName: "heart")
                                    .font(.system(size: 26))
                                Text("24.5K")
                                    .font(.system(size: 12))
                            }
                        }
                        
                        Button(action: {}) {
                            VStack(spacing: 2) {
                                Image(systemName: "message")
                                    .font(.system(size: 26))
                                Text("1.2K")
                                    .font(.system(size: 12))
                            }
                        }
                        
                        Button(action: {}) {
                            VStack(spacing: 2) {
                                Image(systemName: "arrowshape.turn.up.right")
                                    .font(.system(size: 26))
                                Text("Share")
                                    .font(.system(size: 12))
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.trailing)
                }
                .padding(.bottom, 50) // Extra padding to stay above safe area
                
                // Progress bar
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(maxWidth: .infinity, maxHeight: 3)
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Rectangle()
                        .frame(width: UIScreen.main.bounds.width * playerManager.progress, height: 3)
                        .foregroundColor(.white)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            setupPlayer()
            playerManager.play()
        }
        .onDisappear {
            playerManager.pause()
        }
        .onChange(of: playerManager.progress) { newValue in
            if newValue >= 0.99 {
                isVideoFinished = true
            }
        }
    }
    
    private func setupPlayer() {
        playerManager.setupPlayer(url: post.videoURL)
    }
}

struct FeedView: View {
    // Changed from Int to UUID? to match the ID type used in ForEach
    @State private var currentIndex: UUID?
    
    // Dictionary to keep track of player managers
    @State private var playerManagers: [UUID: VideoPlayerManager] = [:]
    
    // Example video posts (replace URLs with actual video URLs)
    let posts = [
        VideoPost(username: "nature_lover", profileImage: "person.crop.circle.fill",
                 videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!),
        VideoPost(username: "travel_addict", profileImage: "person.crop.circle.fill.badge.checkmark",
                 videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4")!),
        VideoPost(username: "food_explorer", profileImage: "star.circle.fill",
                 videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4")!),
        VideoPost(username: "adventure_time", profileImage: "heart.circle.fill",
                 videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4")!),
        VideoPost(username: "world_wonder", profileImage: "bolt.circle.fill",
                 videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4")!)
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(posts, id: \.id) { post in
                    FeedItemView(post: post)
                        .frame(height: UIScreen.main.bounds.height)
                        .id(post.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .ignoresSafeArea()
        .background(Color.black)
        .scrollPosition(id: $currentIndex)
        .onChange(of: currentIndex) { oldValue, newValue in
            // Pause the previous video if it exists
            if let oldId = oldValue,
               let oldIndex = posts.firstIndex(where: { $0.id == oldId }) {
                print("Pausing video at index \(oldIndex)")
                // Logic to pause video would go here
            }
            
            // Play the new video if it exists
            if let newId = newValue,
               let newIndex = posts.firstIndex(where: { $0.id == newId }) {
                print("Playing video at index \(newIndex)")
                // Logic to play video would go here
            }
        }
    }
}

// Preview
struct ContentView: View {
    var body: some View {
        FeedView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
