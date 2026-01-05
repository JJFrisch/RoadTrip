// Models/Trip.swift
// Created by Jake Frischmann on 1/1/26.

import Foundation
import SwiftData

@Model
class Trip {
    var id: UUID = UUID()
    var name: String = ""
    var tripDescription: String?
    var startDate: Date = Date()
    var endDate: Date = Date()
    var coverImage: String? // SF Symbol or image name
    var createdAt: Date = Date()
    
    // Budget Tracking
    var totalBudget: Double? // User-set budget limit
    var spentAmount: Double = 0 // Total amount spent so far
    var budgetCategories: [String: Double] = [:] // Category-specific budgets
    
    // Sharing & Collaboration
    var ownerId: String? // User ID of the trip owner
    var ownerEmail: String? // Email of trip owner for display
    /// Persisted backing store for `sharedWith`.
    /// Stored as JSON to avoid CoreData attempting to materialize Swift `Array` as a transformable Objective-C class.
    var sharedWithData: Data = Data()

    /// Array of user IDs who have access
    var sharedWith: [String] {
        get {
            (try? JSONDecoder().decode([String].self, from: sharedWithData)) ?? []
        }
        set {
            sharedWithData = (try? JSONEncoder().encode(newValue)) ?? Data()
        }
    }
    var shareCode: String? // Unique code for sharing via link
    var isShared: Bool = false // Whether trip is shared with others
    var lastSyncedAt: Date? // Last time synced to cloud
    var cloudId: String? // ID in cloud database for sync

    var days: [TripDay]?
    
    init(name: String, startDate: Date, endDate: Date) {
        self.name = name
        self.startDate = startDate
        self.endDate = endDate
        self.sharedWithData = (try? JSONEncoder().encode([String]())) ?? Data()
        self.isShared = false
        self.days = nil
        // Generate TripDays for each day between startDate and endDate (inclusive)
        generateDays(from: startDate, to: endDate)
    }
    
    /// Regenerate days when dates change
    func updateDates(newStartDate: Date, newEndDate: Date) {
        let calendar = Calendar.current
        let oldDays = (days ?? []).sorted(by: { $0.dayNumber < $1.dayNumber })
        
        // Calculate new number of days
        let newNumberOfDays = max(0, calendar.dateComponents([.day], from: newStartDate, to: newEndDate).day ?? 0) + 1
        let oldNumberOfDays = oldDays.count
        
        // Update existing days with new dates
        for (index, day) in oldDays.enumerated() {
            if index < newNumberOfDays {
                if let newDate = calendar.date(byAdding: .day, value: index, to: newStartDate) {
                    day.date = newDate
                    day.dayNumber = index + 1
                }
            }
        }
        
        // Add new days if needed
        if newNumberOfDays > oldNumberOfDays {
            for i in oldNumberOfDays..<newNumberOfDays {
                if let date = calendar.date(byAdding: .day, value: i, to: newStartDate) {
                    let day = TripDay(
                        dayNumber: i + 1,
                        date: date,
                        startLocation: "",
                        endLocation: "",
                        distance: 0,
                        drivingTime: 0,
                        activities: []
                    )
                    day.trip = self
                    if days == nil { days = [] }
                    days?.append(day)
                }
            }
        }
        
        // Remove extra days if needed (keep activities by moving to last day)
        if newNumberOfDays < oldNumberOfDays && newNumberOfDays > 0 {
            let daysToRemove = oldDays.suffix(oldNumberOfDays - newNumberOfDays)
            let lastKeptDay = oldDays[newNumberOfDays - 1]
            for dayToRemove in daysToRemove {
                // Move activities to the last kept day
                for activity in (dayToRemove.activities ?? []) {
                    activity.order = (lastKeptDay.activities ?? []).count
                    if lastKeptDay.activities == nil { lastKeptDay.activities = [] }
                    lastKeptDay.activities?.append(activity)
                }
                dayToRemove.activities?.removeAll()
                days = (days ?? []).filter { $0.id != dayToRemove.id }
            }
        }
        
        startDate = newStartDate
        endDate = newEndDate
    }
    
    private func generateDays(from startDate: Date, to endDate: Date) {
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
            day.trip = self
            if self.days == nil { self.days = [] }
            self.days?.append(day)
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
                day.trip = self
                if self.days == nil { self.days = [] }
                self.days?.append(day)
            }
        }
    }

    
    var numberOfNights: Int {
        max(0, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
    }
    
    var totalDistance: Double {
        (days ?? []).reduce(0) { $0 + $1.distance }
    }
    
    var totalDrivingTime: Double {
        (days ?? []).reduce(0) { $0 + $1.drivingTime }
    }
    
    // Computed property to get valid days (filters out any corrupted data)
    var validDays: [TripDay] {
        (days ?? []).filter { $0.dayNumber > 0 }
    }
    
    // MARK: - Budget Tracking (estimates)

    var estimatedTotalCost: Double {
        (days ?? []).reduce(0) { total, day in
            let activityTotal = (day.activities ?? []).reduce(0) { $0 + ($1.estimatedCost ?? 0) }
            let lodging = day.hotel?.pricePerNight ?? 0
            return total + activityTotal + lodging
        }
    }
    
    func budgetByCategory(_ category: String) -> Double {
        (days ?? []).reduce(0) { total, day in
            var subtotal = (day.activities ?? [])
                .filter { $0.costCategory == category }
                .reduce(0) { $0 + ($1.estimatedCost ?? 0) }

            if category == "Lodging" {
                subtotal += day.hotel?.pricePerNight ?? 0
            }

            return total + subtotal
        }
    }
    
    var budgetBreakdown: [(category: String, amount: Double)] {
        let categories = ["Gas", "Food", "Lodging", "Attractions", "Other"]
        return categories.map { category in
            (category: category, amount: budgetByCategory(category))
        }.filter { $0.amount > 0 }
    }
}
