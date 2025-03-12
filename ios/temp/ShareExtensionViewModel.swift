//
//  ShareExtensionViewModel.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/11.
//

import SwiftUI
import UniformTypeIdentifiers
import TwoCentsInternal

@MainActor @Observable
class ShareExtensionViewModel {
    var items: [NSExtensionItem]
    var mediaType: Media?
    var sharedItems: [Any] = []
    
    init(items: [NSExtensionItem]) {
        self.items = items
        self.processItems()
    }
    
    func close() {
        NotificationCenter.default.post(name: NSNotification.Name("close"), object: nil)
    }

    func processItems() {
        for item in items {
            if let attachments = item.attachments {
                for provider in attachments {
                    // Check and load an image.
                    if provider.hasItemConformingToTypeIdentifier(
                        UTType.image.identifier)
                    {
                        provider.loadItem(
                            forTypeIdentifier: UTType.image.identifier,
                            options: nil
                        ) { (data, error) in
                            if let image = data as? UIImage {
                                if self.mediaType == nil {
                                    self.mediaType = .IMAGE
                                }
                                if self.mediaType == .IMAGE {
                                    self.sharedItems.append(image)
                                }
                            }
                        }
                    }
                    // Check and load a video.
                    else if provider.hasItemConformingToTypeIdentifier(
                        UTType.movie.identifier)
                    {
                        provider.loadItem(
                            forTypeIdentifier: UTType.movie.identifier,
                            options: nil
                        ) { (data, error) in
                            if let url = data as? URL {
                                if self.mediaType == nil {
                                    self.mediaType = .VIDEO
                                }
                                if self.mediaType == .VIDEO {
                                    self.sharedItems.append(url)
                                }
                            }
                        }
                    }
                    // Check and load text.
                    else if provider.hasItemConformingToTypeIdentifier(
                        UTType.text.identifier)
                    {
                        provider.loadItem(
                            forTypeIdentifier: UTType.text.identifier,
                            options: nil
                        ) { (data, error) in
                            if let text = data as? String {
                                if self.mediaType == nil {
                                    self.mediaType = .TEXT
                                }
                                if self.mediaType == .TEXT {
                                    self.sharedItems.append(text)
                                }
                            }
                        }
                    }
                    // Check and load a URL (link).
                    else if provider.hasItemConformingToTypeIdentifier(
                        UTType.url.identifier)
                    {
                        provider.loadItem(
                            forTypeIdentifier: UTType.url.identifier,
                            options: nil
                        ) { (data, error) in
                            if let url = data as? URL {
                                if self.mediaType == nil {
                                    self.mediaType = .LINK
                                }
                                if self.mediaType == .LINK {
                                    self.sharedItems.append(url)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func post() {
        // Immediately complete the extension request.

        //For now we just send over the first item
        if let mediaType {
            let postRequest = PostRequest(media: mediaType, caption: nil, groups: [UUID(uuidString: "b343342a-d41b-4c79-a8a8-7e0b142be6da")!])
            Task {
                let post = try await PostManager.uploadPost(postRequest: postRequest)
                
                switch mediaType {
                case .IMAGE:
                    await handleImage(post: post)
                case .VIDEO:
                    await handleVideo(post: post)
                case .TEXT:
                    await handleText(post: post)
                case .LINK:
                    await handleLink(post: post)
                case .OTHER:
                    print("Tough")
                }
                
            }
            
        }

    }
    
    private func handleImage(post: Post) async {
        for item in sharedItems {
            guard let image = item as? UIImage else {
                continue
            }
            let data = image.jpegData(compressionQuality: 1.0)
            if let data {
                _ = try? await PostManager.uploadMediaPost(post: post, data: data)
            }
        }
    }
    
    private func handleVideo(post: Post) async {
        for item in sharedItems {
            guard let videoURL = item as? URL else {
                continue
            }
            guard let data = try? Data(contentsOf: videoURL) else {
                continue
            }
            _ = try? await PostManager.uploadMediaPost(post: post, data: data)
        }
    }
    
    private func handleText(post: Post) async {
        print("Not implemented yet")
        for item in sharedItems {
            guard let text = item as? String else {
                continue
            }
            let body = [
                "text": text
            ]
            guard let data = try? TwoCentsEncoder().encode(body) else {
                continue
            }
            _ = try? await PostManager.uploadMediaPost(post: post, data: data)
        }
    }

    private func handleLink(post: Post) async {
        for item in sharedItems {
            guard let linkURL = item as? URL else {
                continue
            }
            let body = [
                "mediaUrl": linkURL
            ]
            guard let data = try? TwoCentsEncoder().encode(body) else {
                continue
            }
           _ = try? await PostManager.uploadMediaPost(post: post, data: data)
        }
    }

}
