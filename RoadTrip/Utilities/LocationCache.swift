// Utilities/LocationCache.swift
import Foundation
import MapKit

class LocationCache: ObservableObject {
    static let shared = LocationCache()
    
    private let searchCompletionCache = NSCache<NSString, CachedSearchResults>()
    private let placemarkCache = NSCache<NSString, CachedPlacemark>()
    private let routeCache = NSCache<NSString, CachedRoute>()
    
    private init() {
        // Configure cache limits
        searchCompletionCache.countLimit = 100 // Store up to 100 search queries
        placemarkCache.countLimit = 200 // Store up to 200 location details
        routeCache.countLimit = 50 // Store up to 50 routes
        
        // Set memory limits (in bytes)
        searchCompletionCache.totalCostLimit = 1024 * 1024 * 5 // 5 MB
        placemarkCache.totalCostLimit = 1024 * 1024 * 10 // 10 MB
        routeCache.totalCostLimit = 1024 * 1024 * 5 // 5 MB
    }
    
    // MARK: - Search Completion Cache
    
    func cacheSearchResults(_ results: [MKLocalSearchCompletion], for query: String) {
        let cached = CachedSearchResults(results: results, timestamp: Date())
        searchCompletionCache.setObject(cached, forKey: query as NSString)
    }
    
    func getCachedSearchResults(for query: String) -> [MKLocalSearchCompletion]? {
        guard let cached = searchCompletionCache.object(forKey: query as NSString) else {
            return nil
        }
        
        // Return cached results if less than 24 hours old
        if Date().timeIntervalSince(cached.timestamp) < 86400 {
            return cached.results
        }
        
        // Remove stale cache
        searchCompletionCache.removeObject(forKey: query as NSString)
        return nil
    }
    
    // MARK: - Placemark Cache
    
    func cachePlacemark(_ placemark: MKPlacemark, for location: String) {
        let cached = CachedPlacemark(placemark: placemark, timestamp: Date())
        placemarkCache.setObject(cached, forKey: location as NSString)
    }
    
    func getCachedPlacemark(for location: String) -> MKPlacemark? {
        guard let cached = placemarkCache.object(forKey: location as NSString) else {
            return nil
        }
        
        // Return cached placemark if less than 7 days old
        if Date().timeIntervalSince(cached.timestamp) < 604800 {
            return cached.placemark
        }
        
        // Remove stale cache
        placemarkCache.removeObject(forKey: location as NSString)
        return nil
    }
    
    // MARK: - Route Cache
    
    func cacheRoute(_ route: RouteInfo, from: String, to: String, transportType: MKDirectionsTransportType) {
        let key = routeCacheKey(from: from, to: to, transportType: transportType)
        let cached = CachedRoute(route: route, timestamp: Date())
        routeCache.setObject(cached, forKey: key as NSString)
    }
    
    func getCachedRoute(from: String, to: String, transportType: MKDirectionsTransportType) -> RouteInfo? {
        let key = routeCacheKey(from: from, to: to, transportType: transportType)
        guard let cached = routeCache.object(forKey: key as NSString) else {
            return nil
        }
        
        // Return cached route if less than 7 days old
        if Date().timeIntervalSince(cached.timestamp) < 604800 {
            return cached.route
        }
        
        // Remove stale cache
        routeCache.removeObject(forKey: key as NSString)
        return nil
    }
    
    private func routeCacheKey(from: String, to: String, transportType: MKDirectionsTransportType) -> String {
        let type = transportType == .automobile ? "drive" : "walk"
        return "\(from.lowercased())|\(to.lowercased())|\(type)"
    }
    
    // MARK: - Cache Management
    
    func clearAllCaches() {
        searchCompletionCache.removeAllObjects()
        placemarkCache.removeAllObjects()
        routeCache.removeAllObjects()
    }
    
    func clearSearchCache() {
        searchCompletionCache.removeAllObjects()
    }
    
    func clearRouteCache() {
        routeCache.removeAllObjects()
    }
}

// MARK: - Cache Objects

class CachedSearchResults {
    let results: [MKLocalSearchCompletion]
    let timestamp: Date
    
    init(results: [MKLocalSearchCompletion], timestamp: Date) {
        self.results = results
        self.timestamp = timestamp
    }
}

class CachedPlacemark {
    let placemark: MKPlacemark
    let timestamp: Date
    
    init(placemark: MKPlacemark, timestamp: Date) {
        self.placemark = placemark
        self.timestamp = timestamp
    }
}

class CachedRoute {
    let route: RouteInfo
    let timestamp: Date
    
    init(route: RouteInfo, timestamp: Date) {
        self.route = route
        self.timestamp = timestamp
    }
}

struct RouteInfo {
    let distance: Double // in meters
    let expectedTravelTime: TimeInterval // in seconds
    
    var distanceInMiles: Double {
        distance / 1609.34
    }
    
    var durationInHours: Double {
        expectedTravelTime / 3600.0
    }
}
