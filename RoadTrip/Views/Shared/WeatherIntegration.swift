//
//  WeatherIntegration.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import SwiftUI

// MARK: - Weather-Aware Planning Manager
class WeatherPlanningManager: ObservableObject {
    static let shared = WeatherPlanningManager()
    
    @Published var weatherAlerts: [WeatherAlert] = []
    
    struct WeatherAlert: Identifiable {
        let id = UUID()
        let severity: AlertSeverity
        let message: String
        let activityId: UUID?
        let dayNumber: Int?
        
        enum AlertSeverity {
            case info
            case warning
            case severe
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .warning: return .orange
                case .severe: return .red
                }
            }
            
            var icon: String {
                switch self {
                case .info: return "info.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .severe: return "exclamationmark.octagon.fill"
                }
            }
        }
    }
    
    private init() {}
    
    func analyzeWeatherForTrip(_ trip: Trip) async {
        await MainActor.run {
            weatherAlerts.removeAll()
        }
        
        for day in trip.safeDays {
            // Get weather for the day's start location
            if !day.startLocation.isEmpty {
                if let weather = await WeatherService.shared.fetchWeather(for: day.startLocation, date: day.date) {
                    await analyzeWeatherConditions(weather: weather, for: day)
                }
            }
            
            // Analyze activities
            for activity in day.activities {
                if let weather = await WeatherService.shared.fetchWeather(for: activity.location, date: day.date) {
                    await suggestIndoorAlternatives(for: activity, weather: weather, day: day)
                }
            }
        }
    }
    
    @MainActor
    private func analyzeWeatherConditions(weather: WeatherData, for day: TripDay) {
        if weather.isBadWeather {
            let message: String
            
            if weather.precipitationChance > 0.7 {
                message = "High chance of rain on Day \(day.dayNumber). Consider indoor activities."
            } else if weather.temperatureHigh > 100 {
                message = "Extreme heat on Day \(day.dayNumber) (\(Int(weather.temperatureHigh))°F). Plan for shade and water."
            } else if weather.temperatureLow < 32 {
                message = "Freezing temperatures on Day \(day.dayNumber). Dress warmly!"
            } else if weather.condition == .thunderstorm {
                message = "Thunderstorms expected on Day \(day.dayNumber). Avoid outdoor activities."
            } else {
                message = "Poor weather conditions on Day \(day.dayNumber). Check forecast."
            }
            
            weatherAlerts.append(WeatherAlert(
                severity: weather.condition == .thunderstorm ? .severe : .warning,
                message: message,
                activityId: nil,
                dayNumber: day.dayNumber
            ))
        }
    }
    
    @MainActor
    private func suggestIndoorAlternatives(for activity: Activity, weather: WeatherData, day: TripDay) {
        // Only suggest for outdoor activities in bad weather
        guard weather.isBadWeather && 
              (activity.category == "Attraction" || activity.category == "Other") else {
            return
        }
        
        weatherAlerts.append(WeatherAlert(
            severity: .info,
            message: "Consider indoor alternative for '\(activity.name)' - \(weather.conditionDescription) expected",
            activityId: activity.id,
            dayNumber: day.dayNumber
        ))
    }
    
    func getIndoorSuggestions(for location: String) -> [String] {
        [
            "Visit a museum",
            "Explore an aquarium",
            "Check out local shopping",
            "Try indoor activities (arcade, bowling)",
            "Visit a library or bookstore",
            "See a movie or show"
        ]
    }
}

// MARK: - Weather Forecast View
struct WeatherForecastView: View {
    let day: TripDay
    @StateObject private var weatherService = WeatherService.shared
    @State private var forecast: [WeatherData] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun.fill")
                    .foregroundStyle(.blue)
                Text("Weather Forecast")
                    .font(.headline)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if !forecast.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(forecast) { weather in
                            WeatherCard(weather: weather)
                        }
                    }
                }
            } else if !isLoading {
                Text("No forecast available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .task {
            await loadForecast()
        }
    }
    
    func loadForecast() async {
        guard !day.startLocation.isEmpty else { return }
        
        await MainActor.run {
            isLoading = true
        }
        
        var newForecast: [WeatherData] = []
        
        // Get 7-day forecast starting from day's date
        for i in 0..<7 {
            if let forecastDate = Calendar.current.date(byAdding: .day, value: i, to: day.date) {
                if let weather = await weatherService.fetchWeather(for: day.startLocation, date: forecastDate) {
                    newForecast.append(weather)
                }
            }
        }
        
        await MainActor.run {
            forecast = newForecast
            isLoading = false
        }
    }
}

struct WeatherCard: View {
    let weather: WeatherData
    
    var body: some View {
        VStack(spacing: 8) {
            Text(weather.date, format: .dateTime.weekday(.abbreviated))
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Image(systemName: weather.conditionIcon)
                .font(.title2)
                .foregroundStyle(weather.isBadWeather ? .red : .blue)
            
            Text("\(Int(weather.temperatureHigh))°")
                .font(.title3)
                .fontWeight(.bold)
            
            Text("\(Int(weather.temperatureLow))°")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if weather.precipitationChance > 0.3 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                    Text("\(Int(weather.precipitationChance * 100))%")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(weather.isBadWeather ? Color.red.opacity(0.1) : Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Weather Alerts View
struct WeatherAlertsView: View {
    let trip: Trip
    @StateObject private var planningManager = WeatherPlanningManager.shared
    @State private var isAnalyzing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text("Weather Alerts")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    analyzeWeather()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .disabled(isAnalyzing)
            }
            
            if isAnalyzing {
                HStack {
                    ProgressView()
                    Text("Analyzing weather...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if planningManager.weatherAlerts.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("No weather concerns")
                        .font(.subheadline)
                }
            } else {
                ForEach(planningManager.weatherAlerts) { alert in
                    WeatherAlertRow(alert: alert)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .task {
            analyzeWeather()
        }
    }
    
    func analyzeWeather() {
        Task {
            await MainActor.run {
                isAnalyzing = true
            }
            
            await planningManager.analyzeWeatherForTrip(trip)
            
            await MainActor.run {
                isAnalyzing = false
            }
        }
    }
}

struct WeatherAlertRow: View {
    let alert: WeatherPlanningManager.WeatherAlert
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: alert.severity.icon)
                .foregroundStyle(alert.severity.color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.message)
                    .font(.subheadline)
                
                if let dayNumber = alert.dayNumber {
                    Text("Day \(dayNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Indoor Activity Suggestions
struct IndoorActivitySuggestionsView: View {
    let location: String
    @StateObject private var planningManager = WeatherPlanningManager.shared
    
    var suggestions: [String] {
        planningManager.getIndoorSuggestions(for: location)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "house.fill")
                    .foregroundStyle(.blue)
                Text("Indoor Activity Ideas")
                    .font(.headline)
            }
            
            ForEach(suggestions, id: \.self) { suggestion in
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundStyle(.blue)
                        .font(.caption)
                    Text(suggestion)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Weather-Based Activity Scoring
extension Activity {
    func weatherSuitabilityScore(for weather: WeatherData) -> Double {
        var score = 1.0
        
        // Reduce score for outdoor activities in bad weather
        if category == "Attraction" {
            if weather.precipitationChance > 0.5 {
                score *= 0.3
            }
            if weather.temperatureHigh > 95 || weather.temperatureLow < 40 {
                score *= 0.6
            }
        }
        
        // Indoor activities (Food, Shopping) are better in bad weather
        if category == "Food" || category == "Shopping" {
            if weather.isBadWeather {
                score *= 1.5
            }
        }
        
        return min(score, 1.0)
    }
}
