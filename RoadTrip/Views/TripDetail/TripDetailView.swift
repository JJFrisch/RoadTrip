// Views/TripDetail/TripDetailView.swift
//  Created by Jake Frischmann on 1/1/26.

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @Environment(\.colorScheme) private var colorScheme
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
            .background(AppTheme.Colors.background)
            
            // Custom Tab Bar at Bottom
            VStack(spacing: 0) {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(AppTheme.Colors.divider)
                
                HStack(spacing: 0) {
                    TabBarButton(
                        icon: "list.bullet.clipboard",
                        title: "Overview",
                        isSelected: selectedTab == 0,
                        accessibilityID: "tripDetail.tab.overview"
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 0
                        }
                    }
                    
                    TabBarButton(
                        icon: "dollarsign.circle.fill",
                        title: "Budget",
                        isSelected: selectedTab == 1,
                        accessibilityID: "tripDetail.tab.budget"
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 1
                        }
                    }
                    
                    TabBarButton(
                        icon: "star.fill",
                        title: "Activities",
                        isSelected: selectedTab == 2,
                        accessibilityID: "tripDetail.tab.activities"
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 2
                        }
                    }
                    
                    TabBarButton(
                        icon: "calendar",
                        title: "Schedule",
                        isSelected: selectedTab == 3,
                        accessibilityID: "tripDetail.tab.schedule"
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 3
                        }
                    }
                    
                    TabBarButton(
                        icon: "map.fill",
                        title: "Map",
                        isSelected: selectedTab == 4,
                        accessibilityID: "tripDetail.tab.map"
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTab = 4
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .padding(.horizontal, AppTheme.Spacing.xs)
                .background(AppTheme.Colors.secondaryBackground)
            }
        }
        .background(AppTheme.Colors.background)
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

                    Button {
                        showingCarRentalBrowser = true
                    } label: {
                        Label("Browse Car Rentals", systemImage: "car.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundStyle(AppTheme.Colors.primary)
                }
                .accessibilityLabel("Trip actions")
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
    let accessibilityID: String
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isSelected
                            ? AppTheme.Colors.primary
                            : AppTheme.Colors.secondaryText.color(for: colorScheme).opacity(0.7)
                    )
                
                Text(title)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(
                        isSelected
                            ? AppTheme.Colors.primary
                            : AppTheme.Colors.secondaryText.color(for: colorScheme).opacity(0.7)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                isSelected
                    ? AppTheme.Colors.primary.opacity(0.1)
                    : Color.clear
            )
            .cornerRadius(AppTheme.CornerRadius.medium)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: AppTheme.Animation.fast)) {
                    isHovered = hovering
                }
            }
            .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .accessibilityIdentifier(accessibilityID)
    }
}
