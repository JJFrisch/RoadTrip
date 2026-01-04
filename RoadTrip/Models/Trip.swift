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
        
        // Ensure we have a valid range (handle case where endDate is before startDate)
        guard numberOfDays >= 0 else {
            // If dates are reversed, just create a single day
            let day = TripDay(
                dayNumber: 1,
                date: startDate,
                startLocation: "",
                endLocation: "",
                distance: 0,
                drivingTime: 0,
                activities: []
            )
            self.days.append(day)
            return
        }
        
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
        max(0, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
    }
    
    var totalDistance: Double {
        days.reduce(0) { $0 + $1.distance }
    }
    
    var totalDrivingTime: Double {
        days.reduce(0) { $0 + $1.drivingTime }
    }
    
    // Computed property to get valid days (filters out any corrupted data)
    var validDays: [TripDay] {
        days.filter { $0.dayNumber > 0 }
    }
    
    // MARK: - Budget Tracking
    
    var totalBudget: Double {
        days.reduce(0) { total, day in
            total + day.activities.reduce(0) { $0 + ($1.estimatedCost ?? 0) }
        }
    }
    
    func budgetByCategory(_ category: String) -> Double {
        days.reduce(0) { total, day in
            total + day.activities
                .filter { $0.costCategory == category }
                .reduce(0) { $0 + ($1.estimatedCost ?? 0) }
        }
    }
    
    var budgetBreakdown: [(category: String, amount: Double)] {
        let categories = ["Gas", "Food", "Lodging", "Attractions", "Other"]
        return categories.map { category in
            (category: category, amount: budgetByCategory(category))
        }.filter { $0.amount > 0 }
    }
}
