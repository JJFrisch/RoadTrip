//
//  RouteOptimizationService.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import MapKit
import SwiftUI
import SwiftData

// MARK: - Route Optimization Service
class RouteOptimizationService: ObservableObject {
    static let shared = RouteOptimizationService()
    
    @Published var isOptimizing = false
    @Published var optimizationProgress: Double = 0
    
    private init() {}
    
    // MARK: - Main Optimization Function
    @MainActor
    func optimizeDay(_ day: TripDay, considerTime: Bool = true, considerTraffic: Bool = false) async throws -> [Activity] {
        isOptimizing = true
        optimizationProgress = 0
        
        defer {
            isOptimizing = false
            optimizationProgress = 0
        }
        
        // Filter activities with coordinates
        let activities = day.activities.filter { $0.hasCoordinates }
        guard activities.count > 1 else { return activities }
        
        await updateProgress(0.2)
        
        // Build distance matrix
        let distanceMatrix = try await buildDistanceMatrix(for: activities)
        
        await updateProgress(0.5)
        
        // Find optimal order using nearest neighbor algorithm
        var optimizedOrder = nearestNeighborTSP(activities: activities, distanceMatrix: distanceMatrix)
        
        await updateProgress(0.7)
        
        // Apply time-based constraints if needed
        if considerTime {
            optimizedOrder = try await applyTimeConstraints(to: optimizedOrder, on: day)
        }
        
        await updateProgress(1.0)
        
        return optimizedOrder
    }
    }
    
    // MARK: - Distance Matrix
    private func buildDistanceMatrix(for activities: [Activity]) async throws -> [[Double]] {
        let count = activities.count
        var matrix = Array(repeating: Array(repeating: 0.0, count: count), count: count)
        
        for i in 0..<count {
            for j in i+1..<count {
                let distance = try await calculateDistance(
                    from: activities[i],
                    to: activities[j]
                )
                matrix[i][j] = distance
                matrix[j][i] = distance
            }
        }
        
        return matrix
    }
    
    private func calculateDistance(from: Activity, to: Activity) async throws -> Double {
        guard let fromLat = from.latitude, let fromLon = from.longitude,
              let toLat = to.latitude, let toLon = to.longitude else {
            return 0
        }
        
        // Check cache first
        if let cached = RouteCacheManager.shared.getCachedRoute(from: from.location, to: to.location) {
            return cached.distance
        }
        
        // Calculate using MapKit
        let fromCoord = CLLocationCoordinate2D(latitude: fromLat, longitude: fromLon)
        let toCoord = CLLocationCoordinate2D(latitude: toLat, longitude: toLon)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoord))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoord))
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        
        do {
            let response = try await directions.calculate()
            if let route = response.routes.first {
                // Cache the result
                let cached = RouteCacheManager.CachedRoute(
                    distance: route.distance,
                    travelTime: route.expectedTravelTime,
                    polyline: route.polyline,
                    timestamp: Date()
                )
                RouteCacheManager.shared.cacheRoute(cached, from: from.location, to: to.location)
                
                return route.distance
            }
        } catch {
            // Fallback to straight-line distance
            let fromLocation = CLLocation(latitude: fromLat, longitude: fromLon)
            let toLocation = CLLocation(latitude: toLat, longitude: toLon)
            return fromLocation.distance(from: toLocation)
        }
        
        return 0
    }
    
    // MARK: - Nearest Neighbor TSP
    private func nearestNeighborTSP(activities: [Activity], distanceMatrix: [[Double]]) -> [Activity] {
        guard activities.count > 1 else { return activities }
        
        var unvisited = Set(activities.indices)
        var route: [Int] = []
        
        // Start with first activity (could be start location)
        var current = 0
        route.append(current)
        unvisited.remove(current)
        
        // Visit nearest neighbor until all visited
        while !unvisited.isEmpty {
            var nearest = -1
            var nearestDistance = Double.infinity
            
            for candidate in unvisited {
                let distance = distanceMatrix[current][candidate]
                if distance < nearestDistance {
                    nearest = candidate
                    nearestDistance = distance
                }
            }
            
            if nearest != -1 {
                route.append(nearest)
                unvisited.remove(nearest)
                current = nearest
            }
        }
        
        // Return activities in optimized order
        return route.map { activities[$0] }
    }
    
    // MARK: - Time Constraints
    private func applyTimeConstraints(to activities: [Activity], on day: TripDay) async throws -> [Activity] {
        let orderedActivities = activities
        
        // Separate activities by time constraints
        var scheduled: [(Activity, Date)] = []
        var flexible: [Activity] = []
        
        for activity in orderedActivities {
            if let time = activity.scheduledTime {
                scheduled.append((activity, time))
            } else {
                flexible.append(activity)
            }
        }
        
        // Sort scheduled by time
        scheduled.sort { $0.1 < $1.1 }
        
        // Interleave flexible activities optimally
        var result: [Activity] = []
        var flexibleIndex = 0
        
        for (scheduledActivity, _) in scheduled {
            // Add flexible activities that fit before this scheduled one
            while flexibleIndex < flexible.count {
                result.append(flexible[flexibleIndex])
                flexibleIndex += 1
                
                // Check if we should stop to make the scheduled activity
                if shouldInsertScheduledActivity(scheduledActivity, after: result) {
                    break
                }
            }
            
            result.append(scheduledActivity)
        }
        
        // Add remaining flexible activities
        while flexibleIndex < flexible.count {
            result.append(flexible[flexibleIndex])
            flexibleIndex += 1
        }
        
        return result
    }
    
    private func shouldInsertScheduledActivity(_ activity: Activity, after current: [Activity]) -> Bool {
        // Simple heuristic: insert scheduled activities at their appropriate time
        guard let scheduledTime = activity.scheduledTime else { return true }
        
        // Calculate estimated time to reach this point
        let estimatedDuration = current.reduce(0.0) { sum, act in
            sum + (act.duration ?? 1.0)
        }

        // Compare against time until the scheduled start (in hours)
        let hoursUntilScheduled = scheduledTime.timeIntervalSinceNow / 3600
        if hoursUntilScheduled <= 0 {
            return true // we're past the scheduled time
        }

        // Insert when the accumulated duration would push us past the scheduled start
        return estimatedDuration >= hoursUntilScheduled
    }
    
    // MARK: - Smart Suggestions
    func suggestMealTimes(for activities: [Activity]) -> [String] {
        var suggestions: [String] = []
        
        let foodActivities = activities.filter { $0.category == "Food" }
        
        if foodActivities.isEmpty {
            suggestions.append("Consider adding meal stops every 4-5 hours")
        }
        
        // Check spacing between meals
        for i in 0..<foodActivities.count-1 {
            if let time1 = foodActivities[i].scheduledTime,
               let time2 = foodActivities[i+1].scheduledTime {
                let hoursBetween = time2.timeIntervalSince(time1) / 3600
                if hoursBetween > 6 {
                    suggestions.append("Long gap between \(foodActivities[i].name) and \(foodActivities[i+1].name)")
                }
            }
        }
        
        return suggestions
    }
    
    func suggestOpeningHours(for activity: Activity) -> String? {
        // This would integrate with Google Places API
        // For now, return general suggestions based on category
        switch activity.category {
        case "Attraction":
            return "Most attractions open 9 AM - 5 PM"
        case "Food":
            return "Check restaurant hours - many close between lunch and dinner"
        default:
            return nil
        }
    }
    
    // MARK: - Helper
    @MainActor
    private func updateProgress(_ value: Double) {
        optimizationProgress = value
    }
}

