//
//  TripDTO.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

struct SyncMetadataDTO: Codable, Equatable {
    var version: Int
    var updatedAt: Date

    static let initial = SyncMetadataDTO(version: 1, updatedAt: Date())
}

struct ActivityDTO: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var location: String
    var scheduledTime: Date?
    var duration: Double?
    var category: String
    var notes: String?
    var isCompleted: Bool
    var order: Int

    var checkInTime: Date?
    var checkOutTime: Date?
    var hotelConfirmation: String?
    var hotelPhoneNumber: String?
    var hotelWebsite: String?

    var estimatedCost: Double?
    var costCategory: String?

    var latitude: Double?
    var longitude: Double?
    var placeId: String?
    var sourceType: String?
    var importedAt: Date?
    var rating: Double?
    var photoURL: String?
    var website: String?
    var phoneNumber: String?
    var openingHours: [String]

    var photos: [Data]
    var photoThumbnails: [Data]

    var isMultiDay: Bool
    var endDate: Date?
    var spansDays: Int

    // These are API-forward fields to support in-trip execution telemetry.
    var actualStartTime: Date?
    var actualEndTime: Date?

    var sync: SyncMetadataDTO
}

struct TripDayDTO: Codable, Equatable, Identifiable {
    var id: UUID
    var dayNumber: Int
    var date: Date
    var startLocation: String
    var endLocation: String
    var distance: Double
    var drivingTime: Double
    var hotelName: String?
    var activities: [ActivityDTO]
    var sync: SyncMetadataDTO
}

struct TripDTO: Codable, Equatable, Identifiable {
    var id: UUID
    var name: String
    var tripDescription: String?
    var startDate: Date
    var endDate: Date
    var coverImage: String?
    var createdAt: Date

    var totalBudget: Double?
    var spentAmount: Double
    var budgetCategories: [String: Double]

    var ownerId: String?
    var ownerEmail: String?

    var days: [TripDayDTO]
    var sync: SyncMetadataDTO
}
