import SwiftUI
import AVKit

// MARK: – Data model
struct VideoPost: Identifiable {
    let id = UUID()
    let username: String
    let profileImage: String
    let videoURL: URL
}

// MARK: – Video manager
class VideoPlayerManager: ObservableObject {
    @Published var progress: Double = 0
    var player: AVPlayer?
    private var timeObserver: Any?
    
    func setupPlayer(url: URL) {
        player = AVPlayer(url: url)
        let interval = CMTime(seconds: 1/30, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard
                let self = self,
                let duration = self.player?.currentItem?.duration.seconds,
                duration > 0,
                !duration.isNaN
            else { return }
            let newProgress = time.seconds / duration
            withAnimation(.linear(duration: 1/30)) {
                self.progress = newProgress
            }
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }
    
    func play()  { player?.play()  }
    func pause() { player?.pause() }
    
    @objc private func playerDidFinishPlaying() {
        progress = 1
    }
    
    deinit {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: – Custom video‐player view (encapsulates pause & finish state)
struct CustomVideoPlayer: View {
    @ObservedObject var manager: VideoPlayerManager
    @State private var isPaused = false
    @State private var isVideoFinished = false
    
    var body: some View {
        ZStack {
            if let player = manager.player {
                VideoPlayer(player: player)
                    .disabled(true)  // hide default controls
                    .onTapGesture {
                        isPaused.toggle()
                        if isPaused { manager.pause() }
                        else        { manager.play()  }
                    }
                    .overlay(
                        ZStack {
                            Color.red
                                .opacity(isVideoFinished ? 0.3 : 0)
                                .animation(.easeInOut(duration: 1), value: isVideoFinished)
                            if isPaused {
                                Image(systemName: "play.circle.fill")
                                    .resizable()
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    )
                    .onChange(of: manager.progress) { p in
                        if p >= 0.99 { isVideoFinished = true }
                    }
            } else {
                Color.black
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    )
            }
        }
    }
}

// MARK: – Single feed item
struct FeedItemView: View {
    let post: VideoPost
    @StateObject private var playerManager = VideoPlayerManager()
    
    var body: some View {
        
            TabView {
                
                ZStack{
                    CustomVideoPlayer(manager: playerManager)
                        .ignoresSafeArea()
                 
                    
                    // overlay UI
                    VStack {
                        Spacer()
                        HStack(alignment: .bottom) {
                            userInfo
                            Spacer()
                            interactionButtons
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                        
                        // progress bar
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(maxWidth: .infinity, maxHeight: 3)
                                .foregroundColor(.gray.opacity(0.5))
                            Rectangle()
                                .frame(width: UIScreen.main.bounds.width * playerManager.progress,
                                       height: 3)
                                .foregroundColor(.white)
                        }
                        
                        
                        Spacer()
                            .frame(height:84)
                    }
                    
                    
                }
                Color.orange
                    .ignoresSafeArea()
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
       
        .background(Color.black)
        .onAppear {
            playerManager.setupPlayer(url: post.videoURL)
            playerManager.play()
        }
        .onDisappear {
            playerManager.pause()
        }
    }
    
    // MARK: – UI subviews
    private var userInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: post.profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white, lineWidth: 1))
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
        }
        .foregroundColor(.white)
    }
    
    private var interactionButtons: some View {
        VStack(spacing: 20) {
            Button {} label: {
                VStack(spacing: 2) {
                    Image(systemName: "heart")
                        .font(.system(size: 26))
                    Text("24.5K")
                        .font(.system(size: 12))
                }
            }
            Button {} label: {
                VStack(spacing: 2) {
                    Image(systemName: "message")
                        .font(.system(size: 26))
                    Text("1.2K")
                        .font(.system(size: 12))
                }
            }
            Button {} label: {
                VStack(spacing: 2) {
                    Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 26))
                    Text("Share")
                        .font(.system(size: 12))
                }
            }
        }
        .foregroundColor(.white)
    }
}

// MARK: – Main feed
struct FeedView: View {
    @State private var currentIndex: UUID?
    
    let posts: [VideoPost] = [
        .init(username: "nature_lover",
              profileImage: "person.crop.circle.fill",
              videoURL: URL(string:
                "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
              )!),
        .init(username: "travel_addict",
              profileImage: "person.crop.circle.fill.badge.checkmark",
              videoURL: URL(string:
                "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"
              )!),
        .init(username: "food_explorer",
              profileImage: "star.circle.fill",
              videoURL: URL(string:
                "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
              )!),
        .init(username: "adventure_time",
              profileImage: "heart.circle.fill",
              videoURL: URL(string:
                "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
              )!),
        .init(username: "world_wonder",
              profileImage: "bolt.circle.fill",
              videoURL: URL(string:
                "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
              )!)
    ]
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(posts) { post in
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
        .onChange(of: currentIndex) { old, new in
            // pause old / play new logic here if needed
        }
    }
}

struct FeedView_Previews: PreviewProvider {
    static var previews: some View {
        FeedView()
    }
}
