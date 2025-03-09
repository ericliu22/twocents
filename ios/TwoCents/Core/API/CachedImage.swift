//
//  CachedImage.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/6.
//
import SwiftUI

struct DefaultFailureView: View {
    var body: some View {
        Image(systemName: "exclamationmark.triangle")
    }
}

struct CachedImage<FailureView: View>: View {

    let imageUrl: URL
    @State private var cachedURL: URL?
    @State private var isLoading: Bool = true
    var failureView: FailureView
    
    init(url: URL, @ViewBuilder onFailure: () -> FailureView) {
        self.imageUrl = url
        self.failureView = onFailure()
    }
    
    init(url: URL) where FailureView == DefaultFailureView {
        self.imageUrl = url
        self.failureView = DefaultFailureView()
    }
    
    var body: some View {
        ZStack {
            if let url = cachedURL {
                // pass the local URL to AsyncImage
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .clipped()
                    case .failure:
                        failureView
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if isLoading {
                ProgressView()
            } else {
                failureView
            }
        }
        .task {
            
            do {
                cachedURL = try await CacheManager.fetchCachedImageURL(for: imageUrl)
                isLoading = false
            } catch {
                print("Failed to fetch")
                isLoading = false
            }
        }
    }
    
}
