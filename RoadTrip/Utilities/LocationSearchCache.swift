import Foundation

final class LocationSearchCache {
    private let key = "com.roadtrip.locationSearchCache.v1"
    private let maxEntries = 200

    static let shared = LocationSearchCache()

    private init() {}

    func save(query: String) {
        var items = loadAll()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Move to front
        items.removeAll(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        items.insert(trimmed, at: 0)

        if items.count > maxEntries {
            items = Array(items.prefix(maxEntries))
        }

        UserDefaults.standard.set(items, forKey: key)
    }

    func loadAll() -> [String] {
        (UserDefaults.standard.array(forKey: key) as? [String]) ?? []
    }

    func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
