//
//  GeocodingService.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation
import CoreLocation

class GeocodingService {
    static let shared = GeocodingService()
    
    private let geocoder = CLGeocoder()
    private var cache: [String: CLLocationCoordinate2D] = [:]
    
    private init() {}
    
    // MARK: - Geocode Location String to Coordinates
    func geocode(location: String) async throws -> CLLocationCoordinate2D {
        // Check cache first
        let cacheKey = location.lowercased().trimmingCharacters(in: .whitespaces)
        if let cached = cache[cacheKey] {
            print("📍 Using cached coordinates for \(location)")
            return cached
        }
        
        print("🌍 Geocoding location: \(location)")
        
        // Perform geocoding
        let placemarks = try await geocoder.geocodeAddressString(location)
        
        guard let placemark = placemarks.first,
              let location = placemark.location else {
            throw GeocodingError.noResults
        }
        
        let coordinate = location.coordinate
        
        // Cache the result
        cache[cacheKey] = coordinate
        
        print("✅ Geocoded \(location) to: \(coordinate.latitude), \(coordinate.longitude)")
        
        return coordinate
    }
    
    // MARK: - Reverse Geocode (Coordinates to Location)
    func reverseGeocode(latitude: Double, longitude: Double) async throws -> String {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        
        guard let placemark = placemarks.first else {
            throw GeocodingError.noResults
        }
        
        // Build location string from placemark
        var components: [String] = []
        
        if let locality = placemark.locality {
            components.append(locality)
        }
        
        if let administrativeArea = placemark.administrativeArea {
            components.append(administrativeArea)
        }
        
        if let country = placemark.country {
            components.append(country)
        }
        
        return components.joined(separator: ", ")
    }
    
    // MARK: - Get City Name
    func getCityName(from location: String) async throws -> String {
        let placemarks = try await geocoder.geocodeAddressString(location)
        
        guard let placemark = placemarks.first else {
            throw GeocodingError.noResults
        }
        
        return placemark.locality ?? location
    }
    
    // MARK: - Clear Cache
    func clearCache() {
        cache.removeAll()
        print("🗑️ Geocoding cache cleared")
    }
}

// MARK: - Geocoding Errors
enum GeocodingError: LocalizedError {
    case noResults
    case networkError
    case invalidLocation
    
    var errorDescription: String? {
        switch self {
        case .noResults:
            return "No location found for the given address"
        case .networkError:
            return "Network error while geocoding"
        case .invalidLocation:
            return "Invalid location format"
        }
    }
}
