//
//  PerformanceOptimizations.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import MapKit
import SwiftUI

// MARK: - Route Cache Manager
class RouteCacheManager: ObservableObject {
    static let shared = RouteCacheManager()
    
    private var routeCache: [String: CachedRoute] = [:]
    private let maxCacheSize = 100
    private let cacheExpirationDays = 7
    
    struct CachedRoute {
        let distance: Double
        let travelTime: Double
        let polyline: MKPolyline
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 7 * 24 * 3600 // 7 days
        }
    }
    
    private init() {}
    
    func cacheKey(from start: String, to end: String) -> String {
        "\(start.lowercased())_to_\(end.lowercased())"
    }
    
    func getCachedRoute(from start: String, to end: String) -> CachedRoute? {
        let key = cacheKey(from: start, to: end)
        guard let cached = routeCache[key], !cached.isExpired else {
            routeCache.removeValue(forKey: key)
            return nil
        }
        return cached
    }
    
    func cacheRoute(_ route: CachedRoute, from start: String, to end: String) {
        let key = cacheKey(from: start, to: end)
        
        // Remove oldest entries if cache is full
        if routeCache.count >= maxCacheSize {
            let sortedByAge = routeCache.sorted { $0.value.timestamp < $1.value.timestamp }
            if let oldestKey = sortedByAge.first?.key {
                routeCache.removeValue(forKey: oldestKey)
            }
        }
        
        routeCache[key] = route
    }
    
    func clearExpiredRoutes() {
        routeCache = routeCache.filter { !$0.value.isExpired }
    }
    
    func clearCache() {
        routeCache.removeAll()
    }
}

// MARK: - Coordinate Cache
class CoordinateCache: ObservableObject {
    static let shared = CoordinateCache()
    
    private var cache: [String: CachedCoordinate] = [:]
    private let maxCacheSize = 200
    
    struct CachedCoordinate {
        let latitude: Double
        let longitude: Double
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 30 * 24 * 3600 // 30 days
        }
    }
    
    private init() {}
    
    func getCoordinate(for location: String) -> CachedCoordinate? {
        let key = location.lowercased().trimmingCharacters(in: .whitespaces)
        guard let cached = cache[key], !cached.isExpired else {
            cache.removeValue(forKey: key)
            return nil
        }
        return cached
    }
    
    func cacheCoordinate(latitude: Double, longitude: Double, for location: String) {
        let key = location.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Remove oldest if full
        if cache.count >= maxCacheSize {
            let sortedByAge = cache.sorted { $0.value.timestamp < $1.value.timestamp }
            if let oldestKey = sortedByAge.first?.key {
                cache.removeValue(forKey: oldestKey)
            }
        }
        
        cache[key] = CachedCoordinate(latitude: latitude, longitude: longitude, timestamp: Date())
    }
    
    func clearExpired() {
        cache = cache.filter { !$0.value.isExpired }
    }
}

// MARK: - Paginated Activity List
struct PaginatedActivityList: View {
    let activities: [Activity]
    let pageSize: Int = 20
    
    @State private var currentPage = 0
    
    var totalPages: Int {
        max(1, (activities.count + pageSize - 1) / pageSize)
    }
    
    var currentPageActivities: [Activity] {
        let start = currentPage * pageSize
        let end = min(start + pageSize, activities.count)
        return Array(activities[start..<end])
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(currentPageActivities) { activity in
                ActivityRow(activity: activity)
            }
            
            if totalPages > 1 {
                HStack {
                    Button {
                        withAnimation {
                            currentPage = max(0, currentPage - 1)
                        }
                    } label: {
                        Label("Previous", systemImage: "chevron.left")
                    }
                    .disabled(currentPage == 0)
                    
                    Spacer()
                    
                    Text("Page \(currentPage + 1) of \(totalPages)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            currentPage = min(totalPages - 1, currentPage + 1)
                        }
                    } label: {
                        Label("Next", systemImage: "chevron.right")
                    }
                    .disabled(currentPage >= totalPages - 1)
                }
                .padding()
            }
        }
    }
}

// MARK: - Lazy Loading Map Pins
class MapPinManager: ObservableObject {
    @Published var visiblePins: Set<UUID> = []
    
    func shouldShowPin(_ activityId: UUID, in region: MKCoordinateRegion) -> Bool {
        // Only render pins that are in or near the visible region
        visiblePins.contains(activityId)
    }
    
    func updateVisiblePins(for activities: [Activity], in region: MKCoordinateRegion) {
        let regionLatRange = (region.center.latitude - region.span.latitudeDelta/2)...(region.center.latitude + region.span.latitudeDelta/2)
        let regionLonRange = (region.center.longitude - region.span.longitudeDelta/2)...(region.center.longitude + region.span.longitudeDelta/2)
        
        var newVisiblePins: Set<UUID> = []
        
        for activity in activities {
            guard let lat = activity.latitude, let lon = activity.longitude else { continue }
            
            if regionLatRange.contains(lat) && regionLonRange.contains(lon) {
                newVisiblePins.insert(activity.id)
            }
        }
        
        if newVisiblePins != visiblePins {
            DispatchQueue.main.async {
                self.visiblePins = newVisiblePins
            }
        }
    }
}

// Placeholder for ActivityRow
struct ActivityRow: View {
    let activity: Activity
    
    var body: some View {
        HStack {
            Image(systemName: activity.category == "Food" ? "fork.knife" : "star.fill")
            Text(activity.name)
            Spacer()
        }
        .padding()
    }
}
