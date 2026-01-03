// Utilities/TimeHelper.swift
import Foundation

struct TimeHelper {
    
    /// Suggests next activity time based on previous activity and travel time
    static func suggestNextActivityTime(
        previousActivityTime: Date?,
        previousActivityDuration: Double?,
        travelTimeHours: Double,
        activityCategory: String
    ) -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // If there's a previous activity, calculate based on that
        if let prevTime = previousActivityTime {
            let prevDuration = previousActivityDuration ?? 1.0
            let travelTimeSeconds = travelTimeHours * 3600
            let prevDurationSeconds = prevDuration * 3600
            
            // End time of previous activity + travel time + buffer
            let bufferTime: TimeInterval = 900 // 15 minutes buffer
            let suggestedTime = prevTime.addingTimeInterval(prevDurationSeconds + travelTimeSeconds + bufferTime)
            
            return suggestedTime
        }
        
        // Otherwise, suggest based on activity category and time of day
        return suggestTimeByCategory(category: activityCategory, baseDate: now)
    }
    
    /// Suggests time based on activity category (meals, etc.)
    static func suggestTimeByCategory(category: String, baseDate: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: baseDate)
        
        switch category {
        case "Food":
            // Determine meal time based on current time or return next meal
            let hour = calendar.component(.hour, from: baseDate)
            
            if hour < 9 {
                // Suggest breakfast at 8am
                var breakfast = components
                breakfast.hour = 8
                breakfast.minute = 0
                return calendar.date(from: breakfast) ?? baseDate
            } else if hour < 13 {
                // Suggest lunch at 12:30pm
                var lunch = components
                lunch.hour = 12
                lunch.minute = 30
                return calendar.date(from: lunch) ?? baseDate
            } else {
                // Suggest dinner at 7pm
                var dinner = components
                dinner.hour = 19
                dinner.minute = 0
                return calendar.date(from: dinner) ?? baseDate
            }
            
        case "Hotel":
            let hour = calendar.component(.hour, from: baseDate)
            if hour < 12 {
                // Check-out at 11am
                var checkout = components
                checkout.hour = 11
                checkout.minute = 0
                return calendar.date(from: checkout) ?? baseDate
            } else {
                // Check-in at 3pm
                var checkin = components
                checkin.hour = 15
                checkin.minute = 0
                return calendar.date(from: checkin) ?? baseDate
            }
            
        default:
            // Default to 10am for attractions and other activities
            var morning = components
            morning.hour = 10
            morning.minute = 0
            return calendar.date(from: morning) ?? baseDate
        }
    }
    
    /// Get suggested duration based on activity category and name
    static func suggestDuration(category: String, activityName: String) -> Double {
        let nameLower = activityName.lowercased()
        
        // Check for specific keywords
        if nameLower.contains("breakfast") || nameLower.contains("coffee") {
            return 1.0
        } else if nameLower.contains("lunch") {
            return 1.0
        } else if nameLower.contains("dinner") {
            return 1.5
        } else if nameLower.contains("museum") || nameLower.contains("gallery") {
            return 2.0
        } else if nameLower.contains("beach") || nameLower.contains("park") {
            return 3.0
        } else if nameLower.contains("check-in") || nameLower.contains("check-out") {
            return 0.5
        }
        
        // Otherwise use category defaults
        switch category {
        case "Food":
            return 1.0
        case "Attraction":
            return 2.0
        case "Hotel":
            return 0.5
        default:
            return 1.5
        }
    }
    
    /// Calculate expected time based on previous activities in the day
    static func calculateSmartTimeForNewActivity(
        day: TripDay,
        newActivityCategory: String,
        newActivityName: String
    ) async -> (suggestedTime: Date, suggestedDuration: Double) {
        let sortedActivities = day.activities.sorted { a, b in
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                return a.scheduledTime != nil
            }
            return timeA < timeB
        }
        
        let suggestedDuration = suggestDuration(category: newActivityCategory, activityName: newActivityName)
        
        // If there are existing activities, calculate based on the last one
        if let lastActivity = sortedActivities.last,
           let lastTime = lastActivity.scheduledTime {
            
            // Try to calculate travel time from last activity to new activity's typical location
            var travelTime: Double = 0.25 // Default 15 min buffer
            
            // Use the suggested time
            let suggestedTime = suggestNextActivityTime(
                previousActivityTime: lastTime,
                previousActivityDuration: lastActivity.duration,
                travelTimeHours: travelTime,
                activityCategory: newActivityCategory
            )
            
            return (suggestedTime, suggestedDuration)
        }
        
        // No existing activities, suggest based on category
        let suggestedTime = suggestTimeByCategory(category: newActivityCategory, baseDate: day.date)
        return (suggestedTime, suggestedDuration)
    }
}
