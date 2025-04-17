//
//  PostContainer.swift
//  TwoCents
//
//  Created by Joshua Shen on 3/30/25.
//

//
//  PostContainer.swift
//  Shared Data Container for Posts and Media
//
//  Created by Your Name on [Date].
//

import Foundation
import UIKit
import TwoCentsInternal

struct PostContainer {
    
    static let appGroupID = "group.com.example.myapp"
    
    static var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    // URL for the posts.json file that holds the metadata
    static var postsFileURL: URL? {
        return containerURL?.appendingPathComponent("posts.json")
    }
    
    // Generic function to get a folder URL for a given media type (e.g., "images", "videos")
    static func folderURL(for mediaType: Media) -> URL? {
        guard let container = containerURL else { return nil }
        let folderName: String
        switch mediaType {
        case .IMAGE:
            folderName = "images"
        case .VIDEO:
            folderName = "videos"
        default:
            folderName = "otherMedia"
        }
        let folderURL = container.appendingPathComponent(folderName)
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating \(folderName) folder: \(error)")
                return nil
            }
        }
        return folderURL
    }
    
    // MARK: - Posts Metadata Methods
    
    static func savePosts(_ posts: [Post]) {
        guard let fileURL = postsFileURL else { return }
        do {
            let data = try TwoCentsEncoder().encode(posts)
            try data.write(to: fileURL)
            print("Posts saved successfully.")
        } catch {
            print("Error saving posts: \(error)")
        }
    }
    
    static func loadPosts() -> [Post]? {
        guard let fileURL = postsFileURL else { return nil }
        do {
            let data = try Data(contentsOf: fileURL)
            let posts = try TwoCentsDecoder().decode([Post].self, from: data)
            return posts
        } catch {
            print("Error loading posts: \(error)")
            return nil
        }
    }
    
    // MARK: - Media Files Methods
    
    /// Save a media file using a UUID for the filename and storing it in a media-specific folder.
    /// - Parameters:
    ///   - data: The raw data of the media file.
    ///   - mediaType: The type of media (.IMAGE or .VIDEO).
    /// - Returns: The generated filename (UUID with extension) or nil if there was an error.
    static func saveMediaFile(data: Data, mediaType: Media) -> String? {
        guard let folderURL = folderURL(for: mediaType) else { return nil }
        
        // Generate a UUID for the filename.
        let uuid = UUID().uuidString
        let fileExtension: String
        switch mediaType {
        case .IMAGE:
            fileExtension = "jpg" // or "jpg", depending on your image format
        case .VIDEO:
            fileExtension = "mp4" // adjust as needed for your video format
        default:
            fileExtension = "dat"
        }
        let fileName = "\(uuid).\(fileExtension)"
        let fileURL = folderURL.appendingPathComponent(fileName)
        do {
            try data.write(to: fileURL)
            print("Media file saved as \(fileName).")
            return fileName
        } catch {
            print("Error saving media file: \(error)")
            return nil
        }
    }
    
    /// Load an image for a given post from the images folder.
    static func loadImage(for post: Post) -> UIImage? {
        let fileName = post.id
        guard let folderURL = folderURL(for: .IMAGE) else { return nil }
        let fileURL = folderURL.appendingPathComponent(fileName.uuidString)
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            print("Error loading image: \(error)")
            return nil
        }
    }
    // You can add similar methods for loading videos or other media types.
}
