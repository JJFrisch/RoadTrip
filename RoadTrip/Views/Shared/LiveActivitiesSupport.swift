//
//  LiveActivitiesSupport.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import ActivityKit
import WidgetKit

// MARK: - Activity Attributes (for Live Activities)

struct TripActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentActivityName: String
        var currentActivityTime: String
        var nextActivityName: String?
        var nextActivityTime: String?
        var nextActivityDistance: String?
        var progressPercentage: Double
        var completedCount: Int
        var totalCount: Int
        var estimatedArrivalTime: Date?
    }
    
    var tripName: String
    var tripDay: Int
    var totalDays: Int
    var currentLocation: String
    var nextLocation: String?
}

// MARK: - Dynamic Island Activity Manager

class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<TripActivityAttributes>?
    
    private init() {}
    
    /// Start a live activity for the current trip
    func startTripActivity(
        trip: Trip,
        day: TripDay,
        activity: Activity
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return
        }
        
        let attributes = TripActivityAttributes(
            tripName: trip.name,
            tripDay: day.dayNumber,
            totalDays: trip.days.count,
            currentLocation: day.startLocation,
            nextLocation: day.endLocation
        )
        
        let initialContentState = TripActivityAttributes.ContentState(
            currentActivityName: activity.name,
            currentActivityTime: formatTime(activity.scheduledTime),
            nextActivityName: getNextActivity(in: day)?.name,
            nextActivityTime: formatTime(getNextActivity(in: day)?.scheduledTime),
            nextActivityDistance: "2.3 miles",
            progressPercentage: calculateProgress(for: day),
            completedCount: countCompletedActivities(in: day),
            totalCount: day.activities.count,
            estimatedArrivalTime: activity.scheduledTime
        )
        
        do {
            currentActivity = try Activity<TripActivityAttributes>.request(
                attributes: attributes,
                contentState: initialContentState,
                pushType: .token
            )
        } catch {
            print("Failed to start live activity: \(error)")
        }
    }
    
    /// Update the live activity with new information
    func updateTripActivity(
        currentActivityName: String,
        currentTime: String,
        nextActivityName: String?,
        nextTime: String?,
        distance: String?,
        completedCount: Int,
        totalCount: Int
    ) async {
        guard let activity = currentActivity else { return }
        
        let updatedState = TripActivityAttributes.ContentState(
            currentActivityName: currentActivityName,
            currentActivityTime: currentTime,
            nextActivityName: nextActivityName,
            nextActivityTime: nextTime,
            nextActivityDistance: distance,
            progressPercentage: Double(completedCount) / Double(max(1, totalCount)),
            completedCount: completedCount,
            totalCount: totalCount,
            estimatedArrivalTime: Date().addingTimeInterval(60 * 30) // 30 min from now
        )
        
        await activity.update(using: updatedState)
    }
    
    /// End the live activity
    func endTripActivity() async {
        guard let activity = currentActivity else { return }
        await activity.end(using: TripActivityAttributes.ContentState(
            currentActivityName: "Trip Complete",
            currentActivityTime: "Finished",
            nextActivityName: nil,
            nextActivityTime: nil,
            nextActivityDistance: nil,
            progressPercentage: 1.0,
            completedCount: 0,
            totalCount: 0,
            estimatedArrivalTime: nil
        ), dismissalPolicy: .immediate)
    }
    
    // MARK: - Helper Methods
    
    private func formatTime(_ date: Date?) -> String {
        guard let date = date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func getNextActivity(in day: TripDay) -> Activity? {
        day.activities.sorted(by: { $0.order < $1.order }).first(where: { !$0.isCompleted })
    }
    
    private func calculateProgress(for day: TripDay) -> Double {
        guard day.activities.count > 0 else { return 0 }
        let completed = day.activities.filter { $0.isCompleted }.count
        return Double(completed) / Double(day.activities.count)
    }
    
    private func countCompletedActivities(in day: TripDay) -> Int {
        day.activities.filter { $0.isCompleted }.count
    }
}

// MARK: - Lock Screen Widget for Live Activities

struct TripLiveActivityWidget: View {
    let state: TripActivityAttributes.ContentState
    let attributes: TripActivityAttributes
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with trip name and progress
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(attributes.tripName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("Day \(attributes.tripDay) of \(attributes.totalDays)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                ProgressView(value: state.progressPercentage)
                    .frame(width: 50)
            }
            
            // Current Activity
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.currentActivityName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        
                        Text(state.currentActivityTime)
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Next Activity (if available)
            if let nextActivity = state.nextActivityName {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(nextActivity)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        if let distance = state.nextActivityDistance {
                            HStack(spacing: 4) {
                                Image(systemName: "location.fill")
                                    .font(.caption2)
                                
                                Text(distance)
                                    .font(.caption2)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            // Progress Bar
            HStack(spacing: 8) {
                ProgressView(value: state.progressPercentage)
                
                Text("\(state.completedCount)/\(state.totalCount)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Minimal Lock Screen Display

struct TripActivityLockScreenView: View {
    let state: TripActivityAttributes.ContentState
    let attributes: TripActivityAttributes
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(state.currentActivityName)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    
                    Text(state.currentActivityTime)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if let nextActivity = state.nextActivityName {
                Text("→ \(nextActivity)")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Timer Activity View (for current activity countdown)

struct ActivityCountdownDisplay: View {
    @State private var timeRemaining: TimeInterval = 0
    @State private var updateTimer: Timer?
    
    let activityName: String
    let scheduledTime: Date
    let location: String?
    
    var formattedTimeRemaining: String {
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        let seconds = Int(timeRemaining) % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(activityName)
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(formattedTimeRemaining)
                        .font(.title2)
                        .fontWeight(.bold)
                        .monospacedDigit()
                }
                
                Spacer()
                
                if let location = location {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(location)
                            .font(.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        updateTimeRemaining()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func stopTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    private func updateTimeRemaining() {
        timeRemaining = max(0, scheduledTime.timeIntervalSince(Date()))
    }
}

// MARK: - Authorization Check

struct ActivityAuthorizationInfo {
    var areActivitiesEnabled: Bool {
        if #available(iOS 16.1, *) {
            return ActivityKit.ActivityAuthorizationInfo().areActivitiesEnabled
        } else {
            return false
        }
    }
}
