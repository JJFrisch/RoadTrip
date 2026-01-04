// Services/WeatherService.swift
import Foundation
import CoreLocation

struct WeatherData: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let locationName: String
    let temperature: Double // Fahrenheit
    let temperatureHigh: Double
    let temperatureLow: Double
    let condition: WeatherCondition
    let precipitationChance: Double // 0.0 to 1.0
    let windSpeed: Double // mph
    let humidity: Double // 0.0 to 1.0
    
    var conditionIcon: String {
        condition.icon
    }
    
    var conditionDescription: String {
        condition.description
    }
    
    var isBadWeather: Bool {
        precipitationChance > 0.5 || 
        condition == .rain || 
        condition == .thunderstorm || 
        condition == .snow ||
        temperatureHigh > 100 ||
        temperatureLow < 32
    }
}

enum WeatherCondition: String, CaseIterable, Sendable {
    case sunny
    case partlyCloudy
    case cloudy
    case rain
    case thunderstorm
    case snow
    case fog
    case windy
    case unknown
    
    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .cloudy: return "cloud.fill"
        case .rain: return "cloud.rain.fill"
        case .thunderstorm: return "cloud.bolt.rain.fill"
        case .snow: return "cloud.snow.fill"
        case .fog: return "cloud.fog.fill"
        case .windy: return "wind"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var description: String {
        switch self {
        case .sunny: return "Sunny"
        case .partlyCloudy: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .rain: return "Rainy"
        case .thunderstorm: return "Thunderstorm"
        case .snow: return "Snow"
        case .fog: return "Foggy"
        case .windy: return "Windy"
        case .unknown: return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .sunny: return "yellow"
        case .partlyCloudy: return "blue"
        case .cloudy: return "gray"
        case .rain: return "blue"
        case .thunderstorm: return "purple"
        case .snow: return "cyan"
        case .fog: return "gray"
        case .windy: return "teal"
        case .unknown: return "gray"
        }
    }
}

class WeatherService: ObservableObject {
    static let shared = WeatherService()
    
    @Published var weatherCache: [String: WeatherData] = [:]
    @Published var isLoading = false
    @Published var error: String?
    
    private let geocoder = CLGeocoder()
    
    private init() {}
    
    // MARK: - Fetch Weather
    
    /// Fetches weather for a location on a specific date
    /// Note: For a production app, you'd integrate with a real weather API like OpenWeather, WeatherKit, etc.
    /// This implementation generates realistic mock data based on location and date.
    func fetchWeather(for location: String, date: Date) async -> WeatherData? {
        let cacheKey = "\(location)-\(date.timeIntervalSince1970)"
        
        // Check cache
        if let cached = weatherCache[cacheKey] {
            return cached
        }
        
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        // Geocode the location to get coordinates
        do {
            let placemarks = try await geocoder.geocodeAddressString(location)
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else {
                await MainActor.run {
                    isLoading = false
                    error = "Could not find location"
                }
                return nil
            }
            
            // Generate weather based on location and date
            let weather = generateWeather(for: location, coordinate: coordinate, date: date)
            
            await MainActor.run {
                weatherCache[cacheKey] = weather
                isLoading = false
            }
            
            return weather
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.error = error.localizedDescription
            }
            return nil
        }
    }
    
    // MARK: - Fetch Weather for Trip
    
    func fetchWeatherForTrip(_ trip: Trip) async -> [UUID: WeatherData] {
        var results: [UUID: WeatherData] = [:]
        
        for day in trip.days {
            let location = day.startLocation.isEmpty ? day.endLocation : day.startLocation
            guard !location.isEmpty else { continue }
            
            if let weather = await fetchWeather(for: location, date: day.date) {
                results[day.id] = weather
            }
        }
        
        return results
    }
    
    // MARK: - Mock Weather Generation
    
    /// Generates realistic mock weather based on location latitude and month
    private func generateWeather(for locationName: String, coordinate: CLLocationCoordinate2D, date: Date) -> WeatherData {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let latitude = coordinate.latitude
        
        // Base temperature based on latitude and month (Northern Hemisphere assumptions)
        var baseTemp: Double
        let isWinter = month == 12 || month == 1 || month == 2
        let isSummer = month == 6 || month == 7 || month == 8
        
        if latitude > 45 { // Northern regions
            baseTemp = isWinter ? 25 : (isSummer ? 75 : 50)
        } else if latitude > 35 { // Mid-latitude
            baseTemp = isWinter ? 40 : (isSummer ? 85 : 60)
        } else if latitude > 25 { // Southern US
            baseTemp = isWinter ? 55 : (isSummer ? 95 : 75)
        } else { // Tropical
            baseTemp = isWinter ? 70 : (isSummer ? 90 : 80)
        }
        
        // Add some randomness
        let tempVariation = Double.random(in: -8...8)
        let temperature = baseTemp + tempVariation
        let high = temperature + Double.random(in: 8...15)
        let low = temperature - Double.random(in: 8...15)
        
        // Precipitation chance based on region and season
        var precipChance: Double
        if latitude > 40 && isWinter {
            precipChance = Double.random(in: 0.2...0.5) // Higher chance of snow/rain in northern winter
        } else if isSummer && latitude < 35 {
            precipChance = Double.random(in: 0.3...0.6) // Summer storms in south
        } else {
            precipChance = Double.random(in: 0.05...0.3)
        }
        
        // Determine condition
        let condition: WeatherCondition
        if precipChance > 0.5 {
            if temperature < 35 {
                condition = .snow
            } else if Double.random(in: 0...1) > 0.7 {
                condition = .thunderstorm
            } else {
                condition = .rain
            }
        } else if precipChance > 0.3 {
            condition = .cloudy
        } else if Double.random(in: 0...1) > 0.6 {
            condition = .partlyCloudy
        } else {
            condition = .sunny
        }
        
        return WeatherData(
            date: date,
            locationName: locationName,
            temperature: temperature,
            temperatureHigh: high,
            temperatureLow: low,
            condition: condition,
            precipitationChance: precipChance,
            windSpeed: Double.random(in: 2...20),
            humidity: Double.random(in: 0.3...0.8)
        )
    }
    
    // MARK: - Clear Cache
    
    func clearCache() {
        weatherCache.removeAll()
    }
}

// Make TripDay hashable for dictionary key
extension TripDay: Hashable {
    static func == (lhs: TripDay, rhs: TripDay) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
