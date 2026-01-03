// Views/TripDetail/TripDetailView.swift
//  Created by Jake Frischmann on 1/1/26.

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @State private var selectedTab = 0
    @State private var showingEditSheet = false
    @State private var showingOfflineMapSheet = false
    @State private var isPrefetchingRoutes = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Content
            TabView(selection: $selectedTab) {
                OverviewView(trip: trip)
                    .tag(0)
                
                ActivitiesView(trip: trip)
                    .tag(1)
                
                ScheduleView(trip: trip)
                    .tag(2)
                
                RouteInfoView(trip: trip)
                    .tag(3)
                
                TripMapView(trip: trip)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar at Bottom
            HStack(spacing: 0) {
                TabBarButton(
                    icon: "list.bullet.clipboard",
                    title: "Overview",
                    isSelected: selectedTab == 0
                ) {
                    selectedTab = 0
                }
                
                TabBarButton(
                    icon: "star.fill",
                    title: "Activities",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
                
                TabBarButton(
                    icon: "calendar",
                    title: "Schedule",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
                
                TabBarButton(
                    icon: "map",
                    title: "Route",
                    isSelected: selectedTab == 3
                ) {
                    selectedTab = 3
                }
                
                TabBarButton(
                    icon: "location.fill",
                    title: "Map",
                    isSelected: selectedTab == 4
                ) {
                    selectedTab = 4
                }
            }
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundStyle(Color.gray.opacity(0.3)),
                alignment: .top
            )
        }
        .background(Color(.systemBackground))
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingOfflineMapSheet = true
                } label: {
                    Label("Offline Maps", systemImage: "arrow.down.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTripView(trip: trip)
        }
        .sheet(isPresented: $showingOfflineMapSheet) {
            OfflineMapDownloadSheet(trip: trip)
        }
        .onAppear {
            prefetchRoutes()
        }
    }
    
    private func prefetchRoutes() {
        guard !isPrefetchingRoutes else { return }
        isPrefetchingRoutes = true
        
        Task {
            // Collect all route pairs from the trip
            var routes: [(from: String, to: String)] = []
            
            for day in trip.days {
                // Add day route
                routes.append((from: day.startLocation, to: day.endLocation))
                
                // Add activity-to-activity routes for completed activities
                let completedActivities = day.activities.filter { $0.isCompleted }.sorted { a, b in
                    guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                        return a.scheduledTime != nil
                    }
                    return timeA < timeB
                }
                
                // Only create routes if we have at least 2 completed activities
                guard completedActivities.count > 1 else { continue }
                
                for i in 0..<(completedActivities.count - 1) {
                    routes.append((
                        from: completedActivities[i].location,
                        to: completedActivities[i + 1].location
                    ))
                }
            }
            
            // Pre-fetch all routes in parallel (this will cache them)
            _ = await RouteCalculator.shared.calculateMultipleRoutes(routes: routes)
            
            await MainActor.run {
                isPrefetchingRoutes = false
            }
        }
    }
}

// Custom Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .blue : .secondary)
                
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .blue : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
