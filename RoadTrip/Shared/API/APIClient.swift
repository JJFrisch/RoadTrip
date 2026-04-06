//
//  APIClient.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

protocol AuthTokenProviding {
    var accessToken: String? { get }
}

enum APIClientError: Error {
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int, body: String?)
    case decoding(Error)
    case transport(Error)
}

protocol APIClient {
    func send<Response: Decodable>(_ endpoint: APIEndpoint<Response>) async throws -> Response
    func send(_ endpoint: APIEndpoint<EmptyResponse>) async throws
}

struct EmptyResponse: Decodable {}

final class URLSessionAPIClient: APIClient {
    private let baseURL: URL
    private let session: URLSession
    private let tokenProvider: AuthTokenProviding?
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        tokenProvider: AuthTokenProviding? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider

        let configuredDecoder = decoder
        configuredDecoder.dateDecodingStrategy = .iso8601
        self.decoder = configuredDecoder
    }

    func send<Response: Decodable>(_ endpoint: APIEndpoint<Response>) async throws -> Response {
        let request = try makeRequest(for: endpoint)

        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)

            do {
                return try decoder.decode(Response.self, from: data)
            } catch {
                throw APIClientError.decoding(error)
            }
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.transport(error)
        }
    }

    func send(_ endpoint: APIEndpoint<EmptyResponse>) async throws {
        let request = try makeRequest(for: endpoint)

        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)
        } catch let error as APIClientError {
            throw error
        } catch {
            throw APIClientError.transport(error)
        }
    }

    private func makeRequest<Response>(for endpoint: APIEndpoint<Response>) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(endpoint.path), resolvingAgainstBaseURL: false) else {
            throw APIClientError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let url = components.url else {
            throw APIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if endpoint.body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        if let token = tokenProvider?.accessToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        endpoint.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = endpoint.body
        return request
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIClientError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let bodyString = String(data: data, encoding: .utf8)
            throw APIClientError.serverError(statusCode: httpResponse.statusCode, body: bodyString)
        }
    }
}
