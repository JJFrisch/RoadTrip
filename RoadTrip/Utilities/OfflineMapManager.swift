import Foundation
import MapKit

final class OfflineMapManager {
    static let shared = OfflineMapManager()

    private init() {}

    /// Placeholder: registers a downloaded region. Real downloads require MapKit tile sets or third-party SDK.
    func markRegionDownloaded(_ region: MKCoordinateRegion, identifier: String) {
        let meta: [String: Any] = ["centerLat": region.center.latitude,
                                   "centerLon": region.center.longitude,
                                   "latDelta": region.span.latitudeDelta,
                                   "lonDelta": region.span.longitudeDelta,
                                   "id": identifier,
                                   "downloadedAt": Date().timeIntervalSince1970]
        var list = (UserDefaults.standard.array(forKey: "offline_map_regions") as? [[String: Any]]) ?? []
        list.append(meta)
        UserDefaults.standard.set(list, forKey: "offline_map_regions")
    }

    func listDownloadedRegions() -> [[String: Any]] {
        (UserDefaults.standard.array(forKey: "offline_map_regions") as? [[String: Any]]) ?? []
    }

    func clearDownloadedRegions() {
        UserDefaults.standard.removeObject(forKey: "offline_map_regions")
    }
}
