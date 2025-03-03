//
//  CachedImage.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/6.
//
import SwiftUI

struct CachedImage: View {

    let imageUrl: URL
    @State private var cachedURL: URL?
    @State private var isLoading: Bool = true
    
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
                            .aspectRatio(contentMode: .fill)
                            .clipped()
                    case .failure:
                        Image(systemName: "exclamationmark.triangle")
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if isLoading {
                ProgressView()
            } else {
                Image(systemName: "exclamationmark.triangle")
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
