//
//  CreatePostViewModel.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/8.
//
import SwiftUI
import UniformTypeIdentifiers

@MainActor @Observable
class CreatePostViewModel {

    let groups: [UUID] = [HARDCODED_GROUP.id]
    var caption: String = ""
    var mediaType: Media = .LINK
    var mediaURL: String = ""
    var selectedMedia: [SelectedMedia] = []  // Holds SelectedMedia items
    var showMediaPicker = false
    var isPosting = false
    var fullScreenMedia: SelectedMedia? = nil  // For full screen preview

    func createPost() async {
        isPosting = true
        
        print(caption)
        print(mediaURL)
        print(mediaType)
        print(selectedMedia)

        switch mediaType {
        case .IMAGE:
            await createImage()
        case .VIDEO:
            await createVideo()
        case .TEXT:
            await createText()
        case .LINK:
            await createLink()
        case .OTHER:
            await createLink()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isPosting = false
        }

    }

    func createImage() async {
        let postRequest = PostRequest(
            media: .IMAGE, caption: caption.isEmpty ? nil : caption,
            groups: groups)
        guard
            let post = try? await PostManager.uploadPost(
                postRequest: postRequest)
        else {
            print("Failed to upload post")
            return
        }
        for media in selectedMedia {
            if let imageData = UIImage(contentsOfFile: media.url.path)?
                .jpegData(compressionQuality: 1.0)
            {
                _ = try? await PostManager.uploadMediaPost(
                    post: post, data: imageData)
            }
        }
    }

    func createVideo() async {
        let postRequest = PostRequest(
            media: .VIDEO, caption: caption.isEmpty ? nil : caption,
            groups: groups)
        guard
            let post = try? await PostManager.uploadPost(
                postRequest: postRequest)
        else {
            print("Failed to upload post")
            return
        }
        for media in selectedMedia {
            guard let resourceValues = try? media.url.resourceValues(forKeys: [.contentTypeKey]) else {
                continue
            }
            if let contentType = resourceValues.contentType, contentType.conforms(to: .mpeg4Movie) {
                guard let videoData = try? Data(contentsOf: media.url) else {
                    continue
                }
                guard let _ = try? await PostManager.uploadMediaPost(
                    post: post, data: videoData) else {
                    print("Failed to upload video")
                    continue
                }
            }
        }
    }
    
    func createLink() async {
        let postRequest = PostRequest(
            media: .VIDEO, caption: caption.isEmpty ? nil : caption,
            groups: groups)
        guard
            let post = try? await PostManager.uploadPost(
                postRequest: postRequest)
        else {
            print("Failed to upload post")
            return
        }
        
        //Important that it's lowercase
        let body = [
            "mediaUrl": mediaURL
        ]
        guard let data = try? TwoCentsEncoder().encode(body) else {
            print("Failed to encode body")
            return
        }
        guard let _ = try? await PostManager.uploadMediaPost(post: post, data: data) else {
            print("Failed to upload link")
            return
        }
    }
    
    func createText() async {
        print("Not properly implemented yet. Needs additional text field besides caption")
    }
}
