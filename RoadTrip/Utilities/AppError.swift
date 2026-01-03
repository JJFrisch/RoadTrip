//
//  AppError.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation

enum AppError: LocalizedError {
    case networkUnavailable
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case decodingFailed(Error)
    case apiError(String)
    case locationNotFound
    case noResults
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network and try again."
        case .invalidAPIKey:
            return "Invalid API key. Please check your configuration."
        case .invalidURL:
            return "Invalid URL format."
        case .invalidResponse:
            return "Invalid response from server."
        case .decodingFailed(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        case .apiError(let message):
            return message
        case .locationNotFound:
            return "Location not found. Please check the address and try again."
        case .noResults:
            return "No results found. Try adjusting your search criteria."
        case .timeout:
            return "Request timed out. Please try again."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case .invalidAPIKey:
            return "Contact support or check your API key configuration."
        case .locationNotFound:
            return "Try using a different address or location name."
        case .noResults:
            return "Try expanding your search radius or changing your search terms."
        case .timeout:
            return "Your connection may be slow. Try again or check your network."
        default:
            return "Please try again. If the problem persists, contact support."
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout, .invalidResponse:
            return true
        default:
            return false
        }
    }
}

// MARK: - Error Handler

final class ErrorHandler: ObservableObject {
    @Published var currentError: AppError?
    @Published var showingError = false
    
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handle(_ error: Error) {
        DispatchQueue.main.async {
            if let appError = error as? AppError {
                self.currentError = appError
            } else if let urlError = error as? URLError {
                self.currentError = self.mapURLError(urlError)
            } else {
                self.currentError = .unknown(error)
            }
            self.showingError = true
        }
    }
    
    func handle(_ appError: AppError) {
        DispatchQueue.main.async {
            self.currentError = appError
            self.showingError = true
        }
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.showingError = false
        }
    }
    
    private func mapURLError(_ error: URLError) -> AppError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .networkUnavailable
        case .timedOut:
            return .timeout
        default:
            return .unknown(error)
        }
    }
}
