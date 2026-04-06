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
	private var syncCoordinator: TripSyncCoordinator?

	func configure(with modelContext: ModelContext) {
		let localRepository = SwiftDataTripRepository(modelContext: modelContext)
		repository = localRepository

		let tokenStore = AuthTokenStore.shared
		let apiClient = URLSessionAPIClient(
			baseURL: APIEnvironment.development.baseURL,
			tokenProvider: tokenStore,
			tokenRefresher: tokenStore,
			maxRetryAttempts: Config.maxRetryAttempts,
			retryBaseDelay: Config.retryDelay
		)
		let tripService = DefaultTripAPIService(client: apiClient)
		let remoteRepository = DefaultRemoteTripRepository(service: tripService)
		syncCoordinator = TripSyncCoordinator(
			modelContext: modelContext,
			localRepository: localRepository,
			remoteRepository: remoteRepository
		)
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
			syncCoordinator?.enqueueCreateTrip(trip)
			Task {
				await syncCoordinator?.flushQueue()
			}
			loadTrips()
			return trip
		} catch {
			self.error = .apiError("Failed to create trip: \(error.localizedDescription)")
			return nil
		}
	}

	func deleteTrip(_ trip: Trip) {
		guard let repository else { return }
		syncCoordinator?.enqueueDeleteTrip(id: trip.id)

		do {
			try repository.deleteTrip(trip)
			Task {
				await syncCoordinator?.flushQueue()
			}
			loadTrips()
		} catch {
			self.error = .apiError("Failed to delete trip: \(error.localizedDescription)")
		}
	}

	func saveChanges() {
		guard let repository else { return }

		do {
			try repository.save()
			for trip in trips {
				syncCoordinator?.enqueueUpdateTrip(trip)
			}
			Task {
				await syncCoordinator?.flushQueue()
			}
			loadTrips()
		} catch {
			self.error = .apiError("Failed to save trip changes: \(error.localizedDescription)")
		}
	}

	func syncTripsIfNeeded() async {
		guard let syncCoordinator else { return }

		do {
			_ = try await syncCoordinator.syncFromRemote()
			loadTrips()
		} catch {
			self.error = .apiError("Remote sync failed: \(error.localizedDescription)")
		}
	}
}

