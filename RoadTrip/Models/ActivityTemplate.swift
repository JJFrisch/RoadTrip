// Models/ActivityTemplate.swift
import Foundation
import SwiftData

@Model
public final class TemplateActivity {
    @Attribute(.unique)
    public var id: UUID
    public var name: String
    public var location: String
    public var category: String
    public var defaultDuration: Double // in hours
    public var notes: String?
    public var estimatedCost: Double?
    public var costCategory: String?
    public var usageCount: Int
    public var lastUsed: Date?
    public var createdAt: Date
    
    // Common preset templates
    public static let presetNames = [
        "Breakfast", "Lunch", "Dinner", "Coffee Break",
        "Hotel Check-in", "Hotel Check-out",
        "Gas Stop", "Rest Stop", "Scenic Overlook"
    ]
    
    public init(name: String, location: String = "", category: String, defaultDuration: Double = 1.0) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.category = category
        self.defaultDuration = defaultDuration
        self.usageCount = 0
        self.createdAt = Date()
    }
    
    // Create activity from template
    public func createActivity(for day: TripDay, at time: Date? = nil) -> Activity {
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
    public static func commonTemplates() -> [TemplateActivity] {
        return [
            TemplateActivity(name: "Breakfast", category: "Food", defaultDuration: 1.0),
            TemplateActivity(name: "Lunch", category: "Food", defaultDuration: 1.0),
            TemplateActivity(name: "Dinner", category: "Food", defaultDuration: 1.5),
            TemplateActivity(name: "Coffee Break", category: "Food", defaultDuration: 0.5),
            TemplateActivity(name: "Hotel Check-in", category: "Hotel", defaultDuration: 0.5),
            TemplateActivity(name: "Hotel Check-out", category: "Hotel", defaultDuration: 0.5),
            TemplateActivity(name: "Museum Visit", category: "Attraction", defaultDuration: 2.0),
            TemplateActivity(name: "Park Walk", category: "Attraction", defaultDuration: 1.5),
            TemplateActivity(name: "Shopping", category: "Other", defaultDuration: 2.0),
            TemplateActivity(name: "Beach Time", category: "Attraction", defaultDuration: 3.0)
        ]
    }
}

// Type alias for backward compatibility
public typealias ActivityTemplate = TemplateActivity
