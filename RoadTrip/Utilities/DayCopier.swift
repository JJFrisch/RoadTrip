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

        if let sourceHotel = day.hotel {
            let copiedHotel = Hotel(name: sourceHotel.name, address: sourceHotel.address, city: sourceHotel.city, state: sourceHotel.state, zipCode: sourceHotel.zipCode, country: sourceHotel.country)
            copiedHotel.latitude = sourceHotel.latitude
            copiedHotel.longitude = sourceHotel.longitude
            copiedHotel.rating = sourceHotel.rating
            copiedHotel.reviewCount = sourceHotel.reviewCount
            copiedHotel.starRating = sourceHotel.starRating
            copiedHotel.imageURLs = sourceHotel.imageURLs
            copiedHotel.thumbnailURL = sourceHotel.thumbnailURL
            copiedHotel.amenities = sourceHotel.amenities
            copiedHotel.hasWiFi = sourceHotel.hasWiFi
            copiedHotel.hasParking = sourceHotel.hasParking
            copiedHotel.hasBreakfast = sourceHotel.hasBreakfast
            copiedHotel.hasPool = sourceHotel.hasPool
            copiedHotel.hasFitness = sourceHotel.hasFitness
            copiedHotel.petFriendly = sourceHotel.petFriendly
            copiedHotel.pricePerNight = sourceHotel.pricePerNight
            copiedHotel.currency = sourceHotel.currency
            copiedHotel.taxesAndFees = sourceHotel.taxesAndFees
            copiedHotel.bookingComURL = sourceHotel.bookingComURL
            copiedHotel.hotelsComURL = sourceHotel.hotelsComURL
            copiedHotel.expediaURL = sourceHotel.expediaURL
            copiedHotel.airbnbURL = sourceHotel.airbnbURL
            copiedHotel.directBookingURL = sourceHotel.directBookingURL
            copiedHotel.sourceType = sourceHotel.sourceType
            copiedHotel.externalId = sourceHotel.externalId
            copiedHotel.lastUpdated = sourceHotel.lastUpdated
            copiedHotel.isFavorite = sourceHotel.isFavorite
            copiedHotel.notes = sourceHotel.notes

            newDay.hotel = copiedHotel
            newDay.hotelName = copiedHotel.name
        } else {
            newDay.hotelName = day.hotelName
        }
        return newDay
    }
}
