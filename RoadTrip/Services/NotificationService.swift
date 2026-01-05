// Services/NotificationService.swift
import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Permission
    
    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Activity Reminders
    
    func scheduleActivityReminder(activity: Activity, minutesBefore: Int = 30, dayDate: Date) {
        guard let scheduledTime = activity.scheduledTime else { return }
        
        // Combine day date with activity time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        guard let activityDateTime = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                                    minute: timeComponents.minute ?? 0,
                                                    second: 0,
                                                    of: dayDate),
              let reminderTime = calendar.date(byAdding: .minute, value: -minutesBefore, to: activityDateTime) else {
            return
        }
        
        // Don't schedule if reminder time is in the past
        guard reminderTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Activity"
        content.body = "\(activity.name) at \(activity.location) starts in \(minutesBefore) minutes"
        content.sound = .default
        content.categoryIdentifier = "ACTIVITY_REMINDER"
        
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "activity-\(activity.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule activity reminder: \(error)")
            }
        }
    }
    
    // MARK: - Morning Summary
    
    func scheduleMorningSummary(for trip: Trip, day: TripDay) {
        let calendar = Calendar.current
        
        // Schedule for 7 AM on the day
        guard let morningTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: day.date),
              morningTime > Date() else {
            return
        }
        
        let completedActivities = (day.activities ?? []).filter { $0.isCompleted }
        let activityCount = completedActivities.count
        
        let content = UNMutableNotificationContent()
        content.title = "Good Morning! Day \(day.dayNumber) of \(trip.name)"
        
        var bodyParts: [String] = []
        
        if !day.startLocation.isEmpty && !day.endLocation.isEmpty {
            bodyParts.append("📍 \(day.startLocation) → \(day.endLocation)")
        }
        
        if day.distance > 0 {
            let hours = Int(day.drivingTime)
            let minutes = Int((day.drivingTime - Double(hours)) * 60)
            let timeStr = hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
            bodyParts.append("🚗 \(Int(day.distance)) miles (\(timeStr))")
        }
        
        if activityCount > 0 {
            bodyParts.append("📋 \(activityCount) activit\(activityCount == 1 ? "y" : "ies") planned")
        }
        
        content.body = bodyParts.joined(separator: "\n")
        content.sound = .default
        content.categoryIdentifier = "MORNING_SUMMARY"
        
        let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: morningTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "morning-\(day.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule morning summary: \(error)")
            }
        }
    }
    
    // MARK: - Schedule All Notifications for Trip
    
    func scheduleAllNotifications(for trip: Trip) async {
        // First request permission
        let granted = await requestPermission()
        guard granted else { return }
        
        // Cancel existing notifications for this trip
        cancelAllNotifications(for: trip)
        
        // Schedule morning summaries and activity reminders
        for day in trip.safeDays {
            scheduleMorningSummary(for: trip, day: day)
            
            for activity in (day.activities ?? []) where activity.isCompleted && activity.scheduledTime != nil {
                scheduleActivityReminder(activity: activity, minutesBefore: 30, dayDate: day.date)
            }
        }
    }
    
    // MARK: - Cancel Notifications
    
    func cancelAllNotifications(for trip: Trip) {
        var identifiers: [String] = []
        
        for day in trip.safeDays {
            identifiers.append("morning-\(day.id.uuidString)")
            
            for activity in (day.activities ?? []) {
                identifiers.append("activity-\(activity.id.uuidString)")
            }
        }
        
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
