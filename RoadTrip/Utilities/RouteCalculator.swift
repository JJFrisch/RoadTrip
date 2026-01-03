// Utilities/RouteCalculator.swift
import Foundation
import MapKit

class RouteCalculator {
    static let shared = RouteCalculator()
    private let cache = LocationCache.shared
    
    private init() {}
    
    /// Calculate route with caching support
    func calculateRoute(
        from startLocation: String,
        to endLocation: String,
        transportType: MKDirectionsTransportType = .automobile
    ) async throws -> RouteInfo {
        // Check cache first
        if let cachedRoute = cache.getCachedRoute(from: startLocation, to: endLocation, transportType: transportType) {
            return cachedRoute
        }
        
        // Get placemarks (with caching)
        let startPlacemark = try await getPlacemark(for: startLocation)
        let endPlacemark = try await getPlacemark(for: endLocation)
        
        // Calculate route
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startPlacemark)
        request.destination = MKMapItem(placemark: endPlacemark)
        request.transportType = transportType
        
        let directions = MKDirections(request: request)
        let response = try await directions.calculate()
        
        guard let route = response.routes.first else {
            throw RouteCalculationError.noRouteFound
        }
        
        let routeInfo = RouteInfo(
            distance: route.distance,
            expectedTravelTime: route.expectedTravelTime
        )
        
        // Cache the route
        cache.cacheRoute(routeInfo, from: startLocation, to: endLocation, transportType: transportType)
        
        return routeInfo
    }
    
    /// Get placemark for location with caching
    func getPlacemark(for location: String) async throws -> MKPlacemark {
        // Check cache first
        if let cachedPlacemark = cache.getCachedPlacemark(for: location) {
            return cachedPlacemark
        }
        
        // Search for location
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = location
        let search = MKLocalSearch(request: request)
        
        let response = try await search.start()
        
        guard let placemark = response.mapItems.first?.placemark else {
            throw RouteCalculationError.locationNotFound
        }
        
        // Cache the placemark
        cache.cachePlacemark(placemark, for: location)
        
        return placemark
    }
    
    /// Batch calculate multiple routes (useful for trip overview)
    func calculateMultipleRoutes(
        routes: [(from: String, to: String)],
        transportType: MKDirectionsTransportType = .automobile
    ) async -> [String: RouteInfo] {
        var results: [String: RouteInfo] = [:]
        
        await withTaskGroup(of: (String, RouteInfo?).self) { group in
            for route in routes {
                group.addTask {
                    let key = "\(route.from)|\(route.to)"
                    let routeInfo = try? await self.calculateRoute(
                        from: route.from,
                        to: route.to,
                        transportType: transportType
                    )
                    return (key, routeInfo)
                }
            }
            
            for await (key, routeInfo) in group {
                if let routeInfo = routeInfo {
                    results[key] = routeInfo
                }
            }
        }
        
        return results
    }
}

enum RouteCalculationError: Error {
    case noRouteFound
    case locationNotFound
    case invalidInput
}
