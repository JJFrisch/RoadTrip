//
//  APIEndpoint.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint<Response: Decodable> {
    var path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem] = []
    var headers: [String: String] = [:]
    var body: Data?
}

enum APIEnvironment {
    case development
    case staging
    case production

    var baseURL: URL {
        switch self {
        case .development:
            return URL(string: "http://localhost:3000/v1")!
        case .staging:
            return URL(string: "https://staging-api.roadtrip.app/v1")!
        case .production:
            return URL(string: "https://api.roadtrip.app/v1")!
        }
    }
}
