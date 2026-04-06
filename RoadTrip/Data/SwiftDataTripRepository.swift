//
//  SwiftDataTripRepository.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataTripRepository: TripRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchTrips() throws -> [Trip] {
        var descriptor = FetchDescriptor<Trip>(
            sortBy: [SortDescriptor(\Trip.createdAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor)
    }

    func createTrip(
        name: String,
        startDate: Date,
        endDate: Date,
        tripDescription: String?,
        totalBudget: Double?
    ) throws -> Trip {
        let trip = Trip(name: name, startDate: startDate, endDate: endDate)
        trip.tripDescription = tripDescription
        trip.totalBudget = totalBudget
        modelContext.insert(trip)
        try modelContext.save()
        return trip
    }

    func deleteTrip(_ trip: Trip) throws {
        modelContext.delete(trip)
        try modelContext.save()
    }

    func save() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
}
