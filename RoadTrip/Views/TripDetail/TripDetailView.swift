// Views/TripDetail/TripDetailView.swift
//  Created by Jake Frischmann on 1/1/26.

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @State private var selectedTab = 0
    @State private var showingEditSheet = false
    @State private var showingOfflineMapSheet = false
    @State private var showingShareSheet = false
    @State private var showingMoreOptions = false
    @State private var showingCarRentalBrowser = false
    @State private var isPrefetchingRoutes = false
    @State private var pdfData: Data?
    @State private var notificationsEnabled = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Content
            TabView(selection: $selectedTab) {
                OverviewView(trip: trip)
                    .tag(0)
                
                BudgetView(trip: trip)
                    .tag(1)
                
                ActivitiesView(trip: trip)
                    .tag(2)
                
                ScheduleView(trip: trip)
                    .tag(3)
                
                TripMapView(trip: trip)
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(Color(red: 0.98, green: 0.97, blue: 0.96))
            
            // Custom Tab Bar at Bottom
            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.2))
                
                HStack(spacing: 0) {
                    TabBarButton(
                        icon: "list.bullet.clipboard",
                        title: "Overview",
                        isSelected: selectedTab == 0
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 0
                        }
                    }
                    
                    TabBarButton(
                        icon: "dollarsign.circle.fill",
                        title: "Budget",
                        isSelected: selectedTab == 1
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 1
                        }
                    }
                    
                    TabBarButton(
                        icon: "star.fill",
                        title: "Activities",
                        isSelected: selectedTab == 2
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 2
                        }
                    }
                    
                    TabBarButton(
                        icon: "calendar",
                        title: "Schedule",
                        isSelected: selectedTab == 3
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 3
                        }
                    }
                    
                    TabBarButton(
                        icon: "map.fill",
                        title: "Map",
                        isSelected: selectedTab == 4
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 4
                        }
                    }
                }
                .padding(.vertical, 12)
                .background(Color.white)
            }
        }
        .background(Color(red: 0.98, green: 0.97, blue: 0.96))
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
                    
                    Divider()
                    
                    Button {
                        exportToPDF()
                    } label: {
                        Label("Export to PDF", systemImage: "doc.fill")
                    }
                    
                    Button {
                        toggleNotifications()
                    } label: {
                        Label(notificationsEnabled ? "Disable Notifications" : "Enable Notifications", 
                              systemImage: notificationsEnabled ? "bell.slash.fill" : "bell.fill")
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
        .sheet(isPresented: $showingCarRentalBrowser) {
            CarRentalBrowsingView(trip: trip)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = pdfData {
                ShareSheet(items: [pdfData], fileName: "\(trip.name).pdf")
            }
        }
        .onAppear {
            prefetchRoutes()
        }
    }
    
    private func exportToPDF() {
        if let data = PDFExportService.shared.generateTripPDF(trip: trip) {
            pdfData = data
            showingShareSheet = true
        }
    }
    
    private func toggleNotifications() {
        Task {
            if notificationsEnabled {
                NotificationService.shared.cancelAllNotifications(for: trip)
                await MainActor.run {
                    notificationsEnabled = false
                }
            } else {
                await NotificationService.shared.scheduleAllNotifications(for: trip)
                await MainActor.run {
                    notificationsEnabled = true
                }
            }
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
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isSelected
                            ? Color(red: 0.29, green: 0.62, blue: 0.85)
                            : Color.gray.opacity(0.5)
                    )
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(
                        isSelected
                            ? Color(red: 0.29, green: 0.62, blue: 0.85)
                            : Color.gray.opacity(0.5)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                isSelected
                    ? Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.08)
                    : Color.clear
            )
            .cornerRadius(8)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }
}
