//
//  SiriShortcutsSupport.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import AppIntents

// MARK: - Siri Shortcut Intents

struct StartTripIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Trip"
    static let description: LocalizedStringResource = "Mark a trip as started"
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Trip Name")
    var tripName: String?
    
    func perform() async throws -> some IntentResult {
        // TODO: Implement trip start logic
        // This would integrate with TripDetailView to set trip status
        return .result(value: "Trip started: \(tripName ?? "Unknown")")
    }
}

struct AddActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Activity"
    static let description: LocalizedStringResource = "Add an activity to today's trip"
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Activity Name")
    var activityName: String
    
    @Parameter(title: "Location", default: "")
    var location: String
    
    @Parameter(title: "Category", default: "Other")
    var category: String // "Food", "Attraction", "Hotel", "Other"
    
    @Parameter(title: "Time", default: "")
    var time: String
    
    func perform() async throws -> some IntentResult {
        // TODO: Create new activity with provided details
        return .result(value: "Added \(activityName) to your trip")
    }
}

struct CheckActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Activity"
    static let description: LocalizedStringResource = "Mark an activity as completed"
    static let openAppWhenRun: Bool = true
    
    @Parameter(title: "Activity Name")
    var activityName: String
    
    func perform() async throws -> some IntentResult {
        // TODO: Mark activity as completed
        return .result(value: "Marked '\(activityName)' as completed")
    }
}

struct GetNextActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "What's Next?"
    static let description: LocalizedStringResource = "Get the next activity on your itinerary"
    static let openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // TODO: Query current trip and get next activity
        return .result(value: "Next activity is at 2:00 PM")
    }
}

struct NavigateToActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "Navigate to Activity"
    static let description: LocalizedStringResource = "Open Maps to next activity location"
    static let openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // TODO: Get next activity and open Apple Maps
        // Would use MapKit to open navigation
        return .result()
    }
}

struct GetTripStatsIntent: AppIntent {
    static let title: LocalizedStringResource = "Trip Statistics"
    static let description: LocalizedStringResource = "Get trip progress and statistics"
    static let openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // TODO: Calculate and return trip stats
        // - Days remaining
        // - Activities completed
        // - Budget status
        // - Miles traveled
        return .result(value: "5 days left, 12 of 25 activities completed")
    }
}

struct ShareTripIntent: AppIntent {
    static let title: LocalizedStringResource = "Share Trip"
    static let description: LocalizedStringResource = "Generate a share link for your trip"
    static let openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // TODO: Generate share code and display QR
        return .result()
    }
}

// MARK: - Shortcut-Friendly Models

struct ShortcutTrip: Identifiable {
    let id: UUID
    let name: String
    let startDate: Date
    let endDate: Date
    let nextActivityName: String?
    let nextActivityTime: String?
    let totalActivities: Int
    let completedActivities: Int
    let daysRemaining: Int
}

struct ShortcutActivity: Identifiable {
    let id: UUID
    let name: String
    let time: String
    let location: String
    let category: String
    let isCompleted: Bool
}

// MARK: - Suggested Shortcuts Configuration

struct SuggestedShortcutsConfiguration {
    static let suggestedShortcuts: [ShortcutDefinition] = [
        ShortcutDefinition(
            title: "Start My Day",
            description: "Get today's schedule and weather",
            intents: ["GetNextActivityIntent", "GetTripStatsIntent"]
        ),
        ShortcutDefinition(
            title: "Mark Complete & Navigate Next",
            description: "Complete current activity and navigate to next",
            intents: ["CheckActivityIntent", "NavigateToActivityIntent"]
        ),
        ShortcutDefinition(
            title: "Quick Add Activity",
            description: "Quickly add an activity to today",
            intents: ["AddActivityIntent"]
        ),
        ShortcutDefinition(
            title: "Trip Overview",
            description: "Get complete trip statistics",
            intents: ["GetTripStatsIntent"]
        ),
        ShortcutDefinition(
            title: "Share Trip Progress",
            description: "Share current trip with others",
            intents: ["ShareTripIntent"]
        )
    ]
}

struct ShortcutDefinition {
    let title: String
    let description: String
    let intents: [String]
}

// MARK: - Voice Command Suggestions

enum VoiceCommandSuggestion: String, CaseIterable {
    case nextActivity = "Hey Siri, what's next on my trip?"
    case startTrip = "Hey Siri, start my trip"
    case completeActivity = "Hey Siri, I'm done with that"
    case navigateNext = "Hey Siri, navigate to my next activity"
    case tripStats = "Hey Siri, how's my trip going?"
    case addActivity = "Hey Siri, add a lunch activity"
    case shareTrip = "Hey Siri, share my trip"
    
    var icon: String {
        switch self {
        case .nextActivity: return "clock"
        case .startTrip: return "flag.fill"
        case .completeActivity: return "checkmark.circle"
        case .navigateNext: return "location.fill"
        case .tripStats: return "chart.bar"
        case .addActivity: return "plus.circle"
        case .shareTrip: return "square.and.arrow.up"
        }
    }
}
