//
//  CarRental.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation
import SwiftData

// MARK: - Car Rental Model
@Model
class CarRental {
    var id: UUID
    var carName: String
    var company: String
    var carType: String // "Economy", "Compact", "SUV", "Luxury", etc.
    var transmission: String // "Automatic", "Manual"
    var seats: Int
    var doors: Int
    var fuelType: String // "Gasoline", "Diesel", "Electric", "Hybrid"
    
    // Location
    var pickUpLocation: String
    var pickUpLatitude: Double
    var pickUpLongitude: Double
    var dropOffLocation: String
    var dropOffLatitude: Double
    var dropOffLongitude: Double
    
    // Dates
    var pickUpDate: Date
    var dropOffDate: Date
    
    // Pricing
    var pricePerDay: Double
    var totalPrice: Double
    var currency: String
    
    // Features
    var hasAirConditioning: Bool
    var hasGPS: Bool
    var hasUnlimitedMileage: Bool
    var features: [String]
    
    // Booking
    var bookingURL: String
    var source: String // "Booking.com", "Hertz", "Enterprise", etc.
    var vendorLogo: String?
    var rating: Double?
    var reviewCount: Int?
    
    // Images
    var imageURL: String?
    
    init(
        carName: String,
        company: String,
        carType: String,
        transmission: String,
        seats: Int,
        pickUpLocation: String,
        pickUpLatitude: Double,
        pickUpLongitude: Double,
        dropOffLocation: String,
        dropOffLatitude: Double,
        dropOffLongitude: Double,
        pickUpDate: Date,
        dropOffDate: Date,
        pricePerDay: Double,
        totalPrice: Double
    ) {
        self.id = UUID()
        self.carName = carName
        self.company = company
        self.carType = carType
        self.transmission = transmission
        self.seats = seats
        self.doors = 4
        self.fuelType = "Gasoline"
        self.pickUpLocation = pickUpLocation
        self.pickUpLatitude = pickUpLatitude
        self.pickUpLongitude = pickUpLongitude
        self.dropOffLocation = dropOffLocation
        self.dropOffLatitude = dropOffLatitude
        self.dropOffLongitude = dropOffLongitude
        self.pickUpDate = pickUpDate
        self.dropOffDate = dropOffDate
        self.pricePerDay = pricePerDay
        self.totalPrice = totalPrice
        self.currency = "USD"
        self.hasAirConditioning = true
        self.hasGPS = false
        self.hasUnlimitedMileage = true
        self.features = []
        self.bookingURL = ""
        self.source = "Booking.com"
    }
}

// MARK: - Car Rental Search Result
struct CarRentalSearchResult: Identifiable, Codable {
    let id: String
    let carName: String
    let company: String
    let carType: String
    let transmission: String
    let seats: Int
    let doors: Int
    let fuelType: String
    let pricePerDay: Double
    let totalPrice: Double
    let currency: String
    let hasAirConditioning: Bool
    let hasGPS: Bool
    let hasUnlimitedMileage: Bool
    let features: [String]
    let imageURL: String?
    let vendorLogo: String?
    let rating: Double?
    let reviewCount: Int?
    let bookingURL: String
    
    // Convert to CarRental model
    func toCarRental(
        pickUpLocation: String,
        pickUpLatitude: Double,
        pickUpLongitude: Double,
        dropOffLocation: String,
        dropOffLatitude: Double,
        dropOffLongitude: Double,
        pickUpDate: Date,
        dropOffDate: Date
    ) -> CarRental {
        let rental = CarRental(
            carName: carName,
            company: company,
            carType: carType,
            transmission: transmission,
            seats: seats,
            pickUpLocation: pickUpLocation,
            pickUpLatitude: pickUpLatitude,
            pickUpLongitude: pickUpLongitude,
            dropOffLocation: dropOffLocation,
            dropOffLatitude: dropOffLatitude,
            dropOffLongitude: dropOffLongitude,
            pickUpDate: pickUpDate,
            dropOffDate: dropOffDate,
            pricePerDay: pricePerDay,
            totalPrice: totalPrice
        )
        
        rental.doors = doors
        rental.fuelType = fuelType
        rental.hasAirConditioning = hasAirConditioning
        rental.hasGPS = hasGPS
        rental.hasUnlimitedMileage = hasUnlimitedMileage
        rental.features = features
        rental.imageURL = imageURL
        rental.vendorLogo = vendorLogo
        rental.rating = rating
        rental.reviewCount = reviewCount
        rental.bookingURL = bookingURL
        
        return rental
    }
}

// MARK: - Car Rental Filters
struct CarRentalFilters {
    var minPrice: Double?
    var maxPrice: Double?
    var carTypes: Set<String> = [] // Filter by specific types
    var transmissionType: TransmissionType?
    var minSeats: Int?
    var requireAirConditioning: Bool = false
    var requireGPS: Bool = false
    var requireUnlimitedMileage: Bool = false
    var fuelTypes: Set<String> = []
    var sortBy: SortOption = .priceLowToHigh
    
    enum TransmissionType: String, CaseIterable {
        case automatic = "Automatic"
        case manual = "Manual"
    }
    
    enum SortOption: String, CaseIterable {
        case priceLowToHigh = "Price: Low to High"
        case priceHighToLow = "Price: High to Low"
        case seats = "Most Seats"
        case rating = "Highest Rated"
    }
}
