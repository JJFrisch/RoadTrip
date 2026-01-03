// Models/ActivityTemplate.swift
import Foundation
import SwiftData

@Model
class ActivityTemplate {
    var id: UUID
    var name: String
    var category: String
    var suggestedDuration: Double? // in hours
    var notes: String?
    var useCount: Int // Track popularity
    var lastUsed: Date
    
    init(name: String, category: String, suggestedDuration: Double? = nil, notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.suggestedDuration = suggestedDuration
        self.notes = notes
        self.useCount = 0
        self.lastUsed = Date()
    }
    
    // Common templates
    static func commonTemplates() -> [ActivityTemplate] {
        return [
            ActivityTemplate(name: "Breakfast", category: "Food", suggestedDuration: 1.0),
            ActivityTemplate(name: "Lunch", category: "Food", suggestedDuration: 1.0),
            ActivityTemplate(name: "Dinner", category: "Food", suggestedDuration: 1.5),
            ActivityTemplate(name: "Coffee Break", category: "Food", suggestedDuration: 0.5),
            ActivityTemplate(name: "Hotel Check-in", category: "Hotel", suggestedDuration: 0.5),
            ActivityTemplate(name: "Hotel Check-out", category: "Hotel", suggestedDuration: 0.5),
            ActivityTemplate(name: "Museum Visit", category: "Attraction", suggestedDuration: 2.0),
            ActivityTemplate(name: "Park Walk", category: "Attraction", suggestedDuration: 1.5),
            ActivityTemplate(name: "Shopping", category: "Other", suggestedDuration: 2.0),
            ActivityTemplate(name: "Beach Time", category: "Attraction", suggestedDuration: 3.0)
        ]
    }
}
