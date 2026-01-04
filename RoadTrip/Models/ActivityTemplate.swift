// Models/ActivityTemplate.swift
import Foundation
import SwiftData

@Model
class ActivityTemplate {
    var id: UUID
    var name: String
    var location: String
    var category: String
    var defaultDuration: Double // in hours
    var notes: String?
    var estimatedCost: Double?
    var costCategory: String?
    var usageCount: Int = 0
    var lastUsed: Date?
    var createdAt: Date
    
    // Common preset templates
    static let presetNames = [
        "Breakfast", "Lunch", "Dinner", "Coffee Break",
        "Hotel Check-in", "Hotel Check-out",
        "Gas Stop", "Rest Stop", "Scenic Overlook"
    ]
    
    init(name: String, location: String = "", category: String, defaultDuration: Double = 1.0) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.category = category
        self.defaultDuration = defaultDuration
        self.createdAt = Date()
    }
    
    // Create activity from template
    func createActivity(for day: TripDay, at time: Date? = nil) -> Activity {
        let activity = Activity(name: name, location: location.isEmpty ? day.startLocation : location, category: category)
        activity.duration = defaultDuration
        activity.scheduledTime = time
        activity.notes = notes
        activity.estimatedCost = estimatedCost
        activity.costCategory = costCategory
        activity.isCompleted = true
        activity.order = day.activities.count
        
        // Update template usage stats
        usageCount += 1
        lastUsed = Date()
        
        return activity
    }
    
    // Common templates
    static func commonTemplates() -> [ActivityTemplate] {
        return [
            ActivityTemplate(name: "Breakfast", category: "Food", defaultDuration: 1.0),
            ActivityTemplate(name: "Lunch", category: "Food", defaultDuration: 1.0),
            ActivityTemplate(name: "Dinner", category: "Food", defaultDuration: 1.5),
            ActivityTemplate(name: "Coffee Break", category: "Food", defaultDuration: 0.5),
            ActivityTemplate(name: "Hotel Check-in", category: "Hotel", defaultDuration: 0.5),
            ActivityTemplate(name: "Hotel Check-out", category: "Hotel", defaultDuration: 0.5),
            ActivityTemplate(name: "Museum Visit", category: "Attraction", defaultDuration: 2.0),
            ActivityTemplate(name: "Park Walk", category: "Attraction", defaultDuration: 1.5),
            ActivityTemplate(name: "Shopping", category: "Other", defaultDuration: 2.0),
            ActivityTemplate(name: "Beach Time", category: "Attraction", defaultDuration: 3.0)
        ]
    }
}
