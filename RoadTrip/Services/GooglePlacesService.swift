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
    
    private let v1BaseURL = "https://places.googleapis.com/v1"
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
        let editorialSummary: String?
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
            case editorialSummary = "editorial_summary"
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

    // MARK: - Places API (New) v1 Models

    private struct GoogleErrorEnvelope: Codable {
        let error: GoogleAPIError
    }

    private struct GoogleAPIError: Codable {
        let code: Int?
        let message: String?
        let status: String?
    }

    private struct V1LatLng: Codable {
        let latitude: Double
        let longitude: Double
    }

    private struct V1LocalizedText: Codable {
        let text: String?
    }

    private struct V1Photo: Codable {
        let name: String
        let widthPx: Int?
        let heightPx: Int?
    }

    private struct V1RegularOpeningHours: Codable {
        let openNow: Bool?
        let weekdayDescriptions: [String]?
    }

    private struct V1Place: Codable {
        let id: String?
        let displayName: V1LocalizedText?
        let editorialSummary: V1LocalizedText?
        let formattedAddress: String?
        let location: V1LatLng?
        let rating: Double?
        let userRatingCount: Int?
        let types: [String]?
        let photos: [V1Photo]?
        let regularOpeningHours: V1RegularOpeningHours?
        let websiteUri: String?
        let internationalPhoneNumber: String?
    }

    private struct V1SearchNearbyRequest: Codable {
        let includedTypes: [String]?
        let locationRestriction: V1LocationRestriction
        let maxResultCount: Int?
    }

    private struct V1LocationRestriction: Codable {
        let circle: V1Circle
    }

    private struct V1Circle: Codable {
        let center: V1LatLng
        let radius: Double
    }

    private struct V1SearchNearbyResponse: Codable {
        let places: [V1Place]?
    }

    private struct V1SearchTextRequest: Codable {
        let textQuery: String
        let includedType: String?
        let locationBias: V1LocationBias?
        let maxResultCount: Int?
    }

    private struct V1LocationBias: Codable {
        let circle: V1Circle
    }

    private struct V1SearchTextResponse: Codable {
        let places: [V1Place]?
    }

    // MARK: - Helpers

    private func makeV1Request(url: URL, method: String, fieldMask: String, body: Data? = nil) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue(Config.googlePlacesAPIKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue(fieldMask, forHTTPHeaderField: "X-Goog-FieldMask")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func decodeGoogleAPIErrorMessage(from data: Data) -> String? {
        if let envelope = try? JSONDecoder().decode(GoogleErrorEnvelope.self, from: data) {
            return envelope.error.message
        }
        if let text = String(data: data, encoding: .utf8), !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return text
        }
        return nil
    }

    private func mapV1PlaceToLegacyPlace(_ place: V1Place) -> Place? {
        guard let placeId = place.id,
              let location = place.location
        else {
            return nil
        }

        let name = place.displayName?.text ?? "Unknown"

        let photos: [Place.Photo]? = place.photos?.map {
            Place.Photo(
                photoReference: $0.name,
                width: $0.widthPx ?? 0,
                height: $0.heightPx ?? 0
            )
        }

        let openingHours: Place.OpeningHours? = {
            guard let openNow = place.regularOpeningHours?.openNow else { return nil }
            return Place.OpeningHours(openNow: openNow)
        }()

        return Place(
            placeId: placeId,
            name: name,
            vicinity: place.formattedAddress,
            geometry: Place.Geometry(location: Place.Location(lat: location.latitude, lng: location.longitude)),
            rating: place.rating,
            types: place.types,
            photos: photos,
            openingHours: openingHours
        )
    }

    private func mapV1PlaceToLegacyPlaceDetails(_ place: V1Place) -> PlaceDetails? {
        guard let placeId = place.id,
              let location = place.location
        else {
            return nil
        }

        let name = place.displayName?.text ?? "Unknown"

        let photos: [Place.Photo]? = place.photos?.map {
            Place.Photo(
                photoReference: $0.name,
                width: $0.widthPx ?? 0,
                height: $0.heightPx ?? 0
            )
        }

        let openingHours: PlaceDetails.DetailedOpeningHours? = {
            if place.regularOpeningHours?.openNow == nil && place.regularOpeningHours?.weekdayDescriptions == nil {
                return nil
            }
            return PlaceDetails.DetailedOpeningHours(
                openNow: place.regularOpeningHours?.openNow,
                weekdayText: place.regularOpeningHours?.weekdayDescriptions
            )
        }()

        return PlaceDetails(
            placeId: placeId,
            name: name,
            formattedAddress: place.formattedAddress,
            geometry: Place.Geometry(location: Place.Location(lat: location.latitude, lng: location.longitude)),
            rating: place.rating,
            editorialSummary: place.editorialSummary?.text,
            website: place.websiteUri,
            phoneNumber: place.internationalPhoneNumber,
            openingHours: openingHours,
            photos: photos,
            reviews: nil,
            types: place.types
        )
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
        
        let fieldMask = "places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.types,places.photos,places.regularOpeningHours.openNow"

        let url: URL
        let requestBody: Data
        let request: URLRequest

        if let keyword, !keyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            guard let endpoint = URL(string: "\(v1BaseURL)/places:searchText") else {
                throw AppError.invalidURL
            }
            url = endpoint
            let bias = V1LocationBias(circle: V1Circle(center: V1LatLng(latitude: location.latitude, longitude: location.longitude), radius: radius))
            let body = V1SearchTextRequest(
                textQuery: keyword,
                includedType: type,
                locationBias: bias,
                maxResultCount: 20
            )
            requestBody = try JSONEncoder().encode(body)
            request = makeV1Request(url: url, method: "POST", fieldMask: fieldMask, body: requestBody)
        } else {
            guard let endpoint = URL(string: "\(v1BaseURL)/places:searchNearby") else {
                throw AppError.invalidURL
            }
            url = endpoint
            let restriction = V1LocationRestriction(
                circle: V1Circle(
                    center: V1LatLng(latitude: location.latitude, longitude: location.longitude),
                    radius: radius
                )
            )
            let includedTypes: [String]? = {
                guard let type, !type.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
                return [type]
            }()
            let body = V1SearchNearbyRequest(
                includedTypes: includedTypes,
                locationRestriction: restriction,
                maxResultCount: 20
            )
            requestBody = try JSONEncoder().encode(body)
            request = makeV1Request(url: url, method: "POST", fieldMask: fieldMask, body: requestBody)
        }

        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let message = decodeGoogleAPIErrorMessage(from: data) ?? "Google Places request failed (HTTP \(httpResponse.statusCode))."
            throw AppError.apiError(message)
        }

        do {
            if request.url?.absoluteString.contains(":searchText") == true {
                let decoded = try JSONDecoder().decode(V1SearchTextResponse.self, from: data)
                let places = (decoded.places ?? []).compactMap(mapV1PlaceToLegacyPlace)
                if places.isEmpty { throw AppError.noResults }
                return places
            } else {
                let decoded = try JSONDecoder().decode(V1SearchNearbyResponse.self, from: data)
                let places = (decoded.places ?? []).compactMap(mapV1PlaceToLegacyPlace)
                if places.isEmpty { throw AppError.noResults }
                return places
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
        
        guard let url = URL(string: "\(v1BaseURL)/places/\(placeId)") else {
            throw AppError.invalidURL
        }

        let fieldMask = "id,displayName,editorialSummary,formattedAddress,location,rating,types,photos,websiteUri,internationalPhoneNumber,regularOpeningHours.openNow,regularOpeningHours.weekdayDescriptions"
        let request = makeV1Request(url: url, method: "GET", fieldMask: fieldMask)

        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let message = decodeGoogleAPIErrorMessage(from: data) ?? "Google Places details request failed (HTTP \(httpResponse.statusCode))."
            throw AppError.apiError(message)
        }

        do {
            let decoded = try JSONDecoder().decode(V1Place.self, from: data)
            if let details = mapV1PlaceToLegacyPlaceDetails(decoded) {
                return details
            }
            throw AppError.locationNotFound
        } catch let error as DecodingError {
            throw AppError.decodingFailed(error)
        }
    }
    
    func getPhotoURL(photoReference: String, maxWidth: Int = 400) -> URL? {
        // Places API (New): photo reference is typically a resource name like
        // "places/{placeId}/photos/{photoId}".
        if photoReference.hasPrefix("places/") {
            var components = URLComponents(string: "\(v1BaseURL)/\(photoReference)/media")
            components?.queryItems = [
                URLQueryItem(name: "maxWidthPx", value: "\(maxWidth)"),
                // Using query param here so AsyncImage can load without custom headers.
                URLQueryItem(name: "key", value: Config.googlePlacesAPIKey)
            ]
            return components?.url
        }

        // Backward-compat fallback (legacy photo reference). This may fail if legacy Places API is disabled.
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/place/photo")
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
