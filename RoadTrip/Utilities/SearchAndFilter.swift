//
//  SearchAndFilter.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import Foundation
import SwiftData

// MARK: - Trip Search & Filter Manager
class TripSearchManager: ObservableObject {
    @Published var searchText = ""
    @Published var sortOption: SortOption = .dateNewest
    
    enum SortOption: String, CaseIterable {
        case dateNewest = "Newest First"
        case dateOldest = "Oldest First"
        case nameAZ = "Name (A-Z)"
        case nameZA = "Name (Z-A)"
        case durationLongest = "Longest Trip"
        case durationShortest = "Shortest Trip"
        
        func sort(_ trips: [Trip]) -> [Trip] {
            switch self {
            case .dateNewest:
                return trips.sorted { $0.createdAt > $1.createdAt }
            case .dateOldest:
                return trips.sorted { $0.createdAt < $1.createdAt }
            case .nameAZ:
                return trips.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            case .nameZA:
                return trips.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
            case .durationLongest:
                return trips.sorted { $0.numberOfNights > $1.numberOfNights }
            case .durationShortest:
                return trips.sorted { $0.numberOfNights < $1.numberOfNights }
            }
        }
    }
    
    func filterAndSort(_ trips: [Trip]) -> [Trip] {
        var filtered = trips
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { trip in
                trip.name.localizedCaseInsensitiveContains(searchText) ||
                (trip.tripDescription?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                trip.days.contains { day in
                    day.startLocation.localizedCaseInsensitiveContains(searchText) ||
                    day.endLocation.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Apply sort
        return sortOption.sort(filtered)
    }
}

// MARK: - Activity Filter Manager
class ActivityFilterManager: ObservableObject {
    @Published var selectedCategory: ActivityCategory = .all
    @Published var showCompletedOnly = false
    @Published var showIncompleteOnly = false
    @Published var sortBy: ActivitySort = .order
    
    enum ActivityCategory: String, CaseIterable {
        case all = "All"
        case food = "Food"
        case attraction = "Attraction"
        case hotel = "Hotel"
        case other = "Other"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .food: return "fork.knife"
            case .attraction: return "star.fill"
            case .hotel: return "bed.double.fill"
            case .other: return "ellipsis.circle"
            }
        }
    }
    
    enum ActivitySort: String, CaseIterable {
        case order = "Default Order"
        case time = "Time"
        case name = "Name"
        case cost = "Cost"
        
        func sort(_ activities: [Activity]) -> [Activity] {
            switch self {
            case .order:
                return activities.sorted { $0.order < $1.order }
            case .time:
                return activities.sorted { (a, b) in
                    guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                        return a.scheduledTime != nil
                    }
                    return timeA < timeB
                }
            case .name:
                return activities.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            case .cost:
                return activities.sorted { (a, b) in
                    guard let costA = a.estimatedCost, let costB = b.estimatedCost else {
                        return a.estimatedCost != nil
                    }
                    return costA > costB
                }
            }
        }
    }
    
    func filter(_ activities: [Activity]) -> [Activity] {
        var filtered = activities
        
        // Category filter
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory.rawValue }
        }
        
        // Completion filter
        if showCompletedOnly {
            filtered = filtered.filter { $0.isCompleted }
        } else if showIncompleteOnly {
            filtered = filtered.filter { !$0.isCompleted }
        }
        
        // Sort
        return sortBy.sort(filtered)
    }
}
