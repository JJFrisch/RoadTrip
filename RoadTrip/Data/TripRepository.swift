//
//  TripRepository.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

@MainActor
protocol TripRepository {
    func fetchTrips() throws -> [Trip]
    func createTrip(
        name: String,
        startDate: Date,
        endDate: Date,
        tripDescription: String?,
        totalBudget: Double?
    ) throws -> Trip
    func deleteTrip(_ trip: Trip) throws
    func save() throws
}
