// Models/Trip.swift
// Created by Jake Frischmann on 1/1/26.

import Foundation
import SwiftData

@Model
class Trip {
    var id: UUID
    var name: String
    var tripDescription: String?
    var startDate: Date
    var endDate: Date
    var coverImage: String? // SF Symbol or image name
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade)
    var days: [TripDay]
    
    init(name: String, startDate: Date, endDate: Date) {
        self.id = UUID()
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = Date()
        self.days = []
        
        // Generate TripDays for each day between startDate and endDate (inclusive)
        let calendar = Calendar.current
        let numberOfDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        for i in 0...numberOfDays {
            if let date = calendar.date(byAdding: .day, value: i, to: startDate) {
                let day = TripDay(
                    dayNumber: i + 1,
                    date: date,
                    startLocation: "",
                    endLocation: "",
                    distance: 0,
                    drivingTime: 0,
                    activities: []
                )
                self.days.append(day)
            }
        }
    }

    
    var numberOfNights: Int {
        Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
    }
    
    var totalDistance: Double {
        days.reduce(0) { $0 + $1.distance }
    }
}
