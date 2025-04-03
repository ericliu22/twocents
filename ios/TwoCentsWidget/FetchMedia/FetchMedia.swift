//
//  MediaFetch.swift
//  TwoCents
//
//  Created by Eric Liu on 3/31/25.
//
import TwoCentsInternal
import Foundation
import AVKit
import LinkPresentation

protocol FetchableMedia { }
extension UIImage: FetchableMedia { }
extension AVAsset: FetchableMedia { }
extension String: FetchableMedia { }

struct TwoCentsLinkMetadata: Identifiable, FetchableMedia {
    let id = UUID()
    let title: String?
    let image: UIImage
    let url: URL
}

func fetchMedia(download: [any Downloadable], media: Media) async -> [FetchableMedia] {
    
    do {
        switch media {
        case .IMAGE:
            let imageDownloads = download as? [ImageDownload] ?? []
            var images: [UIImage] = []
            
            for imageDownload in imageDownloads {
                let image = try await fetchImage(from: imageDownload.mediaUrl)
                images.append(image)
            }
            return images
        case .VIDEO:
            let videoDownloads = download as? [VideoDownload] ?? []
            var videos: [AVAsset] = []
            
            for videoDownload in videoDownloads {
                let video = try await fetchVideo(from: videoDownload.mediaUrl)
                videos.append(video)
            }
            return videos
        case .TEXT:
            let textDownloads = download as? [TextDownload] ?? []
            var texts: [String] = []
            
            for textDownload in textDownloads {
                let text = textDownload.text
                texts.append(text)
            }
            return texts
        case .LINK:
            let linkDownloads = download as? [LinkDownload] ?? []
            var links: [TwoCentsLinkMetadata] = []
            
            for linkDownload in linkDownloads {
                let link = try await fetchLink(from: linkDownload.mediaUrl)
                links.append(link)
            }
            return links
        default:
            return []
        }
    } catch {
        print("FAILED MEDIA FETCH")
        return []
    }
}

func fetchImage(from urlString: String) async throws -> UIImage {
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    let (data, _) = try await URLSession.shared.data(from: url)
    
    guard let image = UIImage(data: data) else {
        throw NSError(domain: "Invalid image data", code: -1, userInfo: nil)
    }
    
    return image
}

func fetchVideo(from urlString: String) async throws -> AVAsset {
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    
    // Download the video file to a temporary URL.
    let (fileURL, _) = try await URLSession.shared.download(from: url)
    
    // Create an AVURLAsset from the local file URL.
    let asset = AVURLAsset(url: fileURL)
    return asset
}

func fetchLink(from urlString: String) async throws -> TwoCentsLinkMetadata {
    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }
    return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<TwoCentsLinkMetadata, Error>) in
        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else if let metadata = metadata {
                metadata.imageProvider?.loadObject(ofClass: UIImage.self) { object, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let image = object as? UIImage {
                        let link = TwoCentsLinkMetadata(title: metadata.title, image: image, url: url)
                        continuation.resume(returning: link)
                    }
                }
            } else {
                let unknownError = NSError(domain: "LPLinkMetadataError", code: -1, userInfo: nil)
                continuation.resume(throwing: unknownError)
            }
        }
    }
}
