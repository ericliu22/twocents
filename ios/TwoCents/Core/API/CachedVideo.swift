//
//  CachedVideo.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/3.
//

import AVKit
import SwiftUI

struct VideoWidgetSheetView: View {

    let videoUrl: URL
    @State var videoPlayer: AVPlayer?
    @State var isLoading: Bool = true

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
                Image(systemName: "exclamationmark.triangle")
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
