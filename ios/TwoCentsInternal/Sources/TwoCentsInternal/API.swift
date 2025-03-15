//
//  API.swift
//  TwoCents
//
//  Created by Eric Liu on 2025/2/26.
//

import Foundation

public let API_URL: URL = URL(string: "https://api.twocentsapp.com/v1/")!

public enum APIError: Error {
    case invalidResponse
    case unexpectedStatusCode(Int)
    case noData
    
}

public enum HTTPMethod: String, RawRepresentable, Equatable, Hashable {
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
public enum ContentType {
    case json
    case textPlain
    case imgJpeg
    case videoMp4
    case multipart(String)
    case custom(String)
    
    var headerValue: String {
        switch self {
        case .json:
            return "application/json"
        case .textPlain:
            return "text/plain"
        case .imgJpeg:
            return "image/jpeg"
        case .multipart(let boundary):
            return "multipart/form-data; boundary=\(boundary)"
        case .videoMp4:
            return "video/mp4"
        case .custom(let value):
            return value
        }
    }
}

public struct Request<T: Encodable> {
    public let method: HTTPMethod
    public let contentType: ContentType
    public let url: URL
    public let headers: [String: String]?
    public let body: T?
    
    /// Designated initializer with optional headers/body
    public init(
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
    
    public func asURLRequest() async throws -> URLRequest {
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
        if method != .GET {
            let bodyData = try? TwoCentsEncoder().encode(body)
            request.httpBody = bodyData
        }
        
        return request
    }
    
    public func sendRequest() async throws -> Data {
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
    
    public static func uploadMedia(post: Post, fileData: Data, mimeType: String, url: URL) async throws -> Data {
        //We use a boundary because we don't want any part of the image data to contain said boundary or else it escapes early -Eric
        let boundary: UUID = UUID()
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let firebaseToken = try await AuthenticationManager.getJwtToken()
        request.setValue("Bearer \(firebaseToken)", forHTTPHeaderField: "Authorization")

        var body = Data()
        let postData = try TwoCentsEncoder().encode(post)
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"post\"\r\n")
        body.append("Content-Type: application/json\r\n\r\n")
        body.append(postData)
        body.append("\r\n")
        
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"myimage.jpg\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileData)
        body.append("\r\n")
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

public extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

public func TwoCentsEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"  // Adjust based on your pgtype.Date format
    encoder.dateEncodingStrategy = .formatted(dateFormatter)
    return encoder
}

public func TwoCentsDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"  // Adjust based on your pgtype.Date format
    decoder.dateDecodingStrategy = .formatted(dateFormatter)
    return decoder
}
