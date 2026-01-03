import Foundation
import MapKit

/// Activity importer that uses Google Places API for reliable data
final class ActivityImporter {
    struct ImportedPlace {
        var name: String
        var address: String?
        var rating: Double?
        var coordinate: CLLocationCoordinate2D?
        var category: String?
        var typicalDurationHours: Double?
        var placeId: String?
        var photoURL: String?
        var website: String?
        var phoneNumber: String?
        var types: [String]?
    }

    static let shared = ActivityImporter()

    private init() {}

    enum ImportError: Error {
        case network
        case parse
        case invalidAPIKey
        case noResults
    }

    // MARK: - Google Places Integration

    /// Import attractions using Google Places API (replaces HTML parsing)
    func importFromGooglePlaces(near location: CLLocationCoordinate2D, 
                               radius: Double = 2000,
                               type: String? = "tourist_attraction",
                               keyword: String? = nil) async throws -> [ImportedPlace] {
        
        guard Config.hasValidGooglePlacesKey else {
            throw AppError.invalidAPIKey
        }
        
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.networkUnavailable
        }
        
        let places = try await GooglePlacesService.shared.searchNearbyWithRetry(
            location: location,
            radius: radius,
            type: type,
            keyword: keyword
        )
        
        return places.map { place in
            let category = mapGoogleTypeToCategory(place.types?.first ?? "")
            let duration = estimateDuration(for: category)
            
            var photoURL: String? = nil
            if let photo = place.photos?.first {
                photoURL = GooglePlacesService.shared.getPhotoURL(photoReference: photo.photoReference)?.absoluteString
            }
            
            return ImportedPlace(
                name: place.name,
                address: place.vicinity,
                rating: place.rating,
                coordinate: CLLocationCoordinate2D(
                    latitude: place.geometry.location.lat,
                    longitude: place.geometry.location.lng
                ),
                category: category,
                typicalDurationHours: duration,
                placeId: place.placeId,
                photoURL: photoURL,
                website: nil,
                phoneNumber: nil,
                types: place.types
            )
        }
    }
    
    /// Get detailed information for a specific place
    func getPlaceDetails(placeId: String) async throws -> ImportedPlace {
        let details = try await GooglePlacesService.shared.getPlaceDetails(placeId: placeId)
        
        let category = mapGoogleTypeToCategory(details.types?.first ?? "")
        let duration = estimateDuration(for: category)
        
        var photoURL: String? = nil
        if let photo = details.photos?.first {
            photoURL = GooglePlacesService.shared.getPhotoURL(photoReference: photo.photoReference)?.absoluteString
        }
        
        return ImportedPlace(
            name: details.name,
            address: details.formattedAddress,
            rating: details.rating,
            coordinate: CLLocationCoordinate2D(
                latitude: details.geometry.location.lat,
                longitude: details.geometry.location.lng
            ),
            category: category,
            typicalDurationHours: duration,
            placeId: details.placeId,
            photoURL: photoURL,
            website: details.website,
            phoneNumber: details.phoneNumber,
            types: details.types
        )
    }

    /// Legacy URL-based import (deprecated - kept for backward compatibility)
    func importFromTripAdvisor(url: URL) async throws -> [ImportedPlace] {
        // Fallback to HTML parsing for backward compatibility
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200...299 ~= http.statusCode else { 
            throw AppError.networkUnavailable
        }

        guard let html = String(data: data, encoding: .utf8) else { 
            throw AppError.decodingFailed(ImportError.parse)
        }
        return parseTripAdvisor(html: html)
    }

    /// Legacy URL-based import (deprecated - kept for backward compatibility)
    func importFromGoogleMaps(url: URL) async throws -> [ImportedPlace] {
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200...299 ~= http.statusCode else { 
            throw AppError.networkUnavailable
        }

        guard let html = String(data: data, encoding: .utf8) else { 
            throw AppError.decodingFailed(ImportError.parse)
        }
        return parseGoogleMaps(html: html)
    }

    /// Bulk add popular attractions using Google Places API
    func bulkAddPopularAttractions(near coordinate: CLLocationCoordinate2D, radiusMeters: Double = 2000) async -> [ImportedPlace] {
        do {
            return try await importFromGooglePlaces(near: coordinate, radius: radiusMeters)
        } catch {
            // Fallback to basic MapKit search if Places API fails
            return await fallbackMapKitSearch(near: coordinate, radius: radiusMeters)
        }
    }
    
    // MARK: - Helper Methods
    
    private func mapGoogleTypeToCategory(_ googleType: String) -> String {
        switch googleType.lowercased() {
        case let t where t.contains("restaurant"), let t where t.contains("food"), let t where t.contains("cafe"):
            return "Food"
        case let t where t.contains("hotel"), let t where t.contains("lodging"):
            return "Hotel"
        case let t where t.contains("museum"), let t where t.contains("park"), let t where t.contains("tourist"):
            return "Attraction"
        default:
            return "Attraction"
        }
    }
    
    private func estimateDuration(for category: String) -> Double {
        switch category {
        case "Food": return 1.0
        case "Hotel": return 0.0 // Hotels are overnight
        case "Attraction": return 1.5
        default: return 1.0
        }
    }
    
    private func fallbackMapKitSearch(near coordinate: CLLocationCoordinate2D, radius: Double) async -> [ImportedPlace] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "attractions"
        request.region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: radius * 2,
            longitudinalMeters: radius * 2
        )
        
        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            
            return response.mapItems.map { item in
                ImportedPlace(
                    name: item.name ?? "Unknown",
                    address: item.placemark.title,
                    rating: nil,
                    coordinate: item.placemark.coordinate,
                    category: "Attraction",
                    typicalDurationHours: 1.5,
                    placeId: nil,
                    photoURL: nil,
                    website: item.url?.absoluteString,
                    phoneNumber: item.phoneNumber,
                    types: nil
                )
            }
        } catch {
            return []
        }
    }


    private func parseTripAdvisor(html: String) -> [ImportedPlace] {
        // Very basic heuristics: find sections with `data-attraction-name` or <a> tags with known classes
        var results: [ImportedPlace] = []

        // Try to extract titles inside <a ...>...</a> with `ui_header` like classes
        let regex = try? NSRegularExpression(pattern: "<a[^>]*>([A-Za-z0-9\s'\-:,\.\&]+)</a>", options: [.caseInsensitive])
        if let regex = regex {
            let ns = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
            for m in matches.prefix(50) {
                if m.numberOfRanges >= 2 {
                    let title = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if title.count > 3 && title.count < 100 {
                        results.append(ImportedPlace(name: title, address: nil, rating: nil, coordinate: nil, category: "Attraction", typicalDurationHours: 1.5))
                    }
                }
            }
        }

        // De-duplicate by name
        var uniq: [String: ImportedPlace] = [:]
        for r in results {
            if uniq[r.name] == nil { uniq[r.name] = r }
        }

        return Array(uniq.values)
    }

    private func parseGoogleMaps(html: String) -> [ImportedPlace] {
        // Google serves data in JS – this is best-effort parsing for small lists; real integration should use Places API.
        var results: [ImportedPlace] = []
        let regex = try? NSRegularExpression(pattern: "\\\"(.*?)\\\",\\\[\\\d\\\]", options: [])
        if let regex = regex {
            let ns = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
            for m in matches.prefix(80) {
                if m.numberOfRanges >= 2 {
                    let title = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if title.count > 3 && title.count < 80 {
                        results.append(ImportedPlace(name: title, address: nil, rating: nil, coordinate: nil, category: "Attraction", typicalDurationHours: 1.5))
                    }
                }
            }
        }

        // fallback: simple <span> tags
        if results.isEmpty {
            let spanRegex = try? NSRegularExpression(pattern: "<span[^>]*>([A-Za-z0-9\s'\-:,\.\&]+)</span>", options: [.caseInsensitive])
            if let sr = spanRegex {
                let ns = html as NSString
                let matches = sr.matches(in: html, range: NSRange(location: 0, length: ns.length))
                for m in matches.prefix(100) {
                    if m.numberOfRanges >= 2 {
                        let title = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                        if title.count > 3 && title.count < 80 {
                            results.append(ImportedPlace(name: title, address: nil, rating: nil, coordinate: nil, category: "Attraction", typicalDurationHours: 1.5))
                        }
                    }
                }
            }
        }

        // De-duplicate
        var uniq: [String: ImportedPlace] = [:]
        for r in results { if uniq[r.name] == nil { uniq[r.name] = r } }
        return Array(uniq.values)
    }
}
