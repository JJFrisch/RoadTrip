//
//  TripAPIService.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation

struct TripListResponseDTO: Decodable {
    var trips: [TripDTO]
}

struct CreateTripRequestDTO: Encodable {
    var name: String
    var startDate: Date
    var endDate: Date
    var tripDescription: String?
    var totalBudget: Double?
}

struct UpdateTripRequestDTO: Encodable {
    var name: String?
    var tripDescription: String?
    var totalBudget: Double?
    var coverImage: String?
}

protocol TripAPIService {
    func listTrips() async throws -> [TripDTO]
    func getTrip(id: UUID) async throws -> TripDTO
    func createTrip(_ request: CreateTripRequestDTO) async throws -> TripDTO
    func updateTrip(id: UUID, request: UpdateTripRequestDTO) async throws -> TripDTO
    func deleteTrip(id: UUID) async throws
}

final class DefaultTripAPIService: TripAPIService {
    private let client: APIClient
    private let encoder: JSONEncoder

    init(client: APIClient, encoder: JSONEncoder = JSONEncoder()) {
        self.client = client
        let configuredEncoder = encoder
        configuredEncoder.dateEncodingStrategy = .iso8601
        self.encoder = configuredEncoder
    }

    func listTrips() async throws -> [TripDTO] {
        let endpoint = APIEndpoint<TripListResponseDTO>(path: "trips")
        let response = try await client.send(endpoint)
        return response.trips
    }

    func getTrip(id: UUID) async throws -> TripDTO {
        let endpoint = APIEndpoint<TripDTO>(path: "trips/\(id.uuidString)")
        return try await client.send(endpoint)
    }

    func createTrip(_ request: CreateTripRequestDTO) async throws -> TripDTO {
        let body = try encoder.encode(request)
        let endpoint = APIEndpoint<TripDTO>(path: "trips", method: .post, body: body)
        return try await client.send(endpoint)
    }

    func updateTrip(id: UUID, request: UpdateTripRequestDTO) async throws -> TripDTO {
        let body = try encoder.encode(request)
        let endpoint = APIEndpoint<TripDTO>(path: "trips/\(id.uuidString)", method: .patch, body: body)
        return try await client.send(endpoint)
    }

    func deleteTrip(id: UUID) async throws {
        let endpoint = APIEndpoint<EmptyResponse>(path: "trips/\(id.uuidString)", method: .delete)
        try await client.send(endpoint)
    }
}
