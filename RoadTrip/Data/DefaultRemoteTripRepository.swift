//
//  DefaultRemoteTripRepository.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

@MainActor
protocol RemoteTripRepository {
    func listTrips() async throws -> [TripDTO]
    func getTrip(id: UUID) async throws -> TripDTO
    func createTrip(from trip: Trip) async throws -> TripDTO
    func updateTrip(from trip: Trip) async throws -> TripDTO
    func deleteTrip(id: UUID) async throws
}

@MainActor
final class DefaultRemoteTripRepository: RemoteTripRepository {
    private let service: TripAPIService

    init(service: TripAPIService) {
        self.service = service
    }

    func listTrips() async throws -> [TripDTO] {
        try await service.listTrips()
    }

    func getTrip(id: UUID) async throws -> TripDTO {
        try await service.getTrip(id: id)
    }

    func createTrip(from trip: Trip) async throws -> TripDTO {
        let request = CreateTripRequestDTO(
            name: trip.name,
            startDate: trip.startDate,
            endDate: trip.endDate,
            tripDescription: trip.tripDescription,
            totalBudget: trip.totalBudget
        )
        return try await service.createTrip(request)
    }

    func updateTrip(from trip: Trip) async throws -> TripDTO {
        let request = UpdateTripRequestDTO(
            name: trip.name,
            tripDescription: trip.tripDescription,
            totalBudget: trip.totalBudget,
            coverImage: trip.coverImage
        )
        return try await service.updateTrip(id: trip.id, request: request)
    }

    func deleteTrip(id: UUID) async throws {
        try await service.deleteTrip(id: id)
    }
}
