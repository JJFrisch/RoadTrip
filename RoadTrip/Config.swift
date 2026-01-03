//
//  Config.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation

struct Config {
    // MARK: - API Keys
    
    /// Google Places API Key - Add your key here or in Info.plist
    /// Get your key at: https://developers.google.com/maps/documentation/places/web-service/get-api-key
    static var googlePlacesAPIKey: String {
        // First try to read from Info.plist (recommended for security)
        if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_PLACES_API_KEY") as? String, !key.isEmpty {
            return key
        }
        
        // Fallback to environment variable
        if let key = ProcessInfo.processInfo.environment["GOOGLE_PLACES_API_KEY"], !key.isEmpty {
            return key
        }
        
        // Development fallback - Replace with your key for testing
        // WARNING: Never commit real API keys to version control!
        return "YOUR_API_KEY_HERE"
    }
    
    /// Mapbox Access Token - Add your token here or in Info.plist
    /// Get your token at: https://account.mapbox.com/access-tokens/
    static var mapboxAccessToken: String {
        if let token = Bundle.main.object(forInfoDictionaryKey: "MAPBOX_ACCESS_TOKEN") as? String, !token.isEmpty {
            return token
        }
        
        if let token = ProcessInfo.processInfo.environment["MAPBOX_ACCESS_TOKEN"], !token.isEmpty {
            return token
        }
        
        return "YOUR_MAPBOX_TOKEN_HERE"
    }
    
    // MARK: - Configuration
    
    static let maxCachedLocations = 200
    static let defaultSearchRadius = 2000.0 // meters
    static let requestTimeout: TimeInterval = 30.0
    static let maxRetryAttempts = 3
    static let retryDelay: TimeInterval = 1.0
    
    // MARK: - Validation
    
    static var hasValidGooglePlacesKey: Bool {
        !googlePlacesAPIKey.isEmpty && googlePlacesAPIKey != "YOUR_API_KEY_HERE"
    }
    
    static var hasValidMapboxToken: Bool {
        !mapboxAccessToken.isEmpty && mapboxAccessToken != "YOUR_MAPBOX_TOKEN_HERE"
    }
}
