    var safeActivities: [Activity] { activities ?? [] }
//
//  TripDay.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/1/26.
//

import Foundation
import SwiftData

@Model
class TripDay {
    var id: UUID = UUID()
    var dayNumber: Int = 0
    var date: Date = Date()
    var startLocation: String = ""
    var endLocation: String = ""
    var distance: Double = 0 // in miles
    var drivingTime: Double = 0 // in hours
    var hotelName: String?

    var hotel: Hotel?
    var activities: [Activity]?
    var trip: Trip?
    
    init(dayNumber: Int, date: Date, startLocation: String, endLocation: String, distance: Double = 0, drivingTime: Double = 0, activities: [Activity] = []) {
        self.id = UUID()
        self.dayNumber = dayNumber
        self.date = date
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.distance = distance
        self.drivingTime = drivingTime
        self.hotelName = nil
        self.hotel = nil
        self.activities = activities.isEmpty ? nil : activities
    }
}
