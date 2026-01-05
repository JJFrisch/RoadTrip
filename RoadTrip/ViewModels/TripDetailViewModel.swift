//
//  TripDetailViewModel.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/1/26.
//

import Foundation
import SwiftUI
import MapKit
import SwiftData

@MainActor
final class TripDetailViewModel: ObservableObject {
    @Published var isImporting: Bool = false
    @Published var importError: AppError?

    private let importer = ActivityImporter.shared

    func importActivities(from url: URL, baseActivityIndex: Int = 0, modelContext: ModelContext) async throws -> [Activity] {
        isImporting = true
        defer { isImporting = false }
        
        // Check network first
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.networkUnavailable
        }

        var imported: [ActivityImporter.ImportedPlace] = []
        
        do {
            if url.host?.contains("tripadvisor") == true {
                imported = try await importer.importFromTripAdvisor(url: url)
            } else if url.host?.contains("google") == true || url.host?.contains("maps") == true {
                imported = try await importer.importFromGoogleMaps(url: url)
            } else {
                // Try both heuristics
                do { 
                    imported = try await importer.importFromTripAdvisor(url: url) 
                } catch { 
                    imported = try await importer.importFromGoogleMaps(url: url) 
                }
            }
        } catch {
            if let appError = error as? AppError {
                throw appError
            }
            throw AppError.unknown(error)
        }

        var created: [Activity] = []
        for (index, place) in imported.enumerated() {
            let activity = Activity(name: place.name, location: place.address ?? "", category: place.category ?? "Attraction")
            activity.duration = place.typicalDurationHours
            activity.order = baseActivityIndex + index
            activity.isCompleted = true
            
            // Enhanced fields
            if let coord = place.coordinate {
                activity.latitude = coord.latitude
                activity.longitude = coord.longitude
            }
            activity.placeId = place.placeId
            activity.sourceType = url.host?.contains("google") == true ? "google" : "tripadvisor"
            activity.importedAt = Date()
            activity.rating = place.rating
            activity.photoURL = place.photoURL
            activity.website = place.website
            activity.phoneNumber = place.phoneNumber
            if (activity.notes == nil || activity.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true),
               let blurb = place.blurb,
               !blurb.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                activity.notes = blurb
            }

            // Don't insert into modelContext yet - let caller decide when to persist
            created.append(activity)
        }

        return created
    }
    
    func importActivitiesFromGooglePlaces(near location: CLLocationCoordinate2D, baseActivityIndex: Int = 0, modelContext: ModelContext, radius: Double = 2000) async throws -> [Activity] {
        isImporting = true
        defer { isImporting = false }
        
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.networkUnavailable
        }
        
        let imported = try await importer.importFromGooglePlaces(near: location, radius: radius)
        
        var created: [Activity] = []
        for (index, place) in imported.enumerated() {
            let activity = Activity(name: place.name, location: place.address ?? "", category: place.category ?? "Attraction")
            activity.duration = place.typicalDurationHours
            activity.order = baseActivityIndex + index
            activity.isCompleted = true
            
            // Enhanced fields
            if let coord = place.coordinate {
                activity.latitude = coord.latitude
                activity.longitude = coord.longitude
            }
            activity.placeId = place.placeId
            activity.sourceType = "google"
            activity.importedAt = Date()
            activity.rating = place.rating
            activity.photoURL = place.photoURL
            activity.website = place.website
            activity.phoneNumber = place.phoneNumber
            if (activity.notes == nil || activity.notes?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == true),
               let blurb = place.blurb,
               !blurb.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                activity.notes = blurb
            }
            
            // Don't insert into modelContext yet - let caller decide when to persist
            created.append(activity)
        }
        
        return created
    }

    func suggestStart(previousEnd: Date?, driveTime: TimeInterval?, activityCategory: String, typicalDurationHours: Double?) -> Date {
        SmartTimeSuggester.suggestStartTime(previousEnd: previousEnd, driveTime: driveTime, activityCategory: activityCategory, typicalDurationHours: typicalDurationHours)
    }

    func copyDay(_ day: TripDay, to newDate: Date, into trip: Trip) {
        let newDayNumber = trip.days.count + 1
        let copy = DayCopier.copy(day: day, to: newDate, newDayNumber: newDayNumber)
        if trip.days == nil { trip.days = [] }
        trip.days?.append(copy)
    }
}
