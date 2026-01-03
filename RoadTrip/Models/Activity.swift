//
//  Activity.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/1/26.
//

import Foundation
import SwiftData


@Model
class Activity {
    var id: UUID
    var name: String
    var location: String
    var scheduledTime: Date?
    var duration: Double? // in hours
    var category: String // "Food", "Attraction", "Hotel", "Other"
    var notes: String?
    var isCompleted: Bool
    var order: Int // For custom ordering within a day
    
    init(name: String, location: String, category: String) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.category = category
        self.isCompleted = true // Start checked
        self.order = 0
    }
}

