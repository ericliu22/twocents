//
//  CachedImage.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/6.
//
import SwiftUI

public struct DefaultFailureView: View {
    public var body: some View {
        Image(systemName: "exclamationmark.triangle")
    }
}

public struct CachedImage<FailureView: View>: View {

    public let imageUrl: URL
    @State public var cachedURL: URL?
    @State public var isLoading: Bool = true
    public var failureView: FailureView
    
    public init(url: URL, @ViewBuilder onFailure: () -> FailureView) {
        self.imageUrl = url
        self.failureView = onFailure()
    }
    
    public init(url: URL) where FailureView == DefaultFailureView {
        self.imageUrl = url
        self.failureView = DefaultFailureView()
    }
    
    public var body: some View {
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
