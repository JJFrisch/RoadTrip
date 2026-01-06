//
//  CloudSyncService.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import CloudKit
import SwiftData

// MARK: - CloudKit Sync Service
class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    
    private let container: CKContainer
    private let database: CKDatabase
    private let recordZone = CKRecordZone(zoneName: "TripsZone")
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.roadtrip.app")
        database = container.privateCloudDatabase
        
        checkAccountStatus()
    }
    
    // MARK: - Account Status
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.accountStatus = status
                
                if let error = error {
                    self?.syncError = error.localizedDescription
                    ErrorRecoveryManager.shared.record(
                        title: "iCloud Account Error",
                        message: error.localizedDescription,
                        severity: .warning
                    )
                }
            }
        }
    }
    
    var isAvailable: Bool {
        accountStatus == .available
    }
    
    // MARK: - Sync Trip to Cloud
    func syncTrip(_ trip: Trip) async throws {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }
        
        do {
            // Create or update record
            let record = try tripToRecord(trip)
            let savedRecord = try await database.save(record)
            
            // Update trip with cloud ID
            DispatchQueue.main.async {
                trip.cloudId = savedRecord.recordID.recordName
                trip.lastSyncedAt = Date()
                self.lastSyncDate = Date()
                
                ToastManager.shared.show("Trip synced to iCloud", type: .success)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.syncError = error.localizedDescription
                ErrorRecoveryManager.shared.record(
                    title: "Sync Failed",
                    message: error.localizedDescription,
                    severity: .error
                )
            }
            throw error
        }
    }
    
    // MARK: - Fetch Trips from Cloud
    func fetchTrips() async throws -> [CKRecord] {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        let query = CKQuery(recordType: "Trip", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let result = try await database.records(matching: query)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
            }
            
            return records
        } catch {
            DispatchQueue.main.async {
                self.syncError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Delete Trip from Cloud
    func deleteTrip(cloudId: String) async throws {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        let recordID = CKRecord.ID(recordName: cloudId)
        try await database.deleteRecord(withID: recordID)
    }
    
    // MARK: - Share Trip
    func shareTrip(_ trip: Trip, with userEmail: String) async throws -> String {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        // Generate share code
        let shareCode = UUID().uuidString.prefix(8).uppercased()
        
        // Update trip
        DispatchQueue.main.async {
            trip.shareCode = String(shareCode)
            trip.isShared = true
        }
        
        // Sync to cloud
        try await syncTrip(trip)
        
        return String(shareCode)
    }
    
    func joinTrip(withCode shareCode: String) async throws -> CKRecord? {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        let predicate = NSPredicate(format: "shareCode == %@", shareCode)
        let query = CKQuery(recordType: "Trip", predicate: predicate)
        
        let result = try await database.records(matching: query)
        return try? result.matchResults.first?.1.get()
    }
    
    // MARK: - Helper Methods
    private func tripToRecord(_ trip: Trip) throws -> CKRecord {
        let recordID: CKRecord.ID
        if let cloudId = trip.cloudId {
            recordID = CKRecord.ID(recordName: cloudId, zoneID: recordZone.zoneID)
        } else {
            recordID = CKRecord.ID(recordName: trip.id.uuidString, zoneID: recordZone.zoneID)
        }
        
        let record = CKRecord(recordType: "Trip", recordID: recordID)
        
        // Basic fields
        record["name"] = trip.name as CKRecordValue
        record["tripDescription"] = trip.tripDescription as CKRecordValue?
        record["startDate"] = trip.startDate as CKRecordValue
        record["endDate"] = trip.endDate as CKRecordValue
        record["createdAt"] = trip.createdAt as CKRecordValue
        record["coverImage"] = trip.coverImage as CKRecordValue?
        
        // Sharing fields
        record["ownerId"] = trip.ownerId as CKRecordValue?
        record["ownerEmail"] = trip.ownerEmail as CKRecordValue?
        record["sharedWith"] = trip.sharedWith as CKRecordValue
        record["shareCode"] = trip.shareCode as CKRecordValue?
        record["isShared"] = trip.isShared ? 1 : 0 as CKRecordValue
        
        return record
    }
    
    private func recordToTrip(_ record: CKRecord) -> Trip? {
        guard let name = record["name"] as? String,
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date else {
            return nil
        }
        
        let trip = Trip(name: name, startDate: startDate, endDate: endDate)
        trip.cloudId = record.recordID.recordName
        trip.tripDescription = record["tripDescription"] as? String
        trip.coverImage = record["coverImage"] as? String
        trip.ownerId = record["ownerId"] as? String
        trip.ownerEmail = record["ownerEmail"] as? String
        trip.sharedWith = record["sharedWith"] as? [String] ?? []
        trip.shareCode = record["shareCode"] as? String
        trip.isShared = (record["isShared"] as? Int) == 1
        trip.lastSyncedAt = Date()
        
        return trip
    }
}

// MARK: - Errors
enum CloudSyncError: LocalizedError {
    case accountNotAvailable
    case syncFailed(String)
    case recordNotFound
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud account is not available. Please sign in to iCloud in Settings."
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .recordNotFound:
            return "Trip not found in iCloud."
        }
    }
}
//
//  CloudSyncService.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import CloudKit
import SwiftData

