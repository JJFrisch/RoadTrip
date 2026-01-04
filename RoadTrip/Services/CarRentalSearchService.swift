//
//  CarRentalSearchService.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation
import CoreLocation

// MARK: - Booking.com Car Rental API Response Models
struct CarRentalAPIResponse: Codable {
    let status: Bool
    let message: String
    let data: CarRentalData?
}

struct CarRentalData: Codable {
    let search_results: [BookingCarResult]?
}

struct BookingCarResult: Codable {
    let vehicle_info: VehicleInfo?
    let pricing_info: PricingInfo?
    let supplier: Supplier?
    let features: Features?
}

struct VehicleInfo: Codable {
    let v_name: String?
    let v_type: VehicleType?
    let transmission: String?
    let seats: Int?
    let doors: Int?
    let fuel: String?
    let image_url: String?
}

struct VehicleType: Codable {
    let category: String?
}

struct PricingInfo: Codable {
    let price_per_day: PriceDetail?
    let total: PriceDetail?
}

struct PriceDetail: Codable {
    let amount: String?
    let currency: String?
}

struct Supplier: Codable {
    let name: String?
    let logo: String?
    let rating: Double?
    let reviews: Int?
}

struct Features: Codable {
    let air_conditioning: Bool?
    let unlimited_mileage: Bool?
}

class CarRentalSearchService: ObservableObject {
    static let shared = CarRentalSearchService()
    
    @Published var isSearching = false
    @Published var searchResults: [CarRentalSearchResult] = []
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Search Car Rentals
    func searchCarRentals(
        pickUpLocation: String,
        pickUpLatitude: Double,
        pickUpLongitude: Double,
        dropOffLocation: String,
        dropOffLatitude: Double,
        dropOffLongitude: Double,
        pickUpDate: Date,
        pickUpTime: String = "10:00",
        dropOffDate: Date,
        dropOffTime: String = "10:00",
        driverAge: Int = 30,
        filters: CarRentalFilters
    ) async -> [CarRentalSearchResult] {
        
        await MainActor.run {
            isSearching = true
            errorMessage = nil
        }
        
        // Check if API key is configured
        guard Config.rapidAPIKey != "YOUR_RAPIDAPI_KEY_HERE" else {
            print("⚠️ RapidAPI key not configured - using mock data")
            let results = generateMockResults(location: pickUpLocation, count: 8)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
            return results
        }
        
        // Format dates for API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let pickUpDateStr = dateFormatter.string(from: pickUpDate)
        let dropOffDateStr = dateFormatter.string(from: dropOffDate)
        
        // Build URL
        var components = URLComponents(string: "\(Config.bookingAPIBaseURL)/cars/searchCarRentals")!
        components.queryItems = [
            URLQueryItem(name: "pick_up_latitude", value: String(pickUpLatitude)),
            URLQueryItem(name: "pick_up_longitude", value: String(pickUpLongitude)),
            URLQueryItem(name: "drop_off_latitude", value: String(dropOffLatitude)),
            URLQueryItem(name: "drop_off_longitude", value: String(dropOffLongitude)),
            URLQueryItem(name: "pick_up_date", value: pickUpDateStr),
            URLQueryItem(name: "drop_off_date", value: dropOffDateStr),
            URLQueryItem(name: "pick_up_time", value: pickUpTime),
            URLQueryItem(name: "drop_off_time", value: dropOffTime),
            URLQueryItem(name: "driver_age", value: String(driverAge)),
            URLQueryItem(name: "currency_code", value: "USD"),
            URLQueryItem(name: "location", value: "US")
        ]
        
        guard let url = components.url else {
            print("❌ Invalid URL")
            let results = generateMockResults(location: pickUpLocation, count: 8)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
            return results
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(Config.rapidAPIKey, forHTTPHeaderField: "x-rapidapi-key")
        request.addValue(Config.rapidAPIHost, forHTTPHeaderField: "x-rapidapi-host")
        request.timeoutInterval = 15
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Car Rental API Response: \(httpResponse.statusCode)")
                
                guard httpResponse.statusCode == 200 else {
                    print("❌ API Error: \(httpResponse.statusCode)")
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("Error details: \(errorString)")
                    }
                    let results = generateMockResults(location: pickUpLocation, count: 8)
                    await MainActor.run {
                        searchResults = results
                        isSearching = false
                    }
                    return results
                }
            }
            
            let decoder = JSONDecoder()
            let apiResponse = try decoder.decode(CarRentalAPIResponse.self, from: data)
            
