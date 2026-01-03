import Foundation
import SwiftData

final class DayCopier {
    /// Returns a copy of the given TripDay with a new date and day number.
    static func copy(day: TripDay, to newDate: Date, newDayNumber: Int) -> TripDay {
        // Copy activities deeply
        let copiedActivities = day.activities.map { activity -> Activity in
            let a = Activity(name: activity.name, location: activity.location, category: activity.category)
            a.duration = activity.duration
            a.notes = activity.notes
            a.scheduledTime = activity.scheduledTime
            a.isCompleted = activity.isCompleted
            a.order = activity.order
            return a
        }

        let newDay = TripDay(dayNumber: newDayNumber, date: newDate, startLocation: day.startLocation, endLocation: day.endLocation, distance: day.distance, drivingTime: day.drivingTime, activities: copiedActivities)
        newDay.hotelName = day.hotelName
        return newDay
    }
}
