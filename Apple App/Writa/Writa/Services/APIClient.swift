//
//  APIClient.swift
//  Writa
//
//  HTTP client for communicating with the Writa API.
//  Handles authentication, request/response encoding, and error handling.
//

import Foundation
import SwiftUI

// MARK: - API Configuration

struct APIConfiguration {
    /// Base URL for the API
    /// Development: http://localhost:8787
    /// Production: https://writa-api.joshua-orr.workers.dev
    static var baseURL: String {
        // Always use production for now
        // To test locally, run: cd api && npm run dev
        // Then uncomment the localhost line
        // return "http://localhost:8787"
        return "https://writa-api.joshua-orr.workers.dev"
    }
    
    /// API version prefix
    static let apiVersion = "/api"
    
    /// Request timeout in seconds
    static let timeout: TimeInterval = 30
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case httpError(statusCode: Int, message: String?)
    case networkError(Error)
    case unauthorized
    case notFound
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "HTTP error \(code): \(message ?? "Unknown error")"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Authentication required"
        case .notFound:
            return "Resource not found"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API Client

@Observable
class APIClient {
    /// Shared singleton instance
    static let shared = APIClient()
    
    /// Auth manager for getting tokens
    var authManager: AuthManager?
    
    /// URLSession for requests
    private let session: URLSession
    
    /// JSON encoder for requests
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }()
    
    /// JSON decoder for responses
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = APIConfiguration.timeout
        config.timeoutIntervalForResource = APIConfiguration.timeout * 2
        self.session = URLSession(configuration: config)
    }
    
    /// Configure with auth manager
    func configure(with authManager: AuthManager) {
        self.authManager = authManager
    }
    
    // MARK: - Request Methods
    
    /// Make a GET request
    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        return try await request(path, method: .get, queryItems: queryItems)
    }
    
    /// Make a POST request with body
    func post<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        return try await request(path, method: .post, body: body)
    }
    
    /// Make a POST request without body
    func post<T: Decodable>(_ path: String) async throws -> T {
        return try await request(path, method: .post)
    }
    
    /// Make a PUT request
    func put<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        return try await request(path, method: .put, body: body)
    }
    
    /// Make a PATCH request
    func patch<T: Decodable, B: Encodable>(_ path: String, body: B) async throws -> T {
        return try await request(path, method: .patch, body: body)
    }
    
    /// Make a DELETE request
    func delete<T: Decodable>(_ path: String) async throws -> T {
        return try await request(path, method: .delete)
    }
    
    /// Make a DELETE request without response
    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request(path, method: .delete)
    }
    
    // MARK: - Core Request
    
    private func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem]? = nil,
        body: (any Encodable)? = nil
    ) async throws -> T {
        // Build URL
        var urlComponents = URLComponents(string: APIConfiguration.baseURL + APIConfiguration.apiVersion + path)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw APIError.invalidURL
        }
        
        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add auth token
        if let authManager = authManager {
            do {
                let token = try await authManager.getAuthToken()
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            } catch {
                throw APIError.unauthorized
            }
        }
        
        // Encode body
        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingError(error)
            }
        }
        
        // Log request (debug)
        #if DEBUG
        print("🌐 \(method.rawValue) \(url.absoluteString)")
        #endif
        
        // Make request
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
        
        // Check response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.noData
        }
        
        // Log response (debug)
        #if DEBUG
        print("📥 Status: \(httpResponse.statusCode), Size: \(data.count) bytes")
        #endif
        
        // Handle status codes
        switch httpResponse.statusCode {
        case 200...299:
            // Success
            break
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 400...499:
            let message = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: message?.error)
        case 500...599:
            // Log full error response for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Server error response: \(errorString)")
            }
            let message = try? decoder.decode(ErrorResponse.self, from: data)
            throw APIError.serverError(message?.error ?? "Internal server error")
        default:
            throw APIError.httpError(statusCode: httpResponse.statusCode, message: nil)
        }
        
        // Decode response
        do {
            // Handle empty responses
            if data.isEmpty || T.self == EmptyResponse.self {
                return EmptyResponse() as! T
            }
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            if let json = String(data: data, encoding: .utf8) {
                print("❌ Decoding error. Response: \(json)")
            }
            #endif
            throw APIError.decodingError(error)
        }
    }
    
    // MARK: - File Upload
    
    /// Upload a file
    func uploadFile(data: Data, mimeType: String, filename: String) async throws -> UploadResponse {
        let path = "/upload"
        
        guard let url = URL(string: APIConfiguration.baseURL + APIConfiguration.apiVersion + path) else {
            throw APIError.invalidURL
        }
        
        // Build multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Add auth token
        if let authManager = authManager {
            let token = try await authManager.getAuthToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Build body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (responseData, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0, message: nil)
        }
        
        return try decoder.decode(UploadResponse.self, from: responseData)
    }
}

// MARK: - Helper Types

/// Empty response for void returns
struct EmptyResponse: Codable {}

/// Error response from API
struct ErrorResponse: Codable {
    let error: String
    let details: String?
    let stack: String?
}

/// Upload response
struct UploadResponse: Codable {
    let success: Bool
    let key: String
    let url: String
    let contentType: String
    let size: Int
}

/// Type-erased Encodable wrapper
struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void
    
    init<T: Encodable>(_ wrapped: T) {
        self.encode = wrapped.encode
    }
    
    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

// MARK: - Environment Key

private struct APIClientKey: EnvironmentKey {
    static let defaultValue = APIClient.shared
}

extension EnvironmentValues {
    var apiClient: APIClient {
        get { self[APIClientKey.self] }
        set { self[APIClientKey.self] = newValue }
    }
}
