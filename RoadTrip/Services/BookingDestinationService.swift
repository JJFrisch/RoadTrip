//
//  BookingDestinationService.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation

// MARK: - API Response Models for Destination Search
struct DestinationSearchResponse: Codable {
    let status: Bool?
    let message: String?
    let data: [DestinationResult]?
}

struct DestinationResult: Codable {
    let dest_id: String?
    let search_type: String?
    let city_name: String?
    let label: String?
    let country: String?
    let region: String?
    let latitude: Double?
    let longitude: Double?
}

class BookingDestinationService {
    static let shared = BookingDestinationService()
    
    private init() {}
    
    // Cache for dynamically looked up destination IDs
    private var dynamicCache: [String: String] = [:]
    
    // Common US cities destination IDs for Booking.com
    // These IDs can be found by searching on Booking.com and looking at the URL
    private let cityDestinationIds: [String: String] = [
        // Major US Cities
        "san francisco": "-553173",
        "los angeles": "20014181",
        "new york": "20088325",
        "chicago": "20033173",
        "miami": "20023181",
        "las vegas": "20063527",
        "seattle": "20069211",
        "boston": "20037115",
        "washington": "20033175",
        "portland": "20051751",
        "denver": "20023165",
        "austin": "20058661",
        "phoenix": "20023183",
        "san diego": "20015732",
        "dallas": "20023181",
        "houston": "20023175",
        "philadelphia": "20023179",
        "atlanta": "20023167",
        "nashville": "20023177",
        "new orleans": "20023169",
        
        // California Cities
        "sacramento": "-550604",
        "san jose": "-550543",
        "oakland": "-549764",
        "fresno": "-551282",
        
        // Other Major Cities
        "orlando": "20023185",
        "tampa": "20023187",
        "minneapolis": "20023189",
        "detroit": "20023191",
        "salt lake city": "20023193",
        "kansas city": "20023195",
        "memphis": "20023197",
        "baltimore": "20023199",
        "milwaukee": "20023201",
        "honolulu": "20023203"
    ]
    
    // Get destination ID for a city (local lookup)
    func getDestinationId(for location: String) -> String? {
        let normalized = location.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Check dynamic cache first
        if let cachedId = dynamicCache[normalized] {
            print("✅ Found cached destination ID for \(location): \(cachedId)")
            return cachedId
        }
        
        // Try exact match
        if let destId = cityDestinationIds[normalized] {
            print("✅ Found destination ID for \(location): \(destId)")
            return destId
        }
        
        // Try partial match (e.g., "San Francisco, CA" matches "san francisco")
        for (city, destId) in cityDestinationIds {
            if normalized.contains(city) || city.contains(normalized) {
                print("✅ Partial match found for \(location): \(city) -> \(destId)")
                return destId
            }
        }
        
        print("⚠️ No local destination ID found for \(location)")
        return nil
    }
    
    // Get destination ID with fallback
    func getDestinationIdOrDefault(for location: String) -> String {
        return getDestinationId(for: location) ?? "-553173" // Default to San Francisco
    }
    
    // MARK: - Dynamic Destination Search via API
    func searchDestination(query: String) async -> String? {
        let normalized = query.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Check local first
        if let localId = getDestinationId(for: normalized) {
            return localId
        }
        
        // Check if API key is configured
        guard Config.rapidAPIKey != "YOUR_RAPIDAPI_KEY_HERE" else {
            print("⚠️ RapidAPI key not configured - cannot search destinations")
            return nil
        }
        
        print("🔍 Searching Booking.com for destination: \(query)")
        
        // Build URL for destination search
        var components = URLComponents(string: "\(Config.bookingAPIBaseURL)/hotels/searchDestination")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]
        
        guard let url = components.url else {
            print("❌ Invalid destination search URL")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(Config.rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.addValue(Config.rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 10
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Destination Search Response: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("❌ Destination search failed: \(httpResponse.statusCode)")
                    return nil
                }
            }
            
            // Parse response
            let decoder = JSONDecoder()
            let searchResponse = try decoder.decode(DestinationSearchResponse.self, from: data)
            
            // Find the best city match
            if let destinations = searchResponse.data {
                // Prefer city type results
                for dest in destinations {
                    if dest.search_type == "city", let destId = dest.dest_id {
                        print("✅ Found destination via API: \(dest.city_name ?? query) -> \(destId)")
                        
                        // Cache the result
                        dynamicCache[normalized] = destId
                        
                        return destId
                    }
                }
                
                // Fall back to first result
                if let firstDest = destinations.first, let destId = firstDest.dest_id {
                    print("✅ Using first destination result: \(firstDest.label ?? query) -> \(destId)")
                    dynamicCache[normalized] = destId
                    return destId
                }
            }
            
            print("⚠️ No destinations found for: \(query)")
            return nil
            
        } catch {
            print("❌ Destination search error: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Get Destination ID with API Fallback
    func getDestinationIdAsync(for location: String) async -> String {
        // Try local lookup first
        if let localId = getDestinationId(for: location) {
            return localId
        }
        
        // Try API lookup
        if let apiId = await searchDestination(query: location) {
            return apiId
        }
        
        // Default fallback
        print("⚠️ Using default destination ID for: \(location)")
        return "-553173" // San Francisco default
    }
    
    // Clear dynamic cache
    func clearCache() {
        dynamicCache.removeAll()
        print("🗑️ Destination cache cleared")
    }
}
