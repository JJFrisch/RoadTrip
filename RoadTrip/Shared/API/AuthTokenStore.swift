//
//  AuthTokenStore.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

enum TokenRefreshError: Error {
    case refreshNotConfigured
}

final class AuthTokenStore: MutableAuthTokenProviding, TokenRefreshProviding {
    static let shared = AuthTokenStore()

    private let defaults = UserDefaults.standard
    private let accessTokenKey = "roadtrip.auth.accessToken"
    private let refreshTokenKey = "roadtrip.auth.refreshToken"

    // Optional runtime hook for real refresh integration.
    var refreshHandler: (() async throws -> String)?

    private init() {}

    var accessToken: String? {
        defaults.string(forKey: accessTokenKey)
    }

    var refreshToken: String? {
        defaults.string(forKey: refreshTokenKey)
    }

    func updateAccessToken(_ token: String?) {
        defaults.set(token, forKey: accessTokenKey)
    }

    func setTokens(accessToken: String?, refreshToken: String?) {
        defaults.set(accessToken, forKey: accessTokenKey)
        defaults.set(refreshToken, forKey: refreshTokenKey)
    }

    func refreshAccessToken() async throws -> String {
        guard let refreshHandler else {
            throw TokenRefreshError.refreshNotConfigured
        }

        let newToken = try await refreshHandler()
        updateAccessToken(newToken)
        return newToken
    }
}
