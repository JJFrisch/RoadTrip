import Foundation

final class SyncManager {
    static let shared = SyncManager()

    private var queue: [String] = [] // simple operation queue identifiers
    private let key = "com.roadtrip.syncQueue.v1"

    private init() {
        queue = (UserDefaults.standard.array(forKey: key) as? [String]) ?? []
    }

    func enqueue(_ op: String) {
        queue.append(op)
        persist()
    }

    func dequeue() -> String? {
        guard !queue.isEmpty else { return nil }
        let first = queue.removeFirst()
        persist()
        return first
    }

    func all() -> [String] { queue }

    func clear() {
        queue.removeAll()
        persist()
    }

    private func persist() {
        UserDefaults.standard.set(queue, forKey: key)
    }
}
