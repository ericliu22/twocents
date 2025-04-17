//
//  CreatePostViewModel.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/3/8.
//
import SwiftUI
import TwoCentsInternal
import UniformTypeIdentifiers

@MainActor @Observable
class CreatePostViewModel {

    let groups: [UUID] = [HARDCODED_GROUP.id]
    var caption: String = ""
    var mediaType: Media = .LINK
    var mediaURL: String = ""
    var selectedMedia: [SelectedMedia] = []  // Holds SelectedMedia items
    var showPhotoPicker = false
    var showVideoPicker = false
    var isPosting = false
    var fullScreenMedia: SelectedMedia? = nil  // For full screen preview

    func createPost() async {

        isPosting = true
        defer { isPosting = false }

        let caption = caption.isEmpty ? nil : caption
        let request = PostRequest(
            media: mediaType, caption: caption, groups: groups)

        do {
            let payload = try buildPayload()
            _ = try await PostManager.createPostMultipart(
                request: request, payload: payload)

            // reset UI state
            self.caption = ""
            self.selectedMedia = []
            self.mediaURL = ""

        } catch {
            print("❌ Post failed:", error)
        }
    }

    // MARK: – Helpers

    /// Converts the current UI state into the secondary multipart part.
    private func buildPayload() throws -> PostPayload {

        switch mediaType {

        case .IMAGE:
            guard let first = selectedMedia.first else { return .none }
            guard
                let data = UIImage(contentsOfFile: first.url.path)?
                    .jpegData(compressionQuality: 0.95)
            else {
                throw APIError.noData
            }
            return .file(
                data: data,
                mimeType: "image/jpeg",
                filename: first.url.lastPathComponent)

        case .VIDEO:
            guard let first = selectedMedia.first else { return .none }
            let data = try Data(contentsOf: first.url)
            return .file(
                data: data,
                mimeType: "video/mp4",
                filename: first.url.lastPathComponent)

        case .LINK:
            let link = ["mediaUrl": mediaURL]  // <- no postId
            let json = try TwoCentsEncoder().encode(link)
            return .json(json)

        case .TEXT:
            let text = ["text": caption ?? ""]
            let json = try TwoCentsEncoder().encode(text)
            return .json(json)

        case .OTHER:
            // fall back to first file, treat as binary blob
            guard let first = selectedMedia.first else { return .none }
            let data = try Data(contentsOf: first.url)
            return .file(
                data: data,
                mimeType: "application/octet-stream",
                filename: first.url.lastPathComponent)
        }
    }
}
