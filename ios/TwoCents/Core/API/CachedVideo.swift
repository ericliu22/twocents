//
//  CachedVideo.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//

import AVKit
import SwiftUI

struct CachedVideo<FailureView: View>: View {
    
    let videoUrl: URL
    @State var videoPlayer: AVPlayer?
    @State var isLoading: Bool = true
    var failureView: FailureView
    
    // Initializer to provide a custom failure view.
    init(url: URL, @ViewBuilder onFailure: () -> FailureView) {
        self.videoUrl = url
        self.failureView = onFailure()
    }
    
    // Convenience initializer when no custom failure view is provided.
    // This forces FailureView to be DefaultFailureView.
    init(url: URL) where FailureView == DefaultFailureView {
        self.videoUrl = url
        self.failureView = DefaultFailureView()
    }
    
    var body: some View {
        ZStack {
            if let videoPlayer {
                VideoPlayer(player: videoPlayer)
                    .ignoresSafeArea()
                    .onDisappear {
                        videoPlayer.pause()
                    }
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            } else {
                failureView
            }
        }
        .task {
            do {
                let cachedURL = try await CacheManager.fetchCachedVideoURL(for: videoUrl)
                let asset = AVURLAsset(url: cachedURL)
                let playerItem = AVPlayerItem(asset: asset)
                videoPlayer = AVPlayer(playerItem: playerItem)
                isLoading = false
            } catch {
                isLoading = false
            }
        }
    }
}
