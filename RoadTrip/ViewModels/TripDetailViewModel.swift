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

	private let importer = ActivityImporter.shared

	func importActivities(from url: URL, into day: TripDay, modelContext: ModelContext) async throws -> [Activity] {
		isImporting = true
		defer { isImporting = false }

		var imported: [ActivityImporter.ImportedPlace] = []
		if url.host?.contains("tripadvisor") == true {
			imported = try await importer.importFromTripAdvisor(url: url)
		} else if url.host?.contains("google") == true || url.host?.contains("maps") == true {
			imported = try await importer.importFromGoogleMaps(url: url)
		} else {
			// Try both heuristics
			do { imported = try await importer.importFromTripAdvisor(url: url) } catch { imported = try await importer.importFromGoogleMaps(url: url) }
		}

		var created: [Activity] = []
		for (index, place) in imported.enumerated() {
			let activity = Activity(name: place.name, location: place.address ?? "", category: place.category ?? "Attraction")
			activity.duration = place.typicalDurationHours
			activity.order = day.activities.count + index
			if let coord = place.coordinate {
				// Optionally store coordinates in notes for now (extend model if needed)
				activity.notes = "Coordinates: \(coord.latitude),\(coord.longitude)"
			}

			modelContext.insert(activity)
			day.activities.append(activity)
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
		trip.days.append(copy)
	}
}

