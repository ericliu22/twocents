//
//  PostManager.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/27.
//

import Foundation

public struct PostRequest: Encodable {
    public let media: Media
    public let caption: String?
    public let groups: [UUID]
    
    public init(media: Media, caption: String? = nil, groups: [UUID]) {
        self.media = media
        self.caption = caption
        self.groups = groups
    }
}
/// What you actually attach to the multipart request *besides* the
/// mandatory `"post"` JSON part.
public enum PostPayload {
    /// IMAGE, VIDEO, OTHER – raw bytes + mime + file name
    case file(data: Data, mimeType: String, filename: String)

    /// TEXT, LINK – arbitrary JSON blob (encoded separately)
    case json(Data)

    /// No secondary part (rare, but keeps the switch exhaustive)
    case none
}


//CanvasWidget: Post
//Media: Image

public struct PostManager: Sendable {
    
    private init() {}
    
    public static let POST_URL: URL = API_URL.appending(path: "post")
    
    /// Single call → single request → post *and* media are created.
    ///
    /// - Parameters:
    ///   - request: metadata for the post (`media`, `caption`, `groups`)
    ///   - payload: secondary part (file or JSON) that depends on `media`
    ///
    /// - Returns: the `Post` row created by the backend.
    public static func createPostMultipart(
        request: PostRequest,
        payload: PostPayload
    ) async throws -> Post {

        let boundary = "Boundary-\(UUID().uuidString)"
        var urlRequest = URLRequest(url: POST_URL.appending(path: "create-post"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        let jwt = try await AuthenticationManager.getJwtToken()
        urlRequest.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")

        // ---------- Build body ----------
        var body = Data()

        // 1. the mandatory `"post"` part
        let postJSON = try TwoCentsEncoder().encode(request)
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"post\"\r\n")
        body.append("Content-Type: application/json\r\n\r\n")
        body.append(postJSON)
        body.append("\r\n")

        // 2. the media‑specific part (if any)
        switch payload {
        case .file(let data, let mime, let filename):
            body.append("--\(boundary)\r\n")
            body.append(
                "Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n"
            )
            body.append("Content-Type: \(mime)\r\n\r\n")
            body.append(data)
            body.append("\r\n")

        case .json(let json):
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"data\"\r\n")
            body.append("Content-Type: application/json\r\n\r\n")
            body.append(json)
            body.append("\r\n")

        case .none:
            break
        }

        body.append("--\(boundary)--\r\n")
        urlRequest.httpBody = body
        // ---------------------------------

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard
            let http = response as? HTTPURLResponse,
            http.statusCode == 200
        else {
            throw APIError.unexpectedStatusCode(
                (response as? HTTPURLResponse)?.statusCode ?? -1
            )
        }
        return try TwoCentsDecoder().decode(Post.self, from: data)
    }
    
    public static func uploadPost(postRequest: PostRequest) async throws -> Post {
        let request: Request = Request(
            method: .POST,
            contentType: .json,
            url: POST_URL.appending(path: "create-post"),
            body: postRequest)
    
        let data = try await request.sendRequest()
        return try TwoCentsDecoder().decode(Post.self, from: data)
    }
    
    public static func uploadPostMedia(post: Post, data: Data) async throws -> Data {
        //The media
        let uploadPost: any Uploadable = makeUploadable(post: post, data: data)
        //The downloadable
        let data: Data = try await uploadPost.uploadPost()
        return data
    }
    
    
    public static func getGroupPosts(groupId: UUID, limit: Int = 10, offset: UUID? = nil) async throws -> Data {
        let baseURL = POST_URL.appendingPathComponent("get-group-posts")
        var queryItems = [
            URLQueryItem(name: "groupId", value: groupId.uuidString),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        if let offset = offset {
            queryItems.append(URLQueryItem(name: "offset", value: offset.uuidString))
        }
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            print("failed to construct url")
            throw URLError(.badURL)
        }
        
        let request = Request<String>(
            method: .GET,
            contentType: .textPlain,
            url: finalURL
        )
        return try await request.sendRequest()
    }
    
    public static func getTopPost(groupId: UUID) async throws -> Data {
        let baseURL = POST_URL.appendingPathComponent("get-top-post")
        let queryItems = [
            URLQueryItem(name: "groupId", value: groupId.uuidString),
        ]
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems
        
        guard let finalURL = components.url else {
            print("failed to construct url")
            throw URLError(.badURL)
        }
        
        let request = Request<String>(
            method: .GET,
            contentType: .textPlain,
            url: finalURL
        )
        return try await request.sendRequest()
    }


    public static func getMedia(post: Post) async throws -> Data {
        let baseURL = POST_URL.appendingPathComponent("get-media")
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "postId", value: post.id.uuidString),
            URLQueryItem(name: "media", value: post.media.rawValue)
        ]
        guard let finalURL = components.url else {
            print("failed to construct url")
            throw URLError.init(URLError.Code(rawValue: 404))
        }
        let request: Request = Request<String> (
            method: .GET,
            contentType: .json,
            url: finalURL
        )
        return try await request.sendRequest()
    }
}
