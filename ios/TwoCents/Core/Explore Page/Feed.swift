import SwiftUI
import AVKit

// MARK: – A UIView subclass whose backing layer IS an AVPlayerLayer
class AVPlayerUIView: UIView {
    // Tell UIKit that our layer is an AVPlayerLayer
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    // Convenience accessor
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    // Set up the layer once
    init(player: AVPlayer) {
        super.init(frame: .zero)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    // Whenever the view lays out, update the layer’s bounds
    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: – UIViewRepresentable that uses our subclass
struct PlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> AVPlayerUIView {
        AVPlayerUIView(player: player)
    }

    func updateUIView(_ uiView: AVPlayerUIView, context: Context) {
        // nothing needed here
    }
}

// MARK: – Your ViewModel (unchanged)
class VideoPlayerViewModel: ObservableObject {
    let player: AVPlayer
    @Published var currentTime: Double = 0
    @Published var duration: Double = 1
    @Published var isEnded: Bool = false

    private var timeObserver: Any?
    private var endObserver: Any?

    init(url: URL) {
        player = AVPlayer(url: url)
        guard let item = player.currentItem else { return }

        // Load duration once ready
        item.asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async {
                let d = item.asset.duration
                if CMTIME_IS_NUMERIC(d) { self.duration = d.seconds }
            }
        }

        // Update currentTime ~10×/sec
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            self?.currentTime = time.seconds
        }

        // Listen for "did finish"
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            withAnimation(.easeInOut) {
                self?.isEnded = true
            }
        }
    }

    deinit {
        if let t = timeObserver { player.removeTimeObserver(t) }
        if let o = endObserver { NotificationCenter.default.removeObserver(o) }
    }

    func play() { player.play() }
}

// MARK: – FeedVideoView using our working PlayerView
struct FeedVideoView: View {
    @StateObject private var vm: VideoPlayerViewModel

    init() {
        let sampleURL = URL(string: "https://d2z80tvgtq0lqn.cloudfront.net/videos/463def35-e500-4877-a3b1-01e648e1281c.mp4")!
        _vm = StateObject(wrappedValue: VideoPlayerViewModel(url: sampleURL))
    }

    var body: some View {
        ZStack {
            // Full‑screen video
            PlayerView(player: vm.player)
                .ignoresSafeArea()

            // Progress bar
            VStack {
                Spacer()
                ProgressView(value: vm.currentTime, total: vm.duration)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                    .opacity(vm.isEnded ? 0 : 1)
            }

            // End‑screen
            if vm.isEnded {
                Color.red
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .onAppear { vm.play() }
    }
}

// MARK: – FeedItemView & FeedView (unchanged)
struct FeedItemView: View {
    var body: some View {
        TabView {
            FeedVideoView()
            Color.orange.ignoresSafeArea()
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
}

struct FeedView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(0..<5) { _ in
                    FeedItemView()
                        .frame(height: UIScreen.main.bounds.height)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .ignoresSafeArea()
    }
}
