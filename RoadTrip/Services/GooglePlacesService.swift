//
//  GooglePlacesService.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation
import CoreLocation

final class GooglePlacesService {
    static let shared = GooglePlacesService()
    
    private let baseURL = "https://maps.googleapis.com/maps/api/place"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = Config.requestTimeout
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Models
    
    struct Place: Codable {
        let placeId: String
        let name: String
        let vicinity: String?
        let geometry: Geometry
        let rating: Double?
        let types: [String]?
        let photos: [Photo]?
        let openingHours: OpeningHours?
        
        struct Geometry: Codable {
            let location: Location
        }
        
        struct Location: Codable {
            let lat: Double
            let lng: Double
        }
        
        struct Photo: Codable {
            let photoReference: String
            let width: Int
            let height: Int
            
            enum CodingKeys: String, CodingKey {
                case photoReference = "photo_reference"
                case width, height
            }
        }
        
        struct OpeningHours: Codable {
            let openNow: Bool?
            
            enum CodingKeys: String, CodingKey {
                case openNow = "open_now"
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case name, vicinity, geometry, rating, types, photos
            case openingHours = "opening_hours"
        }
    }
    
    struct PlaceDetails: Codable {
        let placeId: String
        let name: String
        let formattedAddress: String?
        let geometry: Place.Geometry
        let rating: Double?
        let website: String?
        let phoneNumber: String?
        let openingHours: DetailedOpeningHours?
        let photos: [Place.Photo]?
        let reviews: [Review]?
        let types: [String]?
        
        struct DetailedOpeningHours: Codable {
            let openNow: Bool?
            let weekdayText: [String]?
            
            enum CodingKeys: String, CodingKey {
                case openNow = "open_now"
                case weekdayText = "weekday_text"
            }
        }
        
        struct Review: Codable {
            let authorName: String
            let rating: Int
            let text: String
            let time: Int
            
            enum CodingKeys: String, CodingKey {
                case authorName = "author_name"
                case rating, text, time
            }
        }
        
        enum CodingKeys: String, CodingKey {
            case placeId = "place_id"
            case name
            case formattedAddress = "formatted_address"
            case geometry, rating, website
            case phoneNumber = "formatted_phone_number"
            case openingHours = "opening_hours"
            case photos, reviews, types
        }
    }
    
    private struct NearbySearchResponse: Codable {
        let results: [Place]
        let status: String
        let errorMessage: String?
        
        enum CodingKeys: String, CodingKey {
            case results, status
            case errorMessage = "error_message"
        }
    }
    
    private struct PlaceDetailsResponse: Codable {
        let result: PlaceDetails
        let status: String
        let errorMessage: String?
        
        enum CodingKeys: String, CodingKey {
            case result, status
            case errorMessage = "error_message"
        }
    }
    
    // MARK: - API Methods
    
    func searchNearby(location: CLLocationCoordinate2D,
                     radius: Double = Config.defaultSearchRadius,
                     type: String? = nil,
                     keyword: String? = nil) async throws -> [Place] {
        
        guard Config.hasValidGooglePlacesKey else {
            throw AppError.invalidAPIKey
        }
        
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.networkUnavailable
        }
        
        var components = URLComponents(string: "\(baseURL)/nearbysearch/json")
        var queryItems = [
            URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"),
            URLQueryItem(name: "radius", value: "\(Int(radius))"),
            URLQueryItem(name: "key", value: Config.googlePlacesAPIKey)
        ]
        
        if let type = type {
            queryItems.append(URLQueryItem(name: "type", value: type))
        }
        
        if let keyword = keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        components?.queryItems = queryItems
        
        guard let url = components?.url else {
            throw AppError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AppError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        do {
            let searchResponse = try JSONDecoder().decode(NearbySearchResponse.self, from: data)
            
            switch searchResponse.status {
            case "OK":
                return searchResponse.results
            case "ZERO_RESULTS":
                throw AppError.noResults
            case "INVALID_REQUEST":
                throw AppError.apiError(searchResponse.errorMessage ?? "Invalid request")
            case "REQUEST_DENIED":
                let message = searchResponse.errorMessage ?? "Request denied by Google. Check that Places API is enabled, billing is enabled, and key restrictions allow Web Service calls."
                throw AppError.apiError(message)
            default:
                throw AppError.apiError(searchResponse.errorMessage ?? "Unknown error")
            }
        } catch let error as DecodingError {
            throw AppError.decodingFailed(error)
        }
    }
    
    func getPlaceDetails(placeId: String) async throws -> PlaceDetails {
        guard Config.hasValidGooglePlacesKey else {
            throw AppError.invalidAPIKey
        }
        
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.networkUnavailable
        }
        
        var components = URLComponents(string: "\(baseURL)/details/json")
        components?.queryItems = [
            URLQueryItem(name: "place_id", value: placeId),
            URLQueryItem(name: "key", value: Config.googlePlacesAPIKey),
            URLQueryItem(name: "fields", value: "place_id,name,formatted_address,geometry,rating,website,formatted_phone_number,opening_hours,photos,reviews,types")
        ]
        
        guard let url = components?.url else {
            throw AppError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw AppError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        do {
            let detailsResponse = try JSONDecoder().decode(PlaceDetailsResponse.self, from: data)
            
            switch detailsResponse.status {
            case "OK":
                return detailsResponse.result
            case "NOT_FOUND":
                throw AppError.locationNotFound
            case "INVALID_REQUEST":
                throw AppError.apiError(detailsResponse.errorMessage ?? "Invalid request")
            case "REQUEST_DENIED":
                let message = detailsResponse.errorMessage ?? "Request denied by Google. Check that Places API is enabled, billing is enabled, and key restrictions allow Web Service calls."
                throw AppError.apiError(message)
            default:
                throw AppError.apiError(detailsResponse.errorMessage ?? "Unknown error")
            }
        } catch let error as DecodingError {
            throw AppError.decodingFailed(error)
        }
    }
    
    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> URL? {
        var components = URLComponents(string: "\(baseURL)/photo")
        components?.queryItems = [
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "maxwidth", value: "\(maxWidth)"),
            URLQueryItem(name: "key", value: Config.googlePlacesAPIKey)
        ]
        return components?.url
    }
    
    // MARK: - Retry Logic
    
    func searchNearbyWithRetry(location: CLLocationCoordinate2D,
                              radius: Double = Config.defaultSearchRadius,
                              type: String? = nil,
                              keyword: String? = nil,
                              maxAttempts: Int = Config.maxRetryAttempts) async throws -> [Place] {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await searchNearby(location: location, radius: radius, type: type, keyword: keyword)
            } catch let error as AppError {
                lastError = error
                
                if !error.isRetryable || attempt == maxAttempts {
                    throw error
                }
                
                // Exponential backoff
                let delay = Config.retryDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }
        
        throw lastError ?? AppError.unknown(NSError(domain: "GooglePlacesService", code: -1))
    }
}
