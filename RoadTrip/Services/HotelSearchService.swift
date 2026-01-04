//
//  HotelSearchService.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation
import CoreLocation

// MARK: - Booking.com API Response Models
struct BookingAPIResponse: Codable {
    let status: Bool
    let message: String
    let data: BookingData?
}

struct BookingData: Codable {
    let hotels: [BookingHotel]?
}

struct BookingHotel: Codable {
    let hotel_id: String?
    let accessibilityLabel: String?
    let property: BookingProperty?
}

struct BookingProperty: Codable {
    let name: String?
    let reviewScore: Double?
    let reviewScoreWord: String?
    let reviewCount: Int?
    let latitude: Double?
    let longitude: Double?
    let priceBreakdown: BookingPriceBreakdown?
    let photoUrls: [String]?
    let accuratePropertyClass: Int?
}

struct BookingPriceBreakdown: Codable {
    let grossPrice: BookingPrice?
}

struct BookingPrice: Codable {
    let value: Double?
}

class HotelSearchService: ObservableObject {
    static let shared = HotelSearchService()
    
    @Published var isSearching = false
    @Published var searchResults: [HotelSearchResult] = []
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Search Hotels
    func searchHotels(
        location: String,
        checkInDate: Date,
        checkOutDate: Date,
        adults: Int = 2,
        children: Int = 0,
        childrenAges: [Int] = [],
        rooms: Int = 1,
        enabledSources: [String],
        filters: HotelFilters
    ) async -> [HotelSearchResult] {
        
        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }
        
        var allResults: [HotelSearchResult] = []
        
        // Search each enabled source in parallel
        await withTaskGroup(of: [HotelSearchResult].self) { group in
            for source in enabledSources {
                group.addTask {
                    await self.searchSource(
                        source: source,
                        location: location,
                        checkInDate: checkInDate,
                        checkOutDate: checkOutDate,
                        adults: adults,
                        children: children,
                        childrenAges: childrenAges,
                        rooms: rooms,
                        filters: filters
                    )
                }
            }
            
            for await results in group {
                allResults.append(contentsOf: results)
            }
        }
        
        // Apply filters
        let filtered = applyFilters(allResults, filters: filters)
        
        // Sort results
        let sorted = sortResults(filtered, by: filters.sortBy)
        
        await MainActor.run {
            searchResults = sorted
            isSearching = false
        }
        
