// Views/TripDetail/BudgetView.swift
import SwiftUI
import Charts

struct BudgetView: View {
    let trip: Trip
    @State private var weatherData: [UUID: WeatherData] = [:]
    @State private var isLoadingWeather = false
    
    private let costCategories = ["Gas", "Food", "Lodging", "Attractions", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Budget Summary Card
                budgetSummaryCard
                
                // Budget Breakdown Chart
                if trip.estimatedTotalCost > 0 {
                    budgetChartCard
                }
                
                // Weather Forecast Section
                weatherSection
                
                // Per-Day Budget Breakdown
                perDayBreakdown
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .onAppear {
            loadWeather()
        }
    }
    
    // MARK: - Budget Summary Card
    
    private var budgetSummaryCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trip Budget")
                        .font(.headline)
                    Text("Estimated costs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title)
                    .foregroundStyle(.green.gradient)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Estimated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(String(format: "$%.2f", trip.estimatedTotalCost))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Per Day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    let perDay = trip.safeDays.isEmpty ? 0 : trip.estimatedTotalCost / Double(trip.safeDays.count)
                    Text(String(format: "$%.2f", perDay))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
            }
            
            // Category breakdown pills
            if !trip.budgetBreakdown.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(trip.budgetBreakdown, id: \.category) { item in
                            HStack(spacing: 4) {
                                Image(systemName: iconForCategory(item.category))
                                    .font(.caption)
                                Text(String(format: "$%.0f", item.amount))
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(colorForCategory(item.category).opacity(0.2))
                            .foregroundStyle(colorForCategory(item.category))
                            .cornerRadius(12)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    // MARK: - Budget Chart Card
    
    private var budgetChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget Breakdown")
                .font(.headline)
            
            Chart(trip.budgetBreakdown, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.amount),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(colorForCategory(item.category))
                .cornerRadius(4)
            }
            .frame(height: 200)
            
            // Legend
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(trip.budgetBreakdown, id: \.category) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(colorForCategory(item.category))
                            .frame(width: 10, height: 10)
                        
                        Text(item.category)
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(String(format: "$%.0f", item.amount))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    // MARK: - Weather Section
    
    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weather Forecast")
                    .font(.headline)
                
                Spacer()
                
                if isLoadingWeather {
                    ProgressView()
                        .scaleEffect(0.8)
                }
                
                Button {
                    loadWeather()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
            }
            
            if weatherData.isEmpty && !isLoadingWeather {
                HStack {
                    Image(systemName: "cloud.sun")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    
                    Text("Set day locations to see weather forecast")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(trip.safeDays.sorted { $0.dayNumber < $1.dayNumber }) { day in
                            if let weather = weatherData[day.id] {
                                WeatherDayCard(day: day, weather: weather)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    // MARK: - Per Day Breakdown
    
    private var perDayBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Costs")
                .font(.headline)
            
            ForEach(trip.safeDays.sorted { $0.dayNumber < $1.dayNumber }) { day in
                let lodgingCost = day.hotel?.pricePerNight ?? 0
                let activityCost = day.activities.reduce(0) { $0 + ($1.estimatedCost ?? 0) }
                let dayCost = activityCost + lodgingCost
                
                VStack(spacing: 8) {
                    HStack {
                        Text("Day \(day.dayNumber)")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text(String(format: "$%.2f", dayCost))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(dayCost > 0 ? .green : .secondary)
                    }
                    
                    if dayCost > 0 {
                        if let hotel = day.hotel, let price = hotel.pricePerNight, price > 0 {
                            HStack {
                                Image(systemName: iconForCategory("Lodging"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)

                                Text(hotel.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(String(format: "$%.2f", price))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 8)
                        }

                        // Show activities with costs
                        ForEach(day.activities.filter { $0.estimatedCost != nil && $0.estimatedCost! > 0 }) { activity in
                            HStack {
                                Image(systemName: iconForCategory(activity.costCategory ?? "Other"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                
                                Text(activity.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text(String(format: "$%.2f", activity.estimatedCost ?? 0))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
    
    // MARK: - Helpers
    
    private func loadWeather() {
        isLoadingWeather = true
        Task {
            let data = await WeatherService.shared.fetchWeatherForTrip(trip)
            await MainActor.run {
                weatherData = data
                isLoadingWeather = false
            }
        }
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Gas": return "fuelpump.fill"
        case "Food": return "fork.knife"
        case "Lodging": return "bed.double.fill"
        case "Attractions": return "star.fill"
        default: return "dollarsign.circle"
        }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "Gas": return .orange
        case "Food": return .red
        case "Lodging": return .purple
        case "Attractions": return .blue
        default: return .gray
        }
    }
}

// MARK: - Weather Day Card

struct WeatherDayCard: View {
    let day: TripDay
    let weather: WeatherData
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Day \(day.dayNumber)")
                .font(.caption)
                .fontWeight(.semibold)
            
            Image(systemName: weather.conditionIcon)
                .font(.title)
                .foregroundStyle(colorForCondition(weather.condition))
            
            Text("\(Int(weather.temperatureHigh))°")
                .font(.headline)
            
            Text("\(Int(weather.temperatureLow))°")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if weather.precipitationChance > 0.2 {
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                    Text("\(Int(weather.precipitationChance * 100))%")
                        .font(.caption2)
                }
                .foregroundStyle(.blue)
            }
            
            if weather.isBadWeather {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .frame(width: 70)
        .padding()
        .background(weather.isBadWeather ? Color.orange.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(weather.isBadWeather ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
    
    private func colorForCondition(_ condition: WeatherCondition) -> Color {
        switch condition {
        case .sunny: return .yellow
        case .partlyCloudy: return .blue
        case .cloudy: return .gray
        case .rain: return .blue
        case .thunderstorm: return .purple
        case .snow: return .cyan
        case .fog: return .gray
        case .windy: return .teal
        case .unknown: return .gray
        }
    }
}
