//
//  RoadTripWidget.swift
//  RoadTripWidget
//
//  Created for RoadTrip app
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Entry
struct TripEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let tripName: String?
    let nextDestination: String?
    let todayActivities: [WidgetActivity]
    let daysUntilTrip: Int?
    let tripStartDate: Date?
    let totalActivitiesToday: Int
    let completedActivities: Int
}

struct WidgetActivity: Identifiable {
    let id = UUID()
    let name: String
    let time: String
    let category: String
    let isCompleted: Bool
}

// MARK: - App Intent
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Trip"
    static var description: IntentDescription = "Choose which trip to display"
    
    @Parameter(title: "Show Upcoming Trip", default: true)
    var showUpcomingTrip: Bool
}

// MARK: - Timeline Provider
struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TripEntry {
        TripEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            tripName: "Road Trip",
            nextDestination: "Los Angeles, CA",
            todayActivities: [
                WidgetActivity(name: "Visit Beach", time: "10:00 AM", category: "Attraction", isCompleted: false),
                WidgetActivity(name: "Lunch", time: "12:30 PM", category: "Food", isCompleted: false)
            ],
            daysUntilTrip: 5,
            tripStartDate: Date().addingTimeInterval(5 * 86400),
            totalActivitiesToday: 4,
            completedActivities: 1
        )
    }
    
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> TripEntry {
        // Return sample data for preview
        TripEntry(
            date: Date(),
            configuration: configuration,
            tripName: "Summer Road Trip",
            nextDestination: "San Francisco, CA",
            todayActivities: [
                WidgetActivity(name: "Golden Gate Bridge", time: "9:00 AM", category: "Attraction", isCompleted: true),
                WidgetActivity(name: "Fisherman's Wharf", time: "12:00 PM", category: "Food", isCompleted: false)
            ],
            daysUntilTrip: 3,
            tripStartDate: Date().addingTimeInterval(3 * 86400),
            totalActivitiesToday: 5,
            completedActivities: 2
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<TripEntry> {
        // Load trip data using App Groups
        let entry = await loadTripData(configuration: configuration)
        
        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    @MainActor
    private func loadTripData(configuration: ConfigurationAppIntent) async -> TripEntry {
        // For now, return placeholder - real implementation would use App Groups and SwiftData
        // This would require setting up App Groups in the project for data sharing
        
        return TripEntry(
            date: Date(),
            configuration: configuration,
            tripName: nil,
            nextDestination: nil,
            todayActivities: [],
            daysUntilTrip: nil,
            tripStartDate: nil,
            totalActivitiesToday: 0,
            completedActivities: 0
        )
    }
}

// MARK: - Widget Views

struct RoadTripWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget
struct SmallWidgetView: View {
    let entry: TripEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background gradient with dark mode support
            LinearGradient(
                colors: colorScheme == .dark 
                    ? [Color.blue.opacity(0.4), Color.purple.opacity(0.3)]
                    : [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if let tripName = entry.tripName {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "car.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                        Spacer()
                        if let days = entry.daysUntilTrip, days > 0 {
                            Text("\(days)d")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.white.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                    
                    Text(tripName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    if let destination = entry.nextDestination {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.caption2)
                            Text(destination)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding()
            } else {
                // Empty state
                VStack(spacing: 8) {
                    Image(systemName: "car.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.6))
                    Text("No Trips")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }
}

// MARK: - Medium Widget
struct MediumWidgetView: View {
    let entry: TripEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark 
                    ? [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]
                    : [Color.blue.opacity(0.5), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if let tripName = entry.tripName {
                HStack(spacing: 16) {
                    // Left side - Trip info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "car.fill")
                                .font(.title3)
                            if let days = entry.daysUntilTrip, days > 0 {
                                Text("in \(days) days")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else if entry.daysUntilTrip == 0 {
                                Text("TODAY!")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .foregroundStyle(.white)
                        
                        Text(tripName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        
                        Spacer()
                        
                        if let destination = entry.nextDestination {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.caption)
                                Text(destination)
                                    .font(.caption)
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Right side - Activities
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Today's Activities")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white.opacity(0.7))
                        
                        if entry.todayActivities.isEmpty {
                            Text("No activities")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        } else {
                            ForEach(entry.todayActivities.prefix(3)) { activity in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(activity.isCompleted ? Color.green : Color.white.opacity(0.3))
                                        .frame(width: 8, height: 8)
                                    Text(activity.name)
                                        .font(.caption)
                                        .lineLimit(1)
                                        .foregroundStyle(.white)
                                }
                            }
                            
                            if entry.totalActivitiesToday > 3 {
                                Text("+\(entry.totalActivitiesToday - 3) more")
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            } else {
                EmptyWidgetView()
            }
        }
    }
}

// MARK: - Large Widget
struct LargeWidgetView: View {
    let entry: TripEntry
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: colorScheme == .dark 
                    ? [Color.blue.opacity(0.3), Color.purple.opacity(0.2)]
                    : [Color.blue.opacity(0.5), Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            if let tripName = entry.tripName {
                VStack(alignment: .leading, spacing: 12) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                Text(tripName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                            
                            if let destination = entry.nextDestination {
                                HStack(spacing: 4) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.caption)
                                    Text("Next: \(destination)")
                                        .font(.caption)
                                }
                                .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        if let days = entry.daysUntilTrip {
                            VStack(spacing: 2) {
                                Text("\(days)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                Text(days == 1 ? "day" : "days")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    Divider()
                        .background(.white.opacity(0.3))
                    
                    // Today's activities
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today's Schedule")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Text("\(entry.completedActivities)/\(entry.totalActivitiesToday)")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        
                        if entry.todayActivities.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 4) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.title2)
                                    Text("No activities scheduled")
                                        .font(.caption)
                                }
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.vertical)
                                Spacer()
                            }
                        } else {
                            ForEach(entry.todayActivities.prefix(5)) { activity in
                                HStack(spacing: 12) {
                                    Image(systemName: activity.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.subheadline)
                                        .foregroundStyle(activity.isCompleted ? .green : .white.opacity(0.5))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(activity.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                        Text(activity.time)
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.7))
                                    }
                                    .foregroundStyle(.white)
                                    
                                    Spacer()
                                    
                                    Text(activity.category)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(categoryColor(activity.category).opacity(0.3))
                                        .clipShape(Capsule())
                                        .foregroundStyle(.white)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                EmptyWidgetView()
            }
        }
    }
    
    func categoryColor(_ category: String) -> Color {
        switch category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
}

// MARK: - Empty State
struct EmptyWidgetView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.5))
            
            Text("No Trips Planned")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("Open RoadTrip to start planning")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Widget Definition
struct RoadTripWidget: Widget {
    let kind: String = "RoadTripWidget"
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            RoadTripWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Road Trip")
        .description("See your upcoming trip and today's activities at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    RoadTripWidget()
} timeline: {
    TripEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        tripName: "Summer Road Trip",
        nextDestination: "San Francisco",
        todayActivities: [],
        daysUntilTrip: 5,
        tripStartDate: Date().addingTimeInterval(5 * 86400),
        totalActivitiesToday: 0,
        completedActivities: 0
    )
}

#Preview(as: .systemMedium) {
    RoadTripWidget()
} timeline: {
    TripEntry(
        date: Date(),
        configuration: ConfigurationAppIntent(),
        tripName: "California Coast",
        nextDestination: "Big Sur",
        todayActivities: [
            WidgetActivity(name: "Pfeiffer Beach", time: "10:00 AM", category: "Attraction", isCompleted: true),
            WidgetActivity(name: "Nepenthe", time: "1:00 PM", category: "Food", isCompleted: false),
            WidgetActivity(name: "McWay Falls", time: "3:30 PM", category: "Attraction", isCompleted: false)
        ],
        daysUntilTrip: 0,
        tripStartDate: Date(),
        totalActivitiesToday: 5,
        completedActivities: 1
    )
}
