//
//  LinkView.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/17.
//  Updated on 2025/3/27 to integrate embedding.
//

import TwoCentsInternal
import SwiftUI
import LinkPresentation
import WebKit

struct LinkView: PostView {
    let post: Post
    @State var link: LinkDownload?
    let isDetail: Bool
    
    init(post: Post, isDetail: Bool = false) {
        self.post = post
        self.isDetail = isDetail
    }
    
    var body: some View {
        Group {
            if let link {
                if let url = URL(string: link.mediaUrl) {
                    // If the URL is one of the known embeddable providers, show an embedded view.
                    if let embedURL = embedURL(for: url), isDetail {
                        WebView(url: embedURL)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Otherwise, fall back to the LinkPreview.
                        LinkPreview(url: url, isDetail: isDetail)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            // Fetch media data asynchronously.
            guard let data = try? await PostManager.getMedia(post: post) else {
                return
            }
            let links = try? JSONDecoder().decode([LinkDownload].self, from: data)
            // Update state on the main thread.
            await MainActor.run {
                link = links?.first
            }
        }
    }
    
    // MARK: - Helper Methods for Embedding
    
    /// Returns an embed URL for known providers (YouTube, Instagram, TikTok).
    private func embedURL(for url: URL) -> URL? {
        let absoluteString = url.absoluteString.lowercased()
        if absoluteString.contains("youtube.com") || absoluteString.contains("youtu.be") {
            if let videoID = extractYouTubeID(from: url) {
                return URL(string: "https://www.youtube.com/embed/\(videoID)")
            }
        } else if absoluteString.contains("instagram.com") {
            // Instagram embed: Depending on your needs, you might need additional parameters.
            return url
        } else if absoluteString.contains("tiktok.com") {
            // TikTok embed: Use the URL directly if embedding is supported.
            return url
        }
        return nil
    }
    
    /// Extracts the YouTube video ID from a URL using common URL patterns.
    private func extractYouTubeID(from url: URL) -> String? {
        let patterns = [
            "youtube\\.com/watch\\?v=([^&]+)",
            "youtu\\.be/([^?&]+)"
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(location: 0, length: url.absoluteString.utf16.count)
                if let match = regex.firstMatch(in: url.absoluteString, options: [], range: range),
                   let range1 = Range(match.range(at: 1), in: url.absoluteString) {
                    return String(url.absoluteString[range1])
                }
            }
        }
        return nil
    }
}

// MARK: - WebView for Embedded Content

/// A simple wrapper around WKWebView to load and display embedded content.
struct WebView: UIViewRepresentable {
    let url: URL
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = true
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        uiView.load(request)
    }
}

// MARK: - Fallback LinkPreview

/// A link preview using LPLinkMetadata that fetches metadata and displays an image and title.
struct LinkPreview: View {
    let url: URL
    let isDetail: Bool
    @State private var metadata: LPLinkMetadata?
    @State private var previewImage: UIImage?
    
    var body: some View {
        VStack(spacing: 0) {
            // Image container.
            Group {
                if let previewImage = previewImage {
                    
                    
                   
                    if url.absoluteString.contains("tiktok.com") {
                        //zoom in for tiktok thumbnails to look better for ui
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .scaleEffect(2.55)
                            .frame(maxWidth: .infinity, maxHeight: isDetail ? nil : .infinity)
                            .clipped()
                            
                            .background(
//                                ZStack {
//                                    Color.black
//                                    Image(uiImage: previewImage)
//                                        .resizable()
//                                        .scaledToFill()
//                                        .frame(maxWidth: .infinity)
//                                        .clipped()
//                                        .blur(radius: 5)
//                                        .opacity(0.3)
//                                }
                                Color.red
                            )
                            .contentShape(Rectangle())
                        
                    } else {
                        
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: isDetail ? nil : .infinity)
                            .clipped()
                            
                            .background(
                                ZStack {
                                    Color.black
                                    Image(uiImage: previewImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .blur(radius: 5)
                                        .opacity(0.3)
                                }
                            )
                            .contentShape(Rectangle())
                        
                    }
                    
                    
                    
                    
                    
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: isDetail ? (UIScreen.main.bounds.width / 16) * 9 : .infinity)
                        .overlay(
                            Image(systemName: "link")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                        )
                }
            }
            if isDetail {
            // Text container below the image.
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    
                    //title of the link
                    
                    
                 
                        
                        
                        if let title = metadata?.title {
                            Text(title)
                                .font(.subheadline)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text(url.absoluteString)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                        
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 5)
                    }
                }
            .padding(.horizontal, 5)
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemBackground))
            }
           
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .contentShape(Rectangle())
        .onChange(of: metadata) { newMetadata in
            // Load the preview image once metadata is available.
            guard let newMetadata = newMetadata,
                  let imageProvider = newMetadata.imageProvider else { return }
            imageProvider.loadObject(ofClass: UIImage.self) { object, error in
                if let error = error {
                    print("Error loading image: \(error)")
                } else if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        previewImage = image
                    }
                }
            }
        }
        .task {
            let provider = LPMetadataProvider()
            do {
                let fetchedMetadata = try await provider.startFetchingMetadata(for: url)
                DispatchQueue.main.async {
                    metadata = fetchedMetadata
                }
            } catch {
                print("Error fetching metadata: \(error)")
            }
        }
    }
}
