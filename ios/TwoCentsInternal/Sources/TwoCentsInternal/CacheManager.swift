//
//  CacheManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/6.
//
import SwiftUI
import CryptoKit

/// Simple enum to handle file type -> extension mapping.
enum FileType {
    case image
    case video
    
    var fileExtension: String {
        switch self {
        case .image: return "jpeg"
        case .video: return "mp4"
        }
    }
}

/// A manager for caching images/videos with version checks to detect changes.
struct CacheManager {
    
    // MARK: Direct URL-based Fetch with ETag or Last-Modified Check
    
    /// Fetch a local file URL for a direct (HTTPS) image URL.
    /// 1. Issues a HEAD request to get ETag/Last-Modified.
    /// 2. If local is stale, re-download.
    /// 3. Returns local file URL.
    static func fetchCachedImageURL(for remoteURL: URL) async throws -> URL {
        
        // Hash the URL string to form a unique local filename
        let urlString = remoteURL.absoluteString
        let hashedName = sha256(urlString)
        let localURL = makeLocalURL(forHashedName: hashedName, fileType: .image)
        
        // Keys for storing ETag & last-modified in UserDefaults
        let localEtagKey  = "MediaCacheManager.etag.\(hashedName)"
        let localModKey   = "MediaCacheManager.lastModified.\(hashedName)"
        
        // Check if local file exists
        let fileExists = FileManager.default.fileExists(atPath: localURL.path)
        
        // We'll do a HEAD request to check headers only if we already have a local file
        if fileExists {
            do {
                let (etag, lastMod) = try await fetchHttpHeaders(for: remoteURL)
                let localEtag = UserDefaults.standard.string(forKey: localEtagKey)
                let localLastMod = UserDefaults.standard.string(forKey: localModKey)
                
                // If ETag or Last-Modified differs, the file changed => remove local
                let changed = (etag != nil && etag != localEtag)
                            || (lastMod != nil && lastMod != localLastMod)
                
                if changed {
                    try? FileManager.default.removeItem(at: localURL)
                }
            } catch {
                // If HEAD fails, we’ll ignore and proceed with the existing file
                // Or you might choose to re-download.
                print("HEAD request failed:", error)
            }
        }
        
        // If the file is gone or didn’t exist, download it
        if !FileManager.default.fileExists(atPath: localURL.path) {
            // Download data
            let (data, response) = try await URLSession.shared.data(from: remoteURL)
            try data.write(to: localURL)
            
            // Read ETag/Last-Modified from the *GET* response too
            if let httpResp = response as? HTTPURLResponse {
                let etag    = httpResp.value(forHTTPHeaderField: "ETag")
                let lastMod = httpResp.value(forHTTPHeaderField: "Last-Modified")
                if let etag = etag {
                    UserDefaults.standard.set(etag, forKey: localEtagKey)
                }
                if let lastMod = lastMod {
                    UserDefaults.standard.set(lastMod, forKey: localModKey)
                }
            }
        }
        
        return localURL
    }
    
    // MARK: - Video Fetch with ETag / Last-Modified
        
        /// Fetches and caches a video from a remote URL (HTTPS).
        /// 1. If local file is present, issues a HEAD request to compare ETag/Last-Modified.
        /// 2. If changed or missing, downloads again.
        /// 3. Returns the local cached file URL.
        static func fetchCachedVideoURL(for remoteURL: URL) async throws -> URL {
            
            // 1) Generate a unique local filename by hashing the remote URL
            let urlString = remoteURL.absoluteString
            let hashedName = sha256(urlString)
            let localURL = makeLocalURL(forHashedName: hashedName, fileType: .video)
            
            // 2) Prepare keys to store ETag / Last-Modified in UserDefaults
            let localEtagKey  = "MediaCacheManager.etag.video.\(hashedName)"
            let localModKey   = "MediaCacheManager.lastModified.video.\(hashedName)"
            
            // 3) If local file already exists, do a HEAD request to see if changed
            let fileExists = FileManager.default.fileExists(atPath: localURL.path)
            
            if fileExists {
                do {
                    let (etag, lastModified) = try await fetchHttpHeaders(for: remoteURL)
                    
                    let localEtag = UserDefaults.standard.string(forKey: localEtagKey)
                    let localLastMod = UserDefaults.standard.string(forKey: localModKey)
                    
                    // Compare ETag / Last-Modified
                    let changed = (etag != nil && etag != localEtag)
                                || (lastModified != nil && lastModified != localLastMod)
                    
                    // If changed, remove the old file to force a new download
                    if changed {
                        try? FileManager.default.removeItem(at: localURL)
                    }
                } catch {
                    // If HEAD fails, you can decide to keep the old file or re-download
                    // Here we’ll just print the error and continue
                    print("HEAD request failed for video:", error)
                }
            }
            
            // 4) If file not found or removed, download again
            if !FileManager.default.fileExists(atPath: localURL.path) {
                let (data, response) = try await URLSession.shared.data(from: remoteURL)
                try data.write(to: localURL, options: .atomic)
                
                // Update ETag / Last-Modified from GET response
                if let httpResp = response as? HTTPURLResponse {
                    let etag    = httpResp.value(forHTTPHeaderField: "ETag")
                    let lastMod = httpResp.value(forHTTPHeaderField: "Last-Modified")
                    
                    if let etag = etag {
                        UserDefaults.standard.set(etag, forKey: localEtagKey)
                    }
                    if let lastMod = lastMod {
                        UserDefaults.standard.set(lastMod, forKey: localModKey)
                    }
                }
            }
            
            // 5) Return the local file URL
            return localURL
        }
    
    
    // MARK: - Helper: HEAD request to fetch ETag/Last-Modified
    
    /// Sends a HEAD request to get ETag or Last-Modified from the server
    private static func fetchHttpHeaders(for url: URL) async throws -> (etag: String?, lastModified: String?) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let etag    = httpResp.value(forHTTPHeaderField: "ETag")
        let lastMod = httpResp.value(forHTTPHeaderField: "Last-Modified")
        return (etag, lastMod)
    }
    
    
    // MARK: - Internal Helpers
    
    /// Creates a local cache URL in the Caches directory.
    private static func makeLocalURL(forHashedName hashedName: String, fileType: FileType) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let fileName = "\(hashedName).\(fileType.fileExtension)"
        return cacheDir.appendingPathComponent(fileName)
    }
    
    /// Create a SHA256 hash for string-based paths or URLs (to safely generate file names).
    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
