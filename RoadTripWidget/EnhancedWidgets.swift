//
//  EnhancedWidgets.swift
//  RoadTripWidget
//
//  Created by Jake Frischmann on 1/4/26.
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Activity Countdown Widget
struct ActivityCountdownWidget: View {
    let entry: TripEntry
    
    var nextActivityTime: String {
        guard let firstIncomplete = entry.todayActivities.first(where: { !$0.isCompleted }) else {
            return "No activities"
        }
        return firstIncomplete.time
    }
    
    var hoursUntilNextActivity: String {
        let timeFormatter = DateComponentsFormatter()
        timeFormatter.allowedUnits = [.hour, .minute]
        timeFormatter.unitsStyle = .abbreviated
        
        // Parse time string to calculate remaining time
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Estimate: this is simplified, real implementation would use actual times
        if let nextActivity = entry.todayActivities.first(where: { !$0.isCompleted }) {
            return "→ \(nextActivity.time)"
        }
        
        return "No upcoming"
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "clock.badge.checkmark.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                    
                    Text("Next Activity")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                    
                    Spacer()
                }
                
                if let nextActivity = entry.todayActivities.first(where: { !$0.isCompleted }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(nextActivity.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        
                        HStack(spacing: 8) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(nextActivity.time)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                } else {
                    Text("All activities completed!")
                        .font(.caption)
                        .foregroundStyle(.white)
                }
                
                Spacer()
            }
            .padding()
        }
        .widgetBackground(Color.clear)
    }
}

// MARK: - Trip Countdown Widget
struct TripCountdownWidget: View {
    let entry: TripEntry
    
    var countdownText: String {
        guard let daysUntil = entry.daysUntilTrip else { return "Trip info unavailable" }
        
        switch daysUntil {
        case 0:
            return "🎉 Today's the day!"
        case 1:
            return "Tomorrow!"
        case let days where days < 7:
            return "\(days) days away"
        case let days where days < 30:
            return "\(days / 7) weeks away"
        default:
            return "\(daysUntil) days"
        }
    }
    
    var progressValue: Double {
        guard let startDate = entry.tripStartDate else { return 0 }
        let now = Date()
        
        if now >= startDate {
            return 1.0
        }
        
        // Estimate progress based on days until
        if let daysUntil = entry.daysUntilTrip, daysUntil > 0 {
            return max(0, 1.0 - (Double(daysUntil) / 30.0))
        }
        
        return 0
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.5), Color.red.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                
                VStack(spacing: 4) {
                    Text(entry.tripName ?? "Your Trip")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Text(countdownText)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }
                
                if entry.daysUntilTrip ?? 0 > 0 {
                    ProgressView(value: progressValue)
                        .tint(.white)
                        .scaleEffect(x: 1, y: 0.8, anchor: .center)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
        .widgetBackground(Color.clear)
    }
}

// MARK: - Today's Schedule Widget
struct TodayScheduleWidget: View {
    let entry: TripEntry
    
    var displayedActivities: [WidgetActivity] {
        Array(entry.todayActivities.prefix(3))
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.green.opacity(0.5), Color.teal.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "list.bullet.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                    
                    Text("Today's Schedule")
                        .font(.headline)
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("\(entry.completedActivities)/\(entry.totalActivitiesToday)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.2))
                        .cornerRadius(4)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(displayedActivities) { activity in
                        HStack(spacing: 8) {
                            Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundStyle(activity.isCompleted ? .green : .white.opacity(0.6))
                            
                            VStack(alignment: .leading, spacing: 1) {
                                Text(activity.name)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                    .strikethrough(activity.isCompleted, color: .white.opacity(0.5))
                                
                                Text(activity.time)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: categoryIcon(activity.category))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }
                
                if entry.totalActivitiesToday > 3 {
                    Text("+ \(entry.totalActivitiesToday - 3) more")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
                
                Spacer()
            }
            .padding()
        }
        .widgetBackground(Color.clear)
    }
    
    func categoryIcon(_ category: String) -> String {
        switch category {
        case "Food": return "fork.knife"
        case "Attraction": return "star.fill"
        case "Hotel": return "bed.double.fill"
        default: return "mappin.circle.fill"
        }
    }
}

// MARK: - Combined Widget with Multiple Families
struct CombinedRoadTripWidget: View {
    var entry: TripEntry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            ActivityCountdownWidget(entry: entry)
        case .systemMedium:
            TodayScheduleWidget(entry: entry)
        case .systemLarge:
            LargeScheduleWidget(entry: entry)
        default:
            ActivityCountdownWidget(entry: entry)
        }
    }
}

// MARK: - Large Widget
struct LargeScheduleWidget: View {
    let entry: TripEntry
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.4), Color.blue.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.tripName ?? "Road Trip")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        if let daysUntil = entry.daysUntilTrip, daysUntil > 0 {
                            Text("\(daysUntil) days until departure")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                // Progress
                HStack(spacing: 12) {
                    ProgressView(value: Double(entry.completedActivities) / max(1, Double(entry.totalActivitiesToday)))
                        .tint(.green)
                    
                    Text("\(entry.completedActivities)/\(entry.totalActivitiesToday)")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 35)
                }
                
                // Activities Grid
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(entry.todayActivities) { activity in
                        HStack(spacing: 12) {
                            Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.body)
                                .foregroundStyle(activity.isCompleted ? .green : .white.opacity(0.6))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.name)
                                    .font(.subheadline)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                
                                Text(activity.time)
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .widgetBackground(Color.clear)
    }
}

// MARK: - Widget Background Modifier
extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return AnyView(
                self
                    .containerBackground(for: .widget) {
                        backgroundView
                    }
            )
        } else {
            return AnyView(self)
        }
    }
}
