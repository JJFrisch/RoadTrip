//
//  AuthTokenStore.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

enum TokenRefreshError: Error {
    case refreshNotConfigured
    case missingRefreshToken
    case invalidRefreshResponse
}

final class AuthTokenStore: MutableAuthTokenProviding, TokenRefreshProviding {
    static let shared = AuthTokenStore()

    private let defaults = UserDefaults.standard
    private let accessTokenKey = "roadtrip.auth.accessToken"
    private let refreshTokenKey = "roadtrip.auth.refreshToken"
    private let accessTokenExpiryKey = "roadtrip.auth.accessTokenExpiry"
    private var refreshEndpoint: URL {
        if let value = Bundle.main.object(forInfoDictionaryKey: "AUTH_REFRESH_ENDPOINT") as? String,
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        if let value = ProcessInfo.processInfo.environment["AUTH_REFRESH_ENDPOINT"],
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        return APIEnvironment.development.baseURL.appendingPathComponent("auth/refresh")
    }

    // Optional runtime hook for real refresh integration.
    var refreshHandler: (() async throws -> String)?

    private init() {
        refreshHandler = { [weak self] in
            guard let self else {
                throw TokenRefreshError.refreshNotConfigured
            }
            return try await self.requestAccessTokenRefresh()
        }
    }

    var accessToken: String? {
        defaults.string(forKey: accessTokenKey)
    }

    var refreshToken: String? {
        defaults.string(forKey: refreshTokenKey)
    }

    var accessTokenExpiry: Date? {
        defaults.object(forKey: accessTokenExpiryKey) as? Date
    }

    var isAccessTokenExpired: Bool {
        guard let expiry = accessTokenExpiry else { return true }
        return expiry <= Date()
    }

    func updateAccessToken(_ token: String?) {
        defaults.set(token, forKey: accessTokenKey)
    }

    func updateAccessTokenExpiry(_ expiry: Date?) {
        defaults.set(expiry, forKey: accessTokenExpiryKey)
    }

    func setTokens(accessToken: String?, refreshToken: String?, accessTokenExpiry: Date? = nil) {
        defaults.set(accessToken, forKey: accessTokenKey)
        defaults.set(refreshToken, forKey: refreshTokenKey)
        defaults.set(accessTokenExpiry, forKey: accessTokenExpiryKey)
    }

    func refreshAccessToken() async throws -> String {
        guard let refreshHandler else {
            throw TokenRefreshError.refreshNotConfigured
        }

        let newToken = try await refreshHandler()
        updateAccessToken(newToken)
        return newToken
    }

    private struct RefreshRequest: Encodable {
        let refreshToken: String
    }

    private struct RefreshResponse: Decodable {
        let accessToken: String
        let refreshToken: String?
        let expiresIn: Int?
        let expiresAt: Date?

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case refreshToken = "refresh_token"
            case expiresIn = "expires_in"
            case expiresAt = "expires_at"
        }
    }

    private func requestAccessTokenRefresh() async throws -> String {
        guard let refreshToken, !refreshToken.isEmpty else {
            throw TokenRefreshError.missingRefreshToken
        }

        var request = URLRequest(url: refreshEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(RefreshRequest(refreshToken: refreshToken))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode) else {
            throw TokenRefreshError.invalidRefreshResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(RefreshResponse.self, from: data)

        let expiry: Date?
        if let expiresAt = decoded.expiresAt {
            expiry = expiresAt
        } else if let expiresIn = decoded.expiresIn {
            expiry = Date().addingTimeInterval(TimeInterval(expiresIn))
        } else {
            expiry = nil
        }

        setTokens(
            accessToken: decoded.accessToken,
            refreshToken: decoded.refreshToken ?? refreshToken,
            accessTokenExpiry: expiry
        )

        return decoded.accessToken
    }
}
