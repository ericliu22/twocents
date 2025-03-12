//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Eric Liu on 2025/3/11.
//

import UIKit
import Social
import UniformTypeIdentifiers
import TwoCentsInternal

class ShareViewController: SLComposeServiceViewController {
    
    var mediaType: Media?
    var sharedItems: [Any] = []

    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        guard
            let extensionItems = extensionContext?.inputItems
                as? [NSExtensionItem]
        else {
            self.extensionContext?.completeRequest(
                returningItems: [], completionHandler: nil)
            return
        }
        for item in extensionItems {
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
        
        if sharedItems.isEmpty {
            self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        }
        
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
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
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

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
