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

protocol MutableAuthTokenProviding: AuthTokenProviding {
    func updateAccessToken(_ token: String?)
}

protocol TokenRefreshProviding {
    func refreshAccessToken() async throws -> String
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
    private let tokenRefresher: TokenRefreshProviding?
    private let decoder: JSONDecoder
    private let maxRetryAttempts: Int
    private let retryBaseDelay: TimeInterval

    init(
        baseURL: URL,
        session: URLSession = .shared,
        tokenProvider: AuthTokenProviding? = nil,
        tokenRefresher: TokenRefreshProviding? = nil,
        maxRetryAttempts: Int = 2,
        retryBaseDelay: TimeInterval = 0.5,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.tokenProvider = tokenProvider
        self.tokenRefresher = tokenRefresher
        self.maxRetryAttempts = max(0, maxRetryAttempts)
        self.retryBaseDelay = max(0.1, retryBaseDelay)

        let configuredDecoder = decoder
        configuredDecoder.dateDecodingStrategy = .iso8601
        self.decoder = configuredDecoder
    }

    func send<Response: Decodable>(_ endpoint: APIEndpoint<Response>) async throws -> Response {
        let data = try await execute(endpoint)
        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw APIClientError.decoding(error)
        }
    }

    func send(_ endpoint: APIEndpoint<EmptyResponse>) async throws {
        _ = try await execute(endpoint)
    }

    private func execute<Response>(_ endpoint: APIEndpoint<Response>) async throws -> Data {
        var attempt = 0
        var didRefreshToken = false

        while true {
            let request = try makeRequest(for: endpoint)

            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIClientError.invalidResponse
                }

                if httpResponse.statusCode == 401,
                   !didRefreshToken,
                   let tokenRefresher {
                    let refreshedToken = try await tokenRefresher.refreshAccessToken()
                    if let mutableTokenProvider = tokenProvider as? MutableAuthTokenProviding {
                        mutableTokenProvider.updateAccessToken(refreshedToken)
                    }
                    didRefreshToken = true
                    continue
                }

                if shouldRetry(statusCode: httpResponse.statusCode), attempt < maxRetryAttempts {
                    attempt += 1
                    try await Task.sleep(nanoseconds: backoffDelayNanoseconds(forAttempt: attempt))
                    continue
                }

                try validate(statusCode: httpResponse.statusCode, data: data)
                return data

            } catch let error as APIClientError {
                if shouldRetry(error: error), attempt < maxRetryAttempts {
                    attempt += 1
                    try await Task.sleep(nanoseconds: backoffDelayNanoseconds(forAttempt: attempt))
                    continue
                }
                throw error
            } catch {
                if attempt < maxRetryAttempts {
                    attempt += 1
                    try await Task.sleep(nanoseconds: backoffDelayNanoseconds(forAttempt: attempt))
                    continue
                }
                throw APIClientError.transport(error)
            }
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

    private func validate(statusCode: Int, data: Data) throws {
        guard (200...299).contains(statusCode) else {
            let bodyString = String(data: data, encoding: .utf8)
            throw APIClientError.serverError(statusCode: statusCode, body: bodyString)
        }
    }

    private func shouldRetry(statusCode: Int) -> Bool {
        statusCode == 429 || (500...599).contains(statusCode)
    }

    private func shouldRetry(error: APIClientError) -> Bool {
        switch error {
        case .transport:
            return true
        case .serverError(let statusCode, _):
            return shouldRetry(statusCode: statusCode)
        default:
            return false
        }
    }

    private func backoffDelayNanoseconds(forAttempt attempt: Int) -> UInt64 {
        let seconds = retryBaseDelay * pow(2, Double(max(attempt - 1, 0)))
        return UInt64(seconds * 1_000_000_000)
    }
}
