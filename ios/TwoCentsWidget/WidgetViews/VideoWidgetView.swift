//
//  VideoWidgetView.swift
//  TwoCents
//
//  Created by Eric Liu on 3/31/25.
//
import SwiftUI
import TwoCentsInternal
import AVKit

struct VideoWidgetView: View {

    let entry: TwoCentsEntry
    var videos: [AVAsset] = []

    init(entry: TwoCentsEntry) {
        self.entry = entry
        self.videos = entry.fetchedMedia as? [AVAsset] ?? []
    }

    var body: some View {
            TabView {
                ForEach(videos, id: \.self) { video in
                    VideoPlayer(player: AVPlayer(playerItem: AVPlayerItem(asset: video)))
                        .ignoresSafeArea()
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
    }
}

