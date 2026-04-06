//
//  TripsViewModel.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/1/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
final class TripsViewModel: ObservableObject {
	@Published private(set) var trips: [Trip] = []
	@Published private(set) var isLoading: Bool = false
	@Published var error: AppError?

	private var repository: TripRepository?

	func configure(with modelContext: ModelContext) {
		repository = SwiftDataTripRepository(modelContext: modelContext)
	}

	func loadTrips() {
		guard let repository else { return }
		isLoading = true

		do {
			trips = try repository.fetchTrips()
		} catch {
			self.error = .apiError("Failed to load trips: \(error.localizedDescription)")
		}

		isLoading = false
	}

	@discardableResult
	func createTrip(
		name: String,
		startDate: Date,
		endDate: Date,
		tripDescription: String? = nil,
		totalBudget: Double? = nil
	) -> Trip? {
		guard let repository else { return nil }

		do {
			let trip = try repository.createTrip(
				name: name,
				startDate: startDate,
				endDate: endDate,
				tripDescription: tripDescription,
				totalBudget: totalBudget
			)
			loadTrips()
			return trip
		} catch {
			self.error = .apiError("Failed to create trip: \(error.localizedDescription)")
			return nil
		}
	}

	func deleteTrip(_ trip: Trip) {
		guard let repository else { return }

		do {
			try repository.deleteTrip(trip)
			loadTrips()
		} catch {
			self.error = .apiError("Failed to delete trip: \(error.localizedDescription)")
		}
	}

	func saveChanges() {
		guard let repository else { return }

		do {
			try repository.save()
			loadTrips()
		} catch {
			self.error = .apiError("Failed to save trip changes: \(error.localizedDescription)")
		}
	}
}

