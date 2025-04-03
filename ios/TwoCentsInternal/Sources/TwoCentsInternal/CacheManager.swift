import SwiftUI
import LinkPresentation
import CryptoKit

enum ResourceType {
    case image
    case video
    case linkMetadata
    
    /// File extension (or custom) for each resource type
    var fileExtension: String {
        switch self {
        case .image:        return "jpeg"
        case .video:        return "mp4"
        case .linkMetadata: return "linkmeta"
        }
    }
}

public struct CacheManager {
    
    // MARK: - Public Entry Points
    
    public static func fetchCachedImageURL(for remoteURL: URL) async throws -> URL {
        let (url, didDownload) = try await fetchAndCacheData(for: remoteURL, type: .image)
        return url
    }
    
    public static func fetchCachedVideoURL(for remoteURL: URL) async throws -> URL {
        let (url, didDownload) = try await fetchAndCacheData(for: remoteURL, type: .video)
        return url
    }
    
    public static func fetchCachedLinkMetadata(for remoteURL: URL) async throws -> LPLinkMetadata {
        // 1) See if local file already exists (conditional GET check). If needed, fetch remote.
        // 2) Read the .linkmeta file, unarchive it into LPLinkMetadata.
        let (localFileURL, didDownload) = try await fetchAndCacheData(for: remoteURL, type: .linkMetadata)
        
        // If we had to download it, that means we have fresh data not yet stored
        // But for link metadata, we store the *serialized* object, so let's handle that:
        if didDownload {
            // We just downloaded the resource. In reality, we used `fetchAndCacheData` to store
            // the raw Data from an HTTP request. However, for LPLinkMetadata, we actually want to
            // store the *serialized* LinkPresentation object. So let's fix that now:
            try await storeLPLinkMetadata(remoteURL: remoteURL, fileURL: localFileURL)
        }
        
        // Finally, load from disk
        let data = try Data(contentsOf: localFileURL)
        guard let metadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        return metadata
    }
    
    
    // MARK: - Core Fetch Logic (Conditional GET)
    
    /// Returns (localFileURL, didDownload)
    @discardableResult
    private static func fetchAndCacheData(for remoteURL: URL, type: ResourceType) async throws -> (URL, Bool) {
        let normalizedURL = normalize(url: remoteURL)
        let hashedName   = sha256(normalizedURL.absoluteString)
        let localFileURL = makeLocalURL(forHashedName: hashedName, fileExtension: type.fileExtension)
        
        // Keys for ETag / Last-Modified (use unique prefixes to avoid collisions)
        let etagKey     = "CacheManager.\(type).etag.\(hashedName)"
        let lastModKey  = "CacheManager.\(type).lastModified.\(hashedName)"
        
        let storedEtag  = UserDefaults.standard.string(forKey: etagKey)
        let storedMod   = UserDefaults.standard.string(forKey: lastModKey)
        
        // If the file exists, do a conditional GET to see if it’s still valid
        if FileManager.default.fileExists(atPath: localFileURL.path) {
            let isStillValid = try await checkIfResourceIsStillValid(
                url: normalizedURL,
                etag: storedEtag,
                lastModified: storedMod
            )
            // If the server responded 304, we can skip the download
            if isStillValid {
                return (localFileURL, false) // The cache is valid; no download
            } else {
                // Resource changed on the server; remove the local file
                try? FileManager.default.removeItem(at: localFileURL)
            }
        }
        
        // The file doesn't exist or isn't valid => we download
        let (data, response) = try await fetchResource(url: normalizedURL, etag: storedEtag, lastModified: storedMod)
        try data.write(to: localFileURL, options: .atomic)
        
        // Update ETag / Last-Modified from response headers
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
            let etag    = httpResp.value(forHTTPHeaderField: "ETag")
            let lastMod = httpResp.value(forHTTPHeaderField: "Last-Modified")
            UserDefaults.standard.set(etag, forKey: etagKey)
            UserDefaults.standard.set(lastMod, forKey: lastModKey)
        }
        
        return (localFileURL, true)
    }
    
    
    // MARK: - Link Metadata Archival
    
    /// If we are storing an LPLinkMetadata, we actually want to fetch the LinkPresentation data.
    /// So after the raw data is downloaded, we can re-fetch the real metadata via LPMetadataProvider.
    /// Then we archive it over the raw data file for easy re-load.
    private static func storeLPLinkMetadata(remoteURL: URL, fileURL: URL) async throws {
        let provider = LPMetadataProvider()
        let metadata = try await provider.startFetchingMetadata(for: remoteURL)
        
        let archived = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
        try archived.write(to: fileURL, options: .atomic)
    }
    
    
    // MARK: - HEAD + Conditional GET
    
    /// If we have an ETag or Last-Modified, make a conditional GET with `If-None-Match` or `If-Modified-Since`.
    /// If the server returns 304, then the resource is still valid.
    private static func checkIfResourceIsStillValid(
        url: URL,
        etag: String?,
        lastModified: String?
    ) async throws -> Bool {
        
        // We'll do a short GET request with appropriate headers. If the server replies 304, it's valid.
        // Alternatively, you could do a HEAD request, but we actually want the 304 response if unmodified.
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        if let lastModified = lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResp = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        // 304 => the resource hasn't changed => still valid
        return httpResp.statusCode == 304
    }
    
    /// Simple function to perform the actual data request (could also be merged with checkIfResourceIsStillValid).
    private static func fetchResource(
        url: URL,
        etag: String?,
        lastModified: String?
    ) async throws -> (Data, URLResponse) {
        
        // For the actual fetch, we do a normal GET. If the server sees If-None-Match / If-Modified-Since,
        // it may respond with 304. If so, we'll handle that in checkIfResourceIsStillValid.
        // Here, if we get 304, we might throw or handle it differently.
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Not strictly necessary for the "full GET" path, but including them can unify logic:
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        if let lastModified = lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        
        return try await URLSession.shared.data(for: request)
    }
    
    
    // MARK: - URL Normalization + Hashing
    
    /// Normalizes the URL by sorting query parameters and removing any unnecessary components (as needed).
    private static func normalize(url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.queryItems = components.queryItems?.sorted { $0.name < $1.name }
        // Optionally remove known tracking params, e.g., UTM:
        // components.queryItems = components.queryItems?.filter { !["utm_source", "utm_medium"].contains($0.name) }
        return components.url ?? url
    }
    
    /// Creates a local path in the cache directory for a hashed filename + extension
    private static func makeLocalURL(forHashedName name: String, fileExtension: String) -> URL {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDir.appendingPathComponent("\(name).\(fileExtension)")
    }
    
    /// Hash the normalized URL to produce a unique filename
    private static func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