        return sorted
    }
    
    // MARK: - Search Individual Sources
    private func searchSource(
        source: String,
        location: String,
        checkInDate: Date,
        checkOutDate: Date,
        adults: Int,
        children: Int,
        childrenAges: [Int],
        rooms: Int,
        filters: HotelFilters
    ) async -> [HotelSearchResult] {
        
        switch source.lowercased() {
        case "booking":
            return await searchBookingCom(location: location, checkIn: checkInDate, checkOut: checkOutDate, adults: adults, children: children, childrenAges: childrenAges, rooms: rooms)
        case "hotels":
            return await searchHotelsCom(location: location, checkIn: checkInDate, checkOut: checkOutDate, guests: adults + children)
        case "expedia":
            return await searchExpedia(location: location, checkIn: checkInDate, checkOut: checkOutDate, guests: adults + children)
        case "airbnb":
            return await searchAirbnb(location: location, checkIn: checkInDate, checkOut: checkOutDate, guests: adults + children)
        default:
            return []
        }
    }
    
    // MARK: - Booking.com Search (Real API Implementation)
    private func searchBookingCom(location: String, checkIn: Date, checkOut: Date, adults: Int, children: Int, childrenAges: [Int], rooms: Int) async -> [HotelSearchResult] {
        // Check if API key is configured
        guard Config.rapidAPIKey != "YOUR_RAPIDAPI_KEY_HERE" else {
            print("⚠️ RapidAPI key not configured - using mock data")
            try? await Task.sleep(nanoseconds: 500_000_000)
            return generateMockResults(source: .booking, location: location, count: 5)
        }
        
        // Get destination ID using async lookup (with API fallback)
        let destId = await BookingDestinationService.shared.getDestinationIdAsync(for: location)
        
        // Also geocode to verify location exists
        do {
            let coordinates = try await GeocodingService.shared.geocode(location: location)
            print("📍 Using coordinates: \(coordinates.latitude), \(coordinates.longitude)")
            print("🏨 Using destination ID: \(destId)")
        } catch {
            print("⚠️ Geocoding failed: \(error.localizedDescription)")
        }
        
        // Format dates for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let checkInStr = dateFormatter.string(from: checkIn)
        let checkOutStr = dateFormatter.string(from: checkOut)
        
        // Build URL with query parameters
        var components = URLComponents(string: "\(Config.bookingAPIBaseURL)/hotels/searchHotels")!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "dest_id", value: destId),
            URLQueryItem(name: "search_type", value: "city"),
            URLQueryItem(name: "arrival_date", value: checkInStr),
            URLQueryItem(name: "departure_date", value: checkOutStr),
            URLQueryItem(name: "adults", value: String(max(1, adults))),
            URLQueryItem(name: "room_qty", value: String(max(1, rooms))),
            URLQueryItem(name: "page_number", value: "1"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "temperature_unit", value: "c"),
            URLQueryItem(name: "languagecode", value: "en-us"),
            URLQueryItem(name: "currency_code", value: "USD")
        ]

        if children > 0 {
            let cappedChildren = min(children, 10)
            let agesArray: [Int]
            if childrenAges.count >= cappedChildren {
                agesArray = Array(childrenAges.prefix(cappedChildren))
            } else if childrenAges.isEmpty {
                agesArray = Array(repeating: 5, count: cappedChildren)
            } else {
                agesArray = childrenAges + Array(repeating: 5, count: cappedChildren - childrenAges.count)
            }

            let ages = agesArray.map { String(max(0, min(17, $0))) }.joined(separator: ",")
            queryItems.append(URLQueryItem(name: "children_age", value: ages))
        }

        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("❌ Invalid URL")
            return generateMockResults(source: .booking, location: location, count: 5)
        }
        
        // Create request with headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(Config.rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.addValue(Config.rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Booking.com API Response: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("❌ API Error: \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("Error details: \(errorString)")
                    }
                    return generateMockResults(source: .booking, location: location, count: 5)
                }
            }
            
            // Parse response
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(BookingAPIResponse.self, from: data)
            
            guard apiResponse.status, let hotels = apiResponse.data?.hotels else {
                print("⚠️ No hotels found in API response")
                return []
            }
            
            // Convert to HotelSearchResult
            var results: [HotelSearchResult] = []
            for bookingHotel in hotels {
                guard let property = bookingHotel.property,
                      let name = property.name,
                      let latitude = property.latitude,
                      let longitude = property.longitude else {
                    continue
                }
                
                let hotelId = bookingHotel.hotel_id ?? UUID().uuidString
                let rating = property.reviewScore
                let reviewCount = property.reviewCount
                let starRating = property.accuratePropertyClass
                let pricePerNight = property.priceBreakdown?.grossPrice?.value
                
                // Estimate nights
                let nights = Calendar.current.dateComponents([.day], from: checkIn, to: checkOut).day ?? 1
                let totalPrice = pricePerNight.map { $0 * Double(nights) }
                
                let result = HotelSearchResult(
                    id: hotelId,
                    name: name,
                    address: location, // API doesn't provide detailed address in search results
                    city: location,
                    state: nil,
                    country: "USA", // Would need geocoding for accurate country
                    latitude: latitude,
                    longitude: longitude,
                    rating: rating,
                    reviewCount: reviewCount,
                    starRating: starRating,
                    thumbnailURL: property.photoUrls?.first,
                    imageURLs: property.photoUrls ?? [],
                    pricePerNight: pricePerNight,
                    totalPrice: totalPrice,
                    currency: "USD",
                    amenities: [], // Full amenities come from detail endpoint
                    description: nil,
                    bookingURL: "https://www.booking.com/hotel/us/\(hotelId).html?aid=YOUR_AFFILIATE_ID",
                    source: .booking
                )
                
                results.append(result)
            }
            
            print("✅ Fetched \(results.count) hotels from Booking.com")
            return results
            
        } catch {
            print("❌ Booking.com API Error: \(error.localizedDescription)")
            // Fallback to mock data on error
            return generateMockResults(source: .booking, location: location, count: 5)
        }
    }
    
    // MARK: - Hotels.com Search (Mock)
    private func searchHotelsCom(location: String, checkIn: Date, checkOut: Date, guests: Int) async -> [HotelSearchResult] {
        try? await Task.sleep(nanoseconds: 600_000_000)
        return generateMockResults(source: .hotels, location: location, count: 4)
    }
    
    // MARK: - Expedia Search (Mock)
    private func searchExpedia(location: String, checkIn: Date, checkOut: Date, guests: Int) async -> [HotelSearchResult] {
        try? await Task.sleep(nanoseconds: 550_000_000)
        return generateMockResults(source: .expedia, location: location, count: 6)
    }
    
    // MARK: - Airbnb Search (Mock)
    private func searchAirbnb(location: String, checkIn: Date, checkOut: Date, guests: Int) async -> [HotelSearchResult] {
        try? await Task.sleep(nanoseconds: 650_000_000)
        return generateMockResults(source: .airbnb, location: location, count: 3)
    }
    
    // MARK: - Apply Filters
    private func applyFilters(_ results: [HotelSearchResult], filters: HotelFilters) -> [HotelSearchResult] {
        return results.filter { hotel in
            // Price filter
            if let maxPrice = filters.maxPrice, let price = hotel.pricePerNight, price > maxPrice {
                return false
            }
            
            if let minPrice = filters.minPrice, let price = hotel.pricePerNight, price < minPrice {
                return false
            }
            
            // Rating filter
            if let minRating = filters.minRating, let rating = hotel.rating, rating < minRating {
                return false
            }
            
            // Star rating filter
            if let minStars = filters.minStars, let stars = hotel.starRating, stars < minStars {
                return false
            }
            
            // Amenities filter
            if filters.requireWiFi && !hotel.amenities.contains(where: { $0.lowercased().contains("wifi") || $0.lowercased().contains("internet") }) {
                return false
            }
            
            if filters.requireParking && !hotel.amenities.contains(where: { $0.lowercased().contains("parking") }) {
                return false
            }
            
            if filters.requireBreakfast && !hotel.amenities.contains(where: { $0.lowercased().contains("breakfast") }) {
                return false
            }
            
            if filters.requirePool && !hotel.amenities.contains(where: { $0.lowercased().contains("pool") }) {
                return false
            }
            
            if filters.petFriendly && !hotel.amenities.contains(where: { $0.lowercased().contains("pet") }) {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Sort Results
    private func sortResults(_ results: [HotelSearchResult], by sortOption: HotelFilters.SortOption) -> [HotelSearchResult] {
        switch sortOption {
        case .priceLowToHigh:
            return results.sorted { ($0.pricePerNight ?? Double.infinity) < ($1.pricePerNight ?? Double.infinity) }
        case .priceHighToLow:
            return results.sorted { ($0.pricePerNight ?? 0) > ($1.pricePerNight ?? 0) }
        case .ratingHighToLow:
            return results.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .starsHighToLow:
            return results.sorted { ($0.starRating ?? 0) > ($1.starRating ?? 0) }
        case .reviewCount:
            return results.sorted { ($0.reviewCount ?? 0) > ($1.reviewCount ?? 0) }
        }
    }
    
    // MARK: - Mock Data Generator
    private func generateMockResults(source: HotelSearchResult.BookingSource, location: String, count: Int) -> [HotelSearchResult] {
        let hotelNames = [
            "Grand Plaza Hotel", "Comfort Inn & Suites", "Luxury Resort & Spa", "Downtown Boutique Hotel",
            "Oceanview Hotel", "Mountain Lodge", "City Center Inn", "Historic Hotel", "Modern Suites",
            "Riverside Hotel", "Airport Hotel", "Business Center Hotel", "Family Resort"
        ]
        
        let amenitiesSets: [[String]] = [
            ["Free WiFi", "Free Parking", "Pool", "Fitness Center", "Restaurant"],
            ["Free WiFi", "Breakfast Included", "Business Center", "Airport Shuttle"],
            ["Free WiFi", "Free Parking", "Pet Friendly", "Kitchenette"],
            ["Free WiFi", "Pool", "Spa", "Restaurant", "Bar", "Fitness Center", "Concierge"],
            ["Free WiFi", "Parking", "Breakfast Included", "Pet Friendly"]
        ]
        
        return (0..<count).map { index in
            let price = Double.random(in: 80...350).rounded()
            let rating = Double.random(in: 3.5...5.0)
            let stars = Int.random(in: 2...5)
            
            return HotelSearchResult(
                id: "\(source.rawValue)-\(UUID().uuidString)",
                name: hotelNames.randomElement() ?? "Hotel",
                address: "\(100 + index * 10) Main Street",
                city: location,
                state: "CA",
                country: "USA",
                latitude: 37.7749 + Double.random(in: -0.1...0.1),
                longitude: -122.4194 + Double.random(in: -0.1...0.1),
                rating: rating,
                reviewCount: Int.random(in: 50...2000),
                starRating: stars,
                thumbnailURL: "https://example.com/hotel-\(index).jpg",
                imageURLs: (0..<5).map { "https://example.com/hotel-\(index)-\($0).jpg" },
                pricePerNight: price,
                totalPrice: nil,
                currency: "USD",
                amenities: amenitiesSets.randomElement() ?? [],
                description: nil,
                bookingURL: "https://\(source.rawValue.lowercased()).com/hotel-\(index)",
                source: source
            )
        }
    }
}

// MARK: - Hotel Filters
struct HotelFilters {
    var minPrice: Double?
    var maxPrice: Double?
    var minRating: Double?
    var minStars: Int?
    var sortBy: SortOption = .priceLowToHigh
    
    // Amenity filters
    var requireWiFi: Bool = false
    var requireParking: Bool = false
    var requireBreakfast: Bool = false
    var requirePool: Bool = false
    var petFriendly: Bool = false
    
    enum SortOption: String, CaseIterable {
        case priceLowToHigh = "Price: Low to High"
        case priceHighToLow = "Price: High to Low"
        case ratingHighToLow = "Rating: High to Low"
        case starsHighToLow = "Stars: High to Low"
        case reviewCount = "Most Reviewed"
    }
}
