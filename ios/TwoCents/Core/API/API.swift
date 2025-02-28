//
//  API.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import Foundation

let API_URL: URL = URL(string: "https://api.twocentsapp.com/v1/")!

enum APIError: Error {
    case invalidResponse
    case unexpectedStatusCode(Int)
    case noData
}

enum HTTPMethod: String, RawRepresentable, Equatable, Hashable {
    case GET
    case POST
    case PUT
    case DELETE
    case PATCH
    case CONNECT
    case HEAD
    case OPTIONS
    case QUERY
    case TRACE
}

//We really don't care any other content types besides the following
enum ContentType {
    case json
    case textPlain
    case imgJpeg
    case videoMp4
    case custom(String)
    
    var headerValue: String {
        switch self {
        case .json:
            return "application/json"
        case .textPlain:
            return "text/plain"
        case .imgJpeg:
            return "image/jpeg"
        case .videoMp4:
            return "video/mp4"
        case .custom(let value):
            return value
        }
    }
}

struct Request<T: Encodable> {
    let method: HTTPMethod
    let contentType: ContentType
    let url: URL
    let headers: [String: String]?
    let body: T?
    
    /// Designated initializer with optional headers/body
    init(
        method: HTTPMethod,
        contentType: ContentType,
        url: URL,
        headers: [String: String]? = nil,
        body: T? = nil
    ) {
        self.method = method
        self.contentType = contentType
        self.url = url
        self.headers = headers
        self.body = body
    }
    
    func asURLRequest() async throws -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        
        request.setValue(contentType.headerValue, forHTTPHeaderField: "Content-Type")
        let firebaseToken = try await AuthenticationManager.getJwtToken()
        request.setValue("Bearer \(firebaseToken)", forHTTPHeaderField: "Authorization")

        // Set any additional headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Attach body if present
        let bodyData = try? JSONEncoder().encode(body)
        request.httpBody = bodyData
        
        return request
    }
    
    func sendRequest() async throws -> Data {
        let urlRequest = try await self.asURLRequest()
        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            print(data)
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print(data)
            throw APIError.unexpectedStatusCode(httpResponse.statusCode)
        }
        
        if data.isEmpty {
            print(data)
            throw APIError.noData
        }
        
        return data
    }
    
    static func uploadMedia(fileData: Data, fileName: String, mimeType: String, url: URL, boundary: UUID) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Start boundary
        body.append("--\(boundary)\r\n")
        // Content-Disposition header; "file" is the key expected by the server
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n")
        // Content-Type header
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        // Append the actual file data
        body.append(fileData)
        body.append("\r\n")
        // End boundary
        body.append("--\(boundary)--\r\n")
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            print(response)
            print(data)
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            print(response)
            print(data)
            throw APIError.unexpectedStatusCode(httpResponse.statusCode)
        }
        
        if data.isEmpty {
            print(response)
            print(data)
            throw APIError.noData
        }
        return data
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
