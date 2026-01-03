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
    
    // Enhanced location data
    var latitude: Double?
    var longitude: Double?
    var placeId: String? // Google Places ID or other external ID
    var sourceType: String? // "google", "tripadvisor", "manual", "mapbox"
    var importedAt: Date?
    var rating: Double? // 0.0 to 5.0
    var photoURL: String?
    var website: String?
    var phoneNumber: String?
    
    init(name: String, location: String, category: String) {
        self.id = UUID()
        self.name = name
        self.location = location
        self.category = category
        self.isCompleted = true // Start checked
        self.order = 0
    }
    
    // Convenience for coordinate
    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }
}


