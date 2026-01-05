    var safeComments: [ActivityComment] { comments ?? [] }
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
    var id: UUID = UUID()
    var name: String = ""
    var location: String = ""
    var scheduledTime: Date?
    var duration: Double? // in hours
    var category: String = "" // "Food", "Attraction", "Hotel", "Other"
    var notes: String?
    var isCompleted: Bool = false
    var order: Int = 0 // For custom ordering within a day
    
    // Budget tracking
    var estimatedCost: Double? // in dollars
    var costCategory: String? // "Gas", "Food", "Lodging", "Attractions", "Other"
    
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
    
    // Photo attachments
    @Attribute(.externalStorage) var photos: [Data] = [] // Store photo data
    var photoThumbnails: [Data] = [] // Thumbnails for gallery
    
    // Collaboration features
    var comments: [ActivityComment]? // Activity comments
    var votes: [String: Int] = [:] // userId: voteValue (1 or -1)
    var voteScore: Int { votes.values.reduce(0, +) }
    
    // Multi-day activity support
    var isMultiDay: Bool = false
    var endDate: Date? // For multi-day activities like hotel stays
    var spansDays: Int = 1 // Number of days this activity spans

    var day: TripDay?
    
    init(name: String, location: String, category: String) {
        self.name = name
        self.location = location
        self.category = category
        self.comments = nil
        self.isCompleted = true // Start checked
        self.order = 0
    }
    
    // Convenience for coordinate
    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }
}

// MARK: - Activity History for Undo/Redo
class ActivityUndoManager: ObservableObject {
    static let shared = ActivityUndoManager()
    
    struct ActivitySnapshot {
        let activityId: UUID
        let name: String
        let location: String
        let category: String
        let scheduledTime: Date?
        let duration: Double?
        let notes: String?
        let isCompleted: Bool
        let estimatedCost: Double?
        let costCategory: String?
        let action: UndoAction
        let timestamp: Date
    }
    
    enum UndoAction {
        case create
        case update
        case delete
    }
    
    @Published private(set) var canUndo: Bool = false
    @Published private(set) var canRedo: Bool = false
    
    private var undoStack: [ActivitySnapshot] = []
    private var redoStack: [ActivitySnapshot] = []
    private let maxStackSize = 50
    
    private init() {}
    
    func recordChange(_ activity: Activity, action: UndoAction) {
        let snapshot = ActivitySnapshot(
            activityId: activity.id,
            name: activity.name,
            location: activity.location,
            category: activity.category,
            scheduledTime: activity.scheduledTime,
            duration: activity.duration,
            notes: activity.notes,
            isCompleted: activity.isCompleted,
            estimatedCost: activity.estimatedCost,
            costCategory: activity.costCategory,
            action: action,
            timestamp: Date()
        )
        
        undoStack.append(snapshot)
        if undoStack.count > maxStackSize {
            undoStack.removeFirst()
        }
        
        redoStack.removeAll()
        updateState()
    }
    
    func undo(in day: TripDay) -> ActivitySnapshot? {
        guard let snapshot = undoStack.popLast() else { return nil }
        redoStack.append(snapshot)
        updateState()
        return snapshot
    }
    
    func redo(in day: TripDay) -> ActivitySnapshot? {
        guard let snapshot = redoStack.popLast() else { return nil }
        undoStack.append(snapshot)
        updateState()
        return snapshot
    }
    
    func clearHistory() {
        undoStack.removeAll()
        redoStack.removeAll()
        updateState()
    }
    
    private func updateState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
}


