//
//  CacheManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/6.
//
//
//  CacheManager.swift
//  TwoCents
//
//  Updated to fix duplicate caching issue.
//
import SwiftUI
import CryptoKit

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

struct CacheManager {
    
    // MARK: - Normalize URL to handle variations
    
    /// Normalizes the URL by sorting query parameters and removing unwanted components.
    private static func normalize(url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        // Sort query parameters alphabetically to standardize the URL
        components.queryItems = components.queryItems?.sorted { $0.name < $1.name }
        // Remove specific query parameters if needed (e.g., tracking params)
        // components.queryItems = components.queryItems?.filter { ... }
        return components.url ?? url
    }
    
    // MARK: - Fetch Cached Image URL
    
    static func fetchCachedImageURL(for remoteURL: URL) async throws -> URL {
        let normalizedURL = normalize(url: remoteURL)
        let urlString = normalizedURL.absoluteString
        let hashedName = sha256(urlString)
        let localURL = makeLocalURL(forHashedName: hashedName, fileType: .image)
        
        let localEtagKey = "MediaCacheManager.etag.\(hashedName)"
        let localModKey = "MediaCacheManager.lastModified.\(hashedName)"
        
        let fileExists = FileManager.default.fileExists(atPath: localURL.path)
        
        if fileExists {
            do {
                let (etag, lastMod) = try await fetchHttpHeaders(for: normalizedURL)
                let localEtag = UserDefaults.standard.string(forKey: localEtagKey)
                let localLastMod = UserDefaults.standard.string(forKey: localModKey)
                
                let changed = (etag != nil && etag != localEtag) || (lastMod != nil && lastMod != localLastMod)
                if changed {
                    try? FileManager.default.removeItem(at: localURL)
                }
            } catch {
                print("HEAD request failed:", error)
            }
        }
        
        if !FileManager.default.fileExists(atPath: localURL.path) {
            let (data, response) = try await URLSession.shared.data(from: normalizedURL)
            try data.write(to: localURL)
            
            if let httpResp = response as? HTTPURLResponse {
                let etag = httpResp.value(forHTTPHeaderField: "ETag")
                let lastMod = httpResp.value(forHTTPHeaderField: "Last-Modified")
                UserDefaults.standard.set(etag, forKey: localEtagKey)
                UserDefaults.standard.set(lastMod, forKey: localModKey)
            }
        }
        
        return localURL
    }
    
    // MARK: - Fetch Cached Video URL
    
    static func fetchCachedVideoURL(for remoteURL: URL) async throws -> URL {
        let normalizedURL = normalize(url: remoteURL)
        let urlString = normalizedURL.absoluteString
        let hashedName = sha256(urlString)
        let localURL = makeLocalURL(forHashedName: hashedName, fileType: .video)
        
        let localEtagKey = "MediaCacheManager.etag.video.\(hashedName)"
        let localModKey = "MediaCacheManager.lastModified.video.\(hashedName)"
        
        let fileExists = FileManager.default.fileExists(atPath: localURL.path)
        
        if fileExists {
            do {
                let (etag, lastModified) = try await fetchHttpHeaders(for: normalizedURL)
                let localEtag = UserDefaults.standard.string(forKey: localEtagKey)
                let localLastMod = UserDefaults.standard.string(forKey: localModKey)
                
                let changed = (etag != nil && etag != localEtag) || (lastModified != nil && lastModified != localLastMod)
                if changed {
                    try? FileManager.default.removeItem(at: localURL)
                }
            } catch {
                print("HEAD request failed for video:", error)
            }
        }
        
        if !FileManager.default.fileExists(atPath: localURL.path) {
            let (data, response) = try await URLSession.shared.data(from: normalizedURL)
            try data.write(to: localURL, options: .atomic)
            
            if let httpResp = response as? HTTPURLResponse {
                let etag = httpResp.value(forHTTPHeaderField: "ETag")
                let lastMod = httpResp.value(forHTTPHeaderField: "Last-Modified")
                UserDefaults.standard.set(etag, forKey: localEtagKey)
                UserDefaults.standard.set(lastMod, forKey: localModKey)
            }
        }
        
        return localURL
    }
    
    // MARK: - Helper Methods (Unchanged)
    
    private static func fetchHttpHeaders(for url: URL) async throws -> (etag: String?, lastModified: String?) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return (httpResp.value(forHTTPHeaderField: "ETag"), httpResp.value(forHTTPHeaderField: "Last-Modified"))
    }
    
    private static func makeLocalURL(forHashedName hashedName: String, fileType: FileType) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent("\(hashedName).\(fileType.fileExtension)")
    }
    
    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
