import Foundation

final class SyncManager {
    static let shared = SyncManager()

    struct SyncOperation: Codable, Equatable, Identifiable {
        enum Kind: String, Codable {
            case createTrip
            case updateTrip
            case deleteTrip
            case createDay
            case updateDay
            case deleteDay
            case createActivity
            case updateActivity
            case deleteActivity
            case reorderActivities
            case unknown
        }

        var id: UUID
        var kind: Kind
        var entityId: UUID?
        var tripId: UUID?
        var dayId: UUID?
        var createdAt: Date
        var payload: [String: String]

        init(
            id: UUID = UUID(),
            kind: Kind,
            entityId: UUID? = nil,
            tripId: UUID? = nil,
            dayId: UUID? = nil,
            createdAt: Date = Date(),
            payload: [String: String] = [:]
        ) {
            self.id = id
            self.kind = kind
            self.entityId = entityId
            self.tripId = tripId
            self.dayId = dayId
            self.createdAt = createdAt
            self.payload = payload
        }
    }

    private var queue: [SyncOperation] = []
    private let key = "com.roadtrip.syncQueue.v1"
    private let legacyKey = "com.roadtrip.syncQueue.v0"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        queue = loadQueue()
    }

    func enqueue(_ op: SyncOperation) {
        queue.append(op)
        persist()
    }

    // Backward-compatible helper used by existing callers that only pass a string.
    func enqueue(_ op: String) {
        enqueue(SyncOperation(kind: .unknown, payload: ["legacyOperation": op]))
    }

    func dequeueOperation() -> SyncOperation? {
        guard !queue.isEmpty else { return nil }
        let first = queue.removeFirst()
        persist()
        return first
    }

    func dequeue() -> String? {
        dequeueOperation()?.payload["legacyOperation"]
    }

    func allOperations() -> [SyncOperation] {
        queue
    }

    func all() -> [String] {
        queue.compactMap { $0.payload["legacyOperation"] }
    }

    func clear() {
        queue.removeAll()
        persist()
    }

    private func persist() {
        if let data = try? encoder.encode(queue) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadQueue() -> [SyncOperation] {
        if let data = UserDefaults.standard.data(forKey: key),
           let ops = try? decoder.decode([SyncOperation].self, from: data) {
            return ops
        }

        // Migrate previous simple string queue format to typed operations.
        let legacy = (UserDefaults.standard.array(forKey: legacyKey) as? [String]) ?? []
        if !legacy.isEmpty {
            let migrated = legacy.map {
                SyncOperation(kind: .unknown, payload: ["legacyOperation": $0])
            }
            if let data = try? encoder.encode(migrated) {
                UserDefaults.standard.set(data, forKey: key)
                UserDefaults.standard.removeObject(forKey: legacyKey)
            }
            return migrated
        }

        return []
    }
}
