import SwiftUI
import AVKit

struct Video: Identifiable {
    let id = UUID()
    let url: String
    let caption: String
}

class ExploreViewModel: ObservableObject {
    @Published var videos: [Video] = []
    private var currentPage = 0
    private let pageSize = 5
    private var isFetching = false
    
    init() {
        fetchVideos()
    }
    
    func fetchVideos() {
        guard !isFetching else { return }
        isFetching = true
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) {
            let newVideos = (0..<self.pageSize).map { index in
                Video(url: "https://www.w3schools.com/html/mov_bbb.mp4", caption: "Video \(self.currentPage * self.pageSize + index + 1)")
            }
            
            DispatchQueue.main.async {
                self.videos.append(contentsOf: newVideos)
                self.currentPage += 1
                self.isFetching = false
            }
        }
    }
}

struct ExploreView: View {
    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        TabView {
            ForEach(viewModel.videos.indices, id: \.self) { index in
                VideoPlayerView(videoURL: URL(string: viewModel.videos[index].url)!)
                    .overlay(
                        VStack {
                            Spacer()
                            Text(viewModel.videos[index].caption)
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                        },
                        alignment: .bottom
                    )
                    .onAppear {
                        if index == viewModel.videos.count - 1 { // If last video appears, load more
                            viewModel.fetchVideos()
                        }
                    }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

struct VideoPlayerView: View {
    let videoURL: URL
    @State private var player: AVPlayer?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VideoPlayer(player: player)
                .onAppear {
                    player = AVPlayer(url: videoURL)
                    player?.play()
                }
                .onDisappear {
                    player?.pause()
                }
        }
    }
}

struct TikTokFeedView_Previews: PreviewProvider {
    static var previews: some View {
        ExploreView()
    }
}
