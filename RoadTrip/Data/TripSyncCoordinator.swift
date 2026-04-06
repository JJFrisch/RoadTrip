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
    enum ConflictPolicy {
        case lastWriteWins
        case serverVersionCompare
    }

    private struct TripVersionRecord: Codable {
        let version: Int
        let updatedAt: Date
    }

    private let modelContext: ModelContext
    private let localRepository: SwiftDataTripRepository
    private let remoteRepository: RemoteTripRepository
    private let syncManager: SyncManager
    private let conflictPolicy: ConflictPolicy

    private let versionStoreKey = "roadtrip.sync.tripVersions.v1"
    private let defaults = UserDefaults.standard

    init(
        modelContext: ModelContext,
        localRepository: SwiftDataTripRepository,
        remoteRepository: RemoteTripRepository,
        syncManager: SyncManager = .shared,
        conflictPolicy: ConflictPolicy = .serverVersionCompare
    ) {
        self.modelContext = modelContext
        self.localRepository = localRepository
        self.remoteRepository = remoteRepository
        self.syncManager = syncManager
        self.conflictPolicy = conflictPolicy
    }

    func syncFromRemote() async throws -> [Trip] {
        let remoteTrips = try await remoteRepository.listTrips()
        let trips = try TripDTOUpsertMapper.upsertTrips(remoteTrips, in: modelContext)
        recordVersions(from: remoteTrips)
        return trips
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
        setLocalVersion(for: trip.id, version: 1, updatedAt: Date())
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

        let next = currentLocalVersion(for: trip.id) + 1
        setLocalVersion(for: trip.id, version: next, updatedAt: Date())
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
            setLocalVersion(for: syncedTrip.id, version: remoteDTO.sync.version, updatedAt: remoteDTO.sync.updatedAt)

            if syncedTrip.id != localTrip.id {
                modelContext.delete(localTrip)
                try localRepository.save()
            }

        case .updateTrip:
            guard let id = operation.entityId,
                  let localTrip = try findTrip(by: id) else {
                return
            }

            if conflictPolicy == .serverVersionCompare {
                let remoteSnapshot = try await remoteRepository.getTrip(id: id)
                let remoteVersion = remoteSnapshot.sync.version
                let localVersion = currentLocalVersion(for: id)

                if remoteVersion > localVersion {
                    _ = try TripDTOUpsertMapper.upsertTrip(remoteSnapshot, in: modelContext)
                    setLocalVersion(for: id, version: remoteVersion, updatedAt: remoteSnapshot.sync.updatedAt)
                    return
                }
            }

            let remoteDTO = try await remoteRepository.updateTrip(from: localTrip)
            _ = try TripDTOUpsertMapper.upsertTrip(remoteDTO, in: modelContext)
            setLocalVersion(for: id, version: remoteDTO.sync.version, updatedAt: remoteDTO.sync.updatedAt)

        case .deleteTrip:
            guard let id = operation.entityId else {
                return
            }

            if conflictPolicy == .serverVersionCompare {
                let remoteSnapshot = try await remoteRepository.getTrip(id: id)
                let remoteVersion = remoteSnapshot.sync.version
                let localVersion = currentLocalVersion(for: id)

                if remoteVersion > localVersion {
                    _ = try TripDTOUpsertMapper.upsertTrip(remoteSnapshot, in: modelContext)
                    setLocalVersion(for: id, version: remoteVersion, updatedAt: remoteSnapshot.sync.updatedAt)
                    return
                }
            }

            try await remoteRepository.deleteTrip(id: id)
            clearLocalVersion(for: id)

        default:
            break
        }
    }

    private func findTrip(by id: UUID) throws -> Trip? {
        let trips = try localRepository.fetchTrips()
        return trips.first(where: { $0.id == id })
    }

    private func recordVersions(from tripDTOs: [TripDTO]) {
        var versions = loadVersionMap()
        for dto in tripDTOs {
            versions[dto.id.uuidString] = TripVersionRecord(version: dto.sync.version, updatedAt: dto.sync.updatedAt)
        }
        saveVersionMap(versions)
    }

    private func currentLocalVersion(for tripID: UUID) -> Int {
        let versions = loadVersionMap()
        return versions[tripID.uuidString]?.version ?? 1
    }

    private func setLocalVersion(for tripID: UUID, version: Int, updatedAt: Date) {
        var versions = loadVersionMap()
        versions[tripID.uuidString] = TripVersionRecord(version: max(1, version), updatedAt: updatedAt)
        saveVersionMap(versions)
    }

    private func clearLocalVersion(for tripID: UUID) {
        var versions = loadVersionMap()
        versions.removeValue(forKey: tripID.uuidString)
        saveVersionMap(versions)
    }

    private func loadVersionMap() -> [String: TripVersionRecord] {
        guard let data = defaults.data(forKey: versionStoreKey) else {
            return [:]
        }

        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([String: TripVersionRecord].self, from: data) {
            return decoded
        }

        return [:]
    }

    private func saveVersionMap(_ versions: [String: TripVersionRecord]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(versions) {
            defaults.set(data, forKey: versionStoreKey)
        }
    }
}
