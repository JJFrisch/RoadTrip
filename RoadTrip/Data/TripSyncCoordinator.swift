//
//  TripSyncCoordinator.swift
//  RoadTrip
//
//  Created by GitHub Copilot.
//

import Foundation
import SwiftData

@MainActor
final class TripSyncCoordinator {
    private let modelContext: ModelContext
    private let localRepository: SwiftDataTripRepository
    private let remoteRepository: RemoteTripRepository
    private let syncManager: SyncManager

    init(
        modelContext: ModelContext,
        localRepository: SwiftDataTripRepository,
        remoteRepository: RemoteTripRepository,
        syncManager: SyncManager = .shared
    ) {
        self.modelContext = modelContext
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
        self.syncManager = syncManager
    }

    func syncFromRemote() async throws -> [Trip] {
        let remoteTrips = try await remoteRepository.listTrips()
        return try TripDTOUpsertMapper.upsertTrips(remoteTrips, in: modelContext)
    }

    func enqueueCreateTrip(_ trip: Trip) {
        syncManager.enqueue(
            SyncManager.SyncOperation(
                kind: .createTrip,
                entityId: trip.id,
                tripId: trip.id,
                payload: [
                    "name": trip.name,
                    "startDate": ISO8601DateFormatter().string(from: trip.startDate),
                    "endDate": ISO8601DateFormatter().string(from: trip.endDate)
                ]
            )
        )
    }

    func enqueueUpdateTrip(_ trip: Trip) {
        syncManager.enqueue(
            SyncManager.SyncOperation(
                kind: .updateTrip,
                entityId: trip.id,
                tripId: trip.id,
                payload: ["name": trip.name]
            )
        )
    }

    func enqueueDeleteTrip(id: UUID) {
        syncManager.enqueue(
            SyncManager.SyncOperation(
                kind: .deleteTrip,
                entityId: id,
                tripId: id
            )
        )
    }

    func flushQueue() async {
        while let operation = syncManager.dequeueOperation() {
            do {
                try await process(operation)
            } catch {
                // Re-enqueue and stop so we preserve ordering for next sync attempt.
                syncManager.enqueue(operation)
                break
            }
        }
    }

    private func process(_ operation: SyncManager.SyncOperation) async throws {
        switch operation.kind {
        case .createTrip:
            guard let id = operation.entityId,
                  let localTrip = try findTrip(by: id) else {
                return
            }

            let remoteDTO = try await remoteRepository.createTrip(from: localTrip)
            let syncedTrip = try TripDTOUpsertMapper.upsertTrip(remoteDTO, in: modelContext)

            if syncedTrip.id != localTrip.id {
                modelContext.delete(localTrip)
                try localRepository.save()
            }

        case .updateTrip:
            guard let id = operation.entityId,
                  let localTrip = try findTrip(by: id) else {
                return
            }

            let remoteDTO = try await remoteRepository.updateTrip(from: localTrip)
            _ = try TripDTOUpsertMapper.upsertTrip(remoteDTO, in: modelContext)

        case .deleteTrip:
            guard let id = operation.entityId else {
                return
            }
            try await remoteRepository.deleteTrip(id: id)

        default:
            break
        }
    }

    private func findTrip(by id: UUID) throws -> Trip? {
        let trips = try localRepository.fetchTrips()
        return trips.first(where: { $0.id == id })
    }
}