// MARK: - CloudKit Sync Service
class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    
    private let container: CKContainer
    private let database: CKDatabase
    private let recordZone = CKRecordZone(zoneName: "TripsZone")
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.roadtrip.app")
        database = container.privateCloudDatabase
        
        checkAccountStatus()
    }
    
    // MARK: - Account Status
    func checkAccountStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.accountStatus = status
                
                if let error = error {
                    self?.syncError = error.localizedDescription
                    ErrorRecoveryManager.shared.record(
                        title: "iCloud Account Error",
                        message: error.localizedDescription,
                        severity: .warning
                    )
                }
            }
        }
    }
    
    var isAvailable: Bool {
        accountStatus == .available
    }
    
    // MARK: - Sync Trip to Cloud
    func syncTrip(_ trip: Trip) async throws {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        DispatchQueue.main.async {
            self.isSyncing = true
        }
        
        defer {
            DispatchQueue.main.async {
                self.isSyncing = false
            }
        }
        
        do {
            // Create or update record
            let record = try tripToRecord(trip)
            let savedRecord = try await database.save(record)
            
            // Update trip with cloud ID
            DispatchQueue.main.async {
                trip.cloudId = savedRecord.recordID.recordName
                trip.lastSyncedAt = Date()
                self.lastSyncDate = Date()
                
                ToastManager.shared.show("Trip synced to iCloud", type: .success)
            }
            
        } catch {
            DispatchQueue.main.async {
                self.syncError = error.localizedDescription
                ErrorRecoveryManager.shared.record(
                    title: "Sync Failed",
                    message: error.localizedDescription,
                    severity: .error
                )
            }
            throw error
        }
    }
    
    // MARK: - Fetch Trips from Cloud
    func fetchTrips() async throws -> [CKRecord] {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        let query = CKQuery(recordType: "Trip", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let result = try await database.records(matching: query)
            let records = result.matchResults.compactMap { try? $0.1.get() }
            
            DispatchQueue.main.async {
                self.lastSyncDate = Date()
            }
            
            return records
        } catch {
            DispatchQueue.main.async {
                self.syncError = error.localizedDescription
            }
            throw error
        }
    }
    
    // MARK: - Delete Trip from Cloud
    func deleteTrip(cloudId: String) async throws {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        let recordID = CKRecord.ID(recordName: cloudId)
        try await database.deleteRecord(withID: recordID)
    }
    
    // MARK: - Share Trip
    func shareTrip(_ trip: Trip, with userEmail: String) async throws -> String {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        // Generate share code
        let shareCode = UUID().uuidString.prefix(8).uppercased()
        
        // Update trip
        DispatchQueue.main.async {
            trip.shareCode = String(shareCode)
            trip.isShared = true
        }
        
        // Sync to cloud
        try await syncTrip(trip)
        
        return String(shareCode)
    }
    
    func joinTrip(withCode shareCode: String) async throws -> CKRecord? {
        guard isAvailable else {
            throw CloudSyncError.accountNotAvailable
        }
        
        let predicate = NSPredicate(format: "shareCode == %@", shareCode)
        let query = CKQuery(recordType: "Trip", predicate: predicate)
        
        let result = try await database.records(matching: query)
        return try? result.matchResults.first?.1.get()
    }
    
    // MARK: - Helper Methods
    private func tripToRecord(_ trip: Trip) throws -> CKRecord {
        let recordID: CKRecord.ID
        if let cloudId = trip.cloudId {
            recordID = CKRecord.ID(recordName: cloudId, zoneID: recordZone.zoneID)
        } else {
            recordID = CKRecord.ID(recordName: trip.id.uuidString, zoneID: recordZone.zoneID)
        }
        
        let record = CKRecord(recordType: "Trip", recordID: recordID)
        
        // Basic fields
        record["name"] = trip.name as CKRecordValue
        record["tripDescription"] = trip.tripDescription as CKRecordValue?
        record["startDate"] = trip.startDate as CKRecordValue
        record["endDate"] = trip.endDate as CKRecordValue
        record["createdAt"] = trip.createdAt as CKRecordValue
        record["coverImage"] = trip.coverImage as CKRecordValue?
        
        // Sharing fields
        record["ownerId"] = trip.ownerId as CKRecordValue?
        record["ownerEmail"] = trip.ownerEmail as CKRecordValue?
        record["sharedWith"] = trip.sharedWith as CKRecordValue
        record["shareCode"] = trip.shareCode as CKRecordValue?
        record["isShared"] = trip.isShared ? 1 : 0 as CKRecordValue
        
        return record
    }
    
    private func recordToTrip(_ record: CKRecord) -> Trip? {
        guard let name = record["name"] as? String,
              let startDate = record["startDate"] as? Date,
              let endDate = record["endDate"] as? Date else {
            return nil
        }
        
        let trip = Trip(name: name, startDate: startDate, endDate: endDate)
        trip.cloudId = record.recordID.recordName
        trip.tripDescription = record["tripDescription"] as? String
        trip.coverImage = record["coverImage"] as? String
        trip.ownerId = record["ownerId"] as? String
        trip.ownerEmail = record["ownerEmail"] as? String
        trip.sharedWith = record["sharedWith"] as? [String] ?? []
        trip.shareCode = record["shareCode"] as? String
        trip.isShared = (record["isShared"] as? Int) == 1
        trip.lastSyncedAt = Date()
        
        return trip
    }
}

// MARK: - Errors
enum CloudSyncError: LocalizedError {
    case accountNotAvailable
    case syncFailed(String)
    case recordNotFound
    
    var errorDescription: String? {
        switch self {
        case .accountNotAvailable:
            return "iCloud account is not available. Please sign in to iCloud in Settings."
        case .syncFailed(let message):
            return "Sync failed: \(message)"
        case .recordNotFound:
            return "Trip not found in iCloud."
        }
    }
}
