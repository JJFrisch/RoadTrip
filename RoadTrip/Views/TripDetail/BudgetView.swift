// Views/TripDetail/BudgetView.swift
import SwiftUI
import Charts

struct BudgetView: View {
    private struct DailyTrendPoint: Identifiable {
        let id = UUID()
        let dayLabel: String
        let actual: Double
        let forecast: Double
    }

    let trip: Trip
    @Environment(\.colorScheme) private var colorScheme
    @State private var weatherData: [UUID: WeatherData] = [:]
    @State private var isLoadingWeather = false
    
    private let costCategories = ["Gas", "Food", "Lodging", "Attractions", "Other"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                // Budget Summary Card
                budgetSummaryCard

                // Budget Health + Runway
                if trip.totalBudget != nil {
                    budgetHealthCard
                }
                
                // Budget Breakdown Chart
                if trip.estimatedTotalCost > 0 {
                    budgetChartCard
                }

                // Budget Trend Forecast
                if !dailyTrendPoints.isEmpty {
                    budgetTrendForecastCard
                }
                
                // Weather Forecast Section
                weatherSection
                
                // Per-Day Budget Breakdown
                perDayBreakdown
            }
            .padding(AppTheme.Spacing.md)
        }
        .background(AppTheme.Colors.background)
        .onAppear {
            loadWeather()
        }
    }

    // MARK: - Budget Trend Forecast

    private var dailyTrendPoints: [DailyTrendPoint] {
        let sortedDays = trip.days.sorted { $0.dayNumber < $1.dayNumber }
        guard !sortedDays.isEmpty else { return [] }

        var points: [DailyTrendPoint] = []
        var runningTotal = 0.0

        for (index, day) in sortedDays.enumerated() {
            let lodgingCost = day.hotel?.pricePerNight ?? 0
            let actual = day.activities.reduce(0) { $0 + ($1.estimatedCost ?? 0) } + lodgingCost
            runningTotal += actual

            let rollingAverage = runningTotal / Double(index + 1)
            points.append(
                DailyTrendPoint(
                    dayLabel: "D\(day.dayNumber)",
                    actual: actual,
                    forecast: rollingAverage
                )
            )
        }

        return points
    }

    private var projectedTripTotal: Double {
        guard let lastForecast = dailyTrendPoints.last?.forecast else { return 0 }
        return lastForecast * Double(max(trip.days.count, 1))
    }

    private var forecastDeltaToBudget: Double? {
        guard let budget = trip.totalBudget else { return nil }
        return projectedTripTotal - budget
    }

    private var budgetTrendForecastCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                    Text("Spend Trend + Forecast")
                        .font(AppTheme.Typography.headline)
                    Text("Daily spend compared to projected trajectory")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                }

                Spacer()

                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundStyle(AppTheme.Colors.primary)
            }

            Chart(dailyTrendPoints) { point in
                BarMark(
                    x: .value("Day", point.dayLabel),
                    y: .value("Actual", point.actual)
                )
                .foregroundStyle(Color.blue.opacity(0.35))

                LineMark(
                    x: .value("Day", point.dayLabel),
                    y: .value("Forecast", point.forecast)
                )
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                .foregroundStyle(Color.orange)

                PointMark(
                    x: .value("Day", point.dayLabel),
                    y: .value("Forecast", point.forecast)
                )
                .foregroundStyle(Color.orange)
            }
            .frame(height: 210)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Projected Total")
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                    Text(String(format: "$%.2f", projectedTripTotal))
                        .font(AppTheme.Typography.headline)
                        .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                }

                Spacer()

                if let delta = forecastDeltaToBudget {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(delta > 0 ? "Projected Overrun" : "Projected Buffer")
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                        Text(String(format: "$%.2f", abs(delta)))
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(delta > 0 ? .red : .green)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: AppTheme.Shadows.small.color, radius: AppTheme.Shadows.small.radius, x: AppTheme.Shadows.small.x, y: AppTheme.Shadows.small.y)
    }

    // MARK: - Budget Health Card

    private var budgetHealthCard: some View {
        let totalBudget = max(trip.totalBudget ?? 0, 0)
        let estimatedSpend = max(trip.estimatedTotalCost, 0)
        let utilization = totalBudget > 0 ? min(estimatedSpend / totalBudget, 1) : 0
        let remaining = max(totalBudget - estimatedSpend, 0)
        let overBudgetAmount = max(estimatedSpend - totalBudget, 0)

        return VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Budget Health")
                        .font(AppTheme.Typography.headline)
                    Text(statusText(for: utilization, isOverBudget: overBudgetAmount > 0))
                        .font(.caption)
                        .foregroundStyle(statusColor(for: utilization, isOverBudget: overBudgetAmount > 0))
                }

                Spacer()

                Text("\(Int(utilization * 100))%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(statusColor(for: utilization, isOverBudget: overBudgetAmount > 0))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor(for: utilization, isOverBudget: overBudgetAmount > 0).opacity(0.15))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: utilization)
                    .tint(statusColor(for: utilization, isOverBudget: overBudgetAmount > 0))

                HStack {
                    Text(String(format: "$%.2f spent", estimatedSpend))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(String(format: "$%.2f budget", totalBudget))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "$%.2f", remaining))
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(overBudgetAmount > 0 ? "Over Budget" : "Buffer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "$%.2f", overBudgetAmount > 0 ? overBudgetAmount : remaining))
                        .font(.headline)
                        .foregroundStyle(overBudgetAmount > 0 ? .red : .blue)
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(
            LinearGradient(
                colors: [AppTheme.Colors.secondaryBackground, statusColor(for: utilization, isOverBudget: overBudgetAmount > 0).opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppTheme.CornerRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(statusColor(for: utilization, isOverBudget: overBudgetAmount > 0).opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Budget Summary Card
    
    private var budgetSummaryCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
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
                    .foregroundStyle(AppTheme.Colors.primary.gradient)
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
                    
                    let perDay = trip.days.isEmpty ? 0 : trip.estimatedTotalCost / Double(trip.days.count)
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
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: AppTheme.Shadows.small.color, radius: AppTheme.Shadows.small.radius, x: AppTheme.Shadows.small.x, y: AppTheme.Shadows.small.y)
    }
    
    // MARK: - Budget Chart Card
    
    private var budgetChartCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: AppTheme.Shadows.small.color, radius: AppTheme.Shadows.small.radius, x: AppTheme.Shadows.small.x, y: AppTheme.Shadows.small.y)
    }
    
    // MARK: - Weather Section
    
    private var weatherSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
                        ForEach(trip.days.sorted { $0.dayNumber < $1.dayNumber }) { day in
                            if let weather = weatherData[day.id] {
                                WeatherDayCard(day: day, weather: weather)
                            }
                        }
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: AppTheme.Shadows.small.color, radius: AppTheme.Shadows.small.radius, x: AppTheme.Shadows.small.x, y: AppTheme.Shadows.small.y)
    }
    
    // MARK: - Per Day Breakdown
    
    private var perDayBreakdown: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Daily Costs")
                .font(.headline)
            
            ForEach(trip.days.sorted { $0.dayNumber < $1.dayNumber }) { day in
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
                .background(AppTheme.Colors.background)
                .cornerRadius(AppTheme.CornerRadius.medium)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.Colors.secondaryBackground)
        .cornerRadius(AppTheme.CornerRadius.large)
        .shadow(color: AppTheme.Shadows.small.color, radius: AppTheme.Shadows.small.radius, x: AppTheme.Shadows.small.x, y: AppTheme.Shadows.small.y)
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

    private func statusText(for utilization: Double, isOverBudget: Bool) -> String {
        if isOverBudget {
            return "Over budget"
        }
        if utilization >= 0.9 {
            return "Critical runway"
        }
        if utilization >= 0.7 {
            return "Watch spending"
        }
        return "On track"
    }

    private func statusColor(for utilization: Double, isOverBudget: Bool) -> Color {
        if isOverBudget {
            return .red
        }
        if utilization >= 0.9 {
            return .orange
        }
        if utilization >= 0.7 {
            return .yellow
        }
        return .green
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