            guard apiResponse.status, let cars = apiResponse.data?.search_results else {
                print("⚠️ No cars found in API response")
                let results = generateMockResults(location: pickUpLocation, count: 8)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                }
                return results
            }
            
            var results: [CarRentalSearchResult] = []
            for car in cars {
                guard let vehicleInfo = car.vehicle_info,
                      let carName = vehicleInfo.v_name,
                      let pricing = car.pricing_info else {
                    continue
                }
                
                let pricePerDayStr = pricing.price_per_day?.amount ?? "0"
                let totalPriceStr = pricing.total?.amount ?? "0"
                let pricePerDay = Double(pricePerDayStr) ?? 0
                let totalPrice = Double(totalPriceStr) ?? 0
                
                let result = CarRentalSearchResult(
                    id: UUID().uuidString,
                    carName: carName,
                    company: car.supplier?.name ?? "Unknown",
                    carType: vehicleInfo.v_type?.category ?? "Standard",
                    transmission: vehicleInfo.transmission ?? "Automatic",
                    seats: vehicleInfo.seats ?? 5,
                    doors: vehicleInfo.doors ?? 4,
                    fuelType: vehicleInfo.fuel ?? "Gasoline",
                    pricePerDay: pricePerDay,
                    totalPrice: totalPrice,
                    currency: pricing.total?.currency ?? "USD",
                    hasAirConditioning: car.features?.air_conditioning ?? false,
                    hasGPS: false,
                    hasUnlimitedMileage: car.features?.unlimited_mileage ?? false,
                    features: [],
                    imageURL: vehicleInfo.image_url,
                    vendorLogo: car.supplier?.logo,
                    rating: car.supplier?.rating,
                    reviewCount: car.supplier?.reviews,
                    bookingURL: "https://www.booking.com/cars"
                )
                
                results.append(result)
            }
            
            let filtered = applyFilters(results, filters: filters)
            let sorted = sortResults(filtered, by: filters.sortBy)
            
            print("✅ Fetched \(sorted.count) car rentals from Booking.com")
            
            await MainActor.run {
                searchResults = sorted
                isSearching = false
            }
            
            return sorted
            
        } catch {
            print("❌ Car Rental API Error: \(error.localizedDescription)")
            let results = generateMockResults(location: pickUpLocation, count: 8)
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
            return results
        }
    }
    
    // MARK: - Apply Filters
    private func applyFilters(_ results: [CarRentalSearchResult], filters: CarRentalFilters) -> [CarRentalSearchResult] {
        return results.filter { car in
            if let maxPrice = filters.maxPrice, car.totalPrice > maxPrice {
                return false
            }
            
            if let minPrice = filters.minPrice, car.totalPrice < minPrice {
                return false
            }
            
            if !filters.carTypes.isEmpty && !filters.carTypes.contains(car.carType) {
                return false
            }
            
            if let transmission = filters.transmissionType, car.transmission != transmission.rawValue {
                return false
            }
            
            if let minSeats = filters.minSeats, car.seats < minSeats {
                return false
            }
            
            if filters.requireAirConditioning && !car.hasAirConditioning {
                return false
            }
            
            if filters.requireGPS && !car.hasGPS {
                return false
            }
            
            if filters.requireUnlimitedMileage && !car.hasUnlimitedMileage {
                return false
            }
            
            if !filters.fuelTypes.isEmpty && !filters.fuelTypes.contains(car.fuelType) {
                return false
            }
            
            return true
        }
    }
    
    // MARK: - Sort Results
    private func sortResults(_ results: [CarRentalSearchResult], by sortOption: CarRentalFilters.SortOption) -> [CarRentalSearchResult] {
        switch sortOption {
        case .priceLowToHigh:
            return results.sorted { $0.totalPrice < $1.totalPrice }
        case .priceHighToLow:
            return results.sorted { $0.totalPrice > $1.totalPrice }
        case .seats:
            return results.sorted { $0.seats > $1.seats }
        case .rating:
            return results.sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
        }
    }
    
    // MARK: - Generate Mock Data
    private func generateMockResults(location: String, count: Int) -> [CarRentalSearchResult] {
        let carTypes = ["Economy", "Compact", "Mid-size", "Full-size", "SUV", "Luxury", "Van"]
        let companies = ["Hertz", "Enterprise", "Avis", "Budget", "National", "Alamo"]
        let transmissions = ["Automatic", "Manual"]
        let fuelTypes = ["Gasoline", "Diesel", "Electric", "Hybrid"]
        
        let carModels = [
            "Toyota Corolla", "Honda Civic", "Ford Focus", "Chevrolet Cruze",
            "Toyota Camry", "Honda Accord", "Nissan Altima", "Ford Fusion",
            "Toyota RAV4", "Honda CR-V", "Ford Explorer", "Chevrolet Tahoe",
            "BMW 3 Series", "Mercedes C-Class", "Audi A4", "Tesla Model 3",
            "Chrysler Pacifica", "Honda Odyssey", "Toyota Sienna"
        ]
        
        return (0..<count).map { index in
            let carType = carTypes[index % carTypes.count]
            let basePrice = Double.random(in: 30...200)
            let days = 3
            
            return CarRentalSearchResult(
                id: UUID().uuidString,
                carName: carModels[index % carModels.count],
                company: companies[index % companies.count],
                carType: carType,
                transmission: transmissions[index % 2],
                seats: carType.contains("Van") ? 7 : (carType.contains("SUV") ? 5 : 5),
                doors: carType.contains("Van") ? 5 : 4,
                fuelType: fuelTypes[index % fuelTypes.count],
                pricePerDay: basePrice,
                totalPrice: basePrice * Double(days),
                currency: "USD",
                hasAirConditioning: true,
                hasGPS: index % 3 == 0,
                hasUnlimitedMileage: index % 2 == 0,
                features: index % 2 == 0 ? ["Bluetooth", "Backup Camera"] : ["USB Ports"],
                imageURL: nil,
                vendorLogo: nil,
                rating: Double.random(in: 7.0...9.5),
                reviewCount: Int.random(in: 50...500),
                bookingURL: "https://www.booking.com/cars"
            )
        }
    }
}
