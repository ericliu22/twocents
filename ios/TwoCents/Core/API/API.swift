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
    case custom(String)
    
    var headerValue: String {
        switch self {
        case .json:
            return "application/json"
        case .textPlain:
            return "text/plain"
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
    
}
