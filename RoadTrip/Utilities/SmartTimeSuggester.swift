import Foundation

struct SmartTimeSuggester {
    static let breakfastRange = (start: 7, end: 9)
    static let lunchRange = (start: 12, end: 14)
    static let dinnerRange = (start: 18, end: 20)

    /// Suggests a reasonable start time for an activity.
    /// - Parameters:
    ///   - previousEnd: when the previous activity ended (optional)
    ///   - driveTime: travel time in seconds between previous and this activity (optional)
    ///   - activityCategory: category string like "Food" or "Attraction"
    ///   - typicalDurationHours: a typical duration in hours for the activity (optional)
    static func suggestStartTime(previousEnd: Date?, driveTime: TimeInterval? = nil, activityCategory: String, typicalDurationHours: Double? = nil, referenceDate: Date = Date()) -> Date {
        var base = previousEnd ?? referenceDate

        if let drive = driveTime {
            base = base.addingTimeInterval(drive)
        }

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: base)

        // If activity is a meal, snap to reasonable meal window
        let hour = components.hour ?? calendar.component(.hour, from: base)
        if activityCategory.lowercased().contains("breakfast") || activityCategory.lowercased().contains("coffee") {
            components.hour = clamp(hour, between: breakfastRange.start, and: breakfastRange.end)
            components.minute = 0
            return calendar.date(from: components) ?? base
        }

        if activityCategory.lowercased().contains("lunch") || activityCategory.lowercased().contains("food") && (hour >= 10 && hour <= 15) {
            components.hour = clamp(hour, between: lunchRange.start, and: lunchRange.end)
            components.minute = 0
            return calendar.date(from: components) ?? base
        }

        if activityCategory.lowercased().contains("dinner") || activityCategory.lowercased().contains("food") && (hour >= 16) {
            components.hour = clamp(hour, between: dinnerRange.start, and: dinnerRange.end)
            components.minute = 0
            return calendar.date(from: components) ?? base
        }

        // Default: schedule right after travel, but if typical duration suggests spacing, adjust for short activities
        if typicalDurationHours != nil {
            // If previous end + travel falls into a meal window and activity is not meal, bump a bit
            return calendar.date(from: components) ?? base
        }

        return base
    }

    private static func clamp(_ value: Int, between a: Int, and b: Int) -> Int {
        return max(a, min(b, value))
    }
}