// MARK: - Optimization View
struct RouteOptimizationView: View {
    @Bindable var day: TripDay
    @StateObject private var optimizer = RouteOptimizationService.shared
    @State private var showingResults = false
    @State private var optimizedActivities: [Activity] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Optimize Route")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Reorder activities to minimize travel time and distance")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                OptimizationOptionRow(
                    icon: "clock.fill",
                    title: "Respect Scheduled Times",
                    description: "Keep activities at their scheduled times"
                )
                
                OptimizationOptionRow(
                    icon: "car.fill",
                    title: "Minimize Distance",
                    description: "Find the shortest route between locations"
                )
                
                OptimizationOptionRow(
                    icon: "fork.knife",
                    title: "Suggest Meal Times",
                    description: "Recommend when to add food stops"
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            
            if optimizer.isOptimizing {
                VStack(spacing: 12) {
                    ProgressView(value: optimizer.optimizationProgress)
                    Text("Optimizing route...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                Button {
                    optimizeRoute()
                } label: {
                    Label("Optimize Now", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding()
            }
        }
        .padding()
        .sheet(isPresented: $showingResults) {
            OptimizationResultsView(
                originalActivities: day.activities,
                optimizedActivities: optimizedActivities,
                onApply: {
                    applyOptimization()
                }
            )
        }
    }
    
    func optimizeRoute() {
        Task {
            do {
                optimizedActivities = try await optimizer.optimizeDay(day, considerTime: true)
                showingResults = true
            } catch {
                ToastManager.shared.show("Failed to optimize route", type: .error)
            }
        }
    }
    
    func applyOptimization() {
        Task { @MainActor in
            for (index, activity) in optimizedActivities.enumerated() {
                activity.order = index
            }
            day.activities = optimizedActivities
            ToastManager.shared.show("Route optimized!", type: .success)
        }
    }
}

struct OptimizationOptionRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct OptimizationResultsView: View {
    let originalActivities: [Activity]
    let optimizedActivities: [Activity]
    let onApply: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Original Order") {
                    ForEach(Array(originalActivities.enumerated()), id: \.element.id) { index, activity in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 30)
                            Text(activity.name)
                        }
                    }
                }
                
                Section("Optimized Order") {
                    ForEach(Array(optimizedActivities.enumerated()), id: \.element.id) { index, activity in
                        HStack {
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .fontWeight(.bold)
                                .frame(width: 30)
                            Text(activity.name)
                        }
                    }
                }
            }
            .navigationTitle("Route Optimization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                }
            }
        }
    }
}
