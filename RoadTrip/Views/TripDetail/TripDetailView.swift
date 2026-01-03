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
            // Custom Tab Picker
            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Activities").tag(1)
                Text("Schedule").tag(2)
                Text("Route").tag(3)
                Text("Map").tag(4)
            }
            .pickerStyle(.segmented)
            .padding()
            
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
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Trip", systemImage: "pencil")
                    }
                    
                    Button {
                        showingOfflineMapSheet = true
                    } label: {
                        Label("Offline Maps", systemImage: "arrow.down.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
