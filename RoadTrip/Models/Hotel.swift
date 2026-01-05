//
//  Hotel.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation
import SwiftData

@Model
class Hotel {
    var id: UUID = UUID()
    var name: String = ""
    var address: String = ""
    var city: String = ""
    var state: String = ""
    var zipCode: String = ""
    var country: String = ""
    
    // Location
    var latitude: Double?
    var longitude: Double?
    
    // Basic Info
    var rating: Double? // 0.0 to 5.0
    var reviewCount: Int?
    var starRating: Int? // 1-5 stars
    var imageURLs: [String] = []
    var thumbnailURL: String?
    
    // Amenities
    var amenities: [String] = []
    var hasWiFi: Bool = false
    var hasParking: Bool = false
    var hasBreakfast: Bool = false
    var hasPool: Bool = false
    var hasFitness: Bool = false
    var petFriendly: Bool = false
    
    // Pricing (per night)
    var pricePerNight: Double?
    var currency: String = "USD"
    var taxesAndFees: Double?
    
    // Booking Links
    var bookingComURL: String?
    var hotelsComURL: String?
    var expediaURL: String?
    var airbnbURL: String?
    var directBookingURL: String?
    
    // Source information
    var sourceType: String? // "booking", "hotels", "expedia", "airbnb", "manual"
    var externalId: String?
    var lastUpdated: Date = Date()
    
    // User preferences
    var isFavorite: Bool = false
    var notes: String?

    @Relationship(deleteRule: .nullify, inverse: \TripDay.hotel)
    var day: TripDay?
    
    init(name: String, address: String, city: String, state: String = "", zipCode: String = "", country: String = "USA") {
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
    }
}

// MARK: - Hotel Search Result (for API responses)
struct HotelSearchResult: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let city: String
    let state: String?
    let country: String
    let latitude: Double?
    let longitude: Double?
    let rating: Double?
    let reviewCount: Int?
    let starRating: Int?
    let thumbnailURL: String?
    let imageURLs: [String]
    let pricePerNight: Double?
    let totalPrice: Double?
    let currency: String?
    let amenities: [String]
    let description: String?
    let bookingURL: String
    let source: BookingSource
    
    enum BookingSource: String, Codable, CaseIterable {
        case booking = "Booking.com"
        case hotels = "Hotels.com"
        case expedia = "Expedia"
        case airbnb = "Airbnb"
        case direct = "Direct"
    }
    
    // Convert to Hotel model
    func toHotel() -> Hotel {
        let hotel = Hotel(name: name, address: address, city: city, state: state ?? "", country: country)

        if let latitude, let longitude {
            var lat = latitude
            var lon = longitude

            // If lat/lon appear swapped (common data issue), correct it.
            if !(-90...90).contains(lat), (-90...90).contains(lon), (-180...180).contains(lat) {
                swap(&lat, &lon)
            }

            if (-90...90).contains(lat), (-180...180).contains(lon) {
                hotel.latitude = lat
                hotel.longitude = lon
            }
        }
        hotel.rating = rating
        hotel.reviewCount = reviewCount
        hotel.starRating = starRating
        hotel.thumbnailURL = thumbnailURL
        hotel.imageURLs = imageURLs
        hotel.pricePerNight = pricePerNight
        hotel.currency = currency ?? "USD"
        hotel.amenities = amenities
        hotel.sourceType = source.rawValue
        hotel.externalId = id
        
        // Set booking URL based on source
        switch source {
        case .booking:
            hotel.bookingComURL = bookingURL
        case .hotels:
            hotel.hotelsComURL = bookingURL
        case .expedia:
            hotel.expediaURL = bookingURL
        case .airbnb:
            hotel.airbnbURL = bookingURL
        case .direct:
            hotel.directBookingURL = bookingURL
        }
        
        // Parse amenities for quick filters
        let amenityLower = amenities.map { $0.lowercased() }
        hotel.hasWiFi = amenityLower.contains { $0.contains("wifi") || $0.contains("wi-fi") || $0.contains("internet") }
        hotel.hasParking = amenityLower.contains { $0.contains("parking") }
        hotel.hasBreakfast = amenityLower.contains { $0.contains("breakfast") }
        hotel.hasPool = amenityLower.contains { $0.contains("pool") }
        hotel.hasFitness = amenityLower.contains { $0.contains("fitness") || $0.contains("gym") }
        hotel.petFriendly = amenityLower.contains { $0.contains("pet") }
        
        return hotel
    }
}

// MARK: - User Hotel Preferences
@Model
class HotelPreferences {
    var id: UUID = UUID()
    var enabledSources: [String] = ["booking", "hotels", "expedia", "airbnb"] // booking, hotels, expedia, airbnb
    var defaultSortBy: String = "price" // price, rating, distance
    var maxPricePerNight: Double?
    var minRating: Double?
    var requiredAmenities: [String] = []
    var preferredAmenities: [String] = []
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    init() {
    }
    
    func isSourceEnabled(_ source: HotelSearchResult.BookingSource) -> Bool {
        enabledSources.contains(source.rawValue.lowercased())
    }
}
