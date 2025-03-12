//
//  CachedVideo.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//

import AVKit
import SwiftUI

public struct CachedVideo<FailureView: View>: View {
    
    public let videoUrl: URL
    @State public var videoPlayer: AVPlayer?
    @State public var isLoading: Bool = true
    public var failureView: FailureView
    
    // Initializer to provide a custom failure view.
    public init(url: URL, @ViewBuilder onFailure: () -> FailureView) {
        self.videoUrl = url
        self.failureView = onFailure()
    }
    
    // Convenience initializer when no custom failure view is provided.
    // This forces FailureView to be DefaultFailureView.
    public init(url: URL) where FailureView == DefaultFailureView {
        self.videoUrl = url
        self.failureView = DefaultFailureView()
    }
    
    public var body: some View {
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
