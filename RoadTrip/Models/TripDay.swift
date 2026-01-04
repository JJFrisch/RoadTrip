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
    var id: UUID
    var dayNumber: Int
    var date: Date
    var startLocation: String
    var endLocation: String
    var distance: Double // in miles
    var drivingTime: Double // in hours
    var hotelName: String?

    @Relationship(deleteRule: .cascade)
    var hotel: Hotel?
    
    @Relationship(deleteRule: .cascade)
    var activities: [Activity]
    
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
        self.activities = activities
    }
}
