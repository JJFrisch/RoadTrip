// Views/TripDetail/DayDetailScheduleView.swift
import SwiftUI
import MapKit

struct DayDetailScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    let day: TripDay
    
    @State private var showDistances = false
    @State private var transportMode: TransportMode = .driving
    @State private var activityDistances: [UUID: Double] = [:] // in miles
    @State private var isCalculatingDistances = false
    @State private var showingImportActivity = false
    @State private var showingAddActivity = false
    
    enum TransportMode: String, CaseIterable {
        case walking = "Walking"
        case driving = "Driving"
        
        var icon: String {
            switch self {
            case .walking: return "figure.walk"
            case .driving: return "car.fill"
            }
        }
    }
    
    var completedActivities: [Activity] {
        (day.activities?.filter { $0.isCompleted }.sorted { a, b in
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                return a.scheduledTime != nil
            }
            return timeA < timeB
        }) ?? []
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                return a.scheduledTime != nil
            }
            return timeA < timeB
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Day \(day.dayNumber)")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(day.date.formatted(date: .long, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Label("From", systemImage: "location.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(day.startLocation)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Label("To", systemImage: "mappin.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(day.endLocation)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                    
                    // Distance Toggle
                    VStack(spacing: 12) {
                        Toggle(isOn: $showDistances) {
                            Label("Show Distances Between Sites", systemImage: "map")
                        }
                        .onChange(of: showDistances) { _, newValue in
                            if newValue && activityDistances.isEmpty {
                                calculateDistances()
                            }
                        }
                        
                        if showDistances {
                            Picker("Transport Mode", selection: $transportMode) {
                                ForEach(TransportMode.allCases, id: \.self) { mode in
                                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: transportMode) { _, _ in
                                calculateDistances()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Hour-by-Hour Timeline
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Schedule")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        
                        if completedActivities.isEmpty {
                            Text("No scheduled activities")
                                .foregroundStyle(.secondary)
                                .italic()
                                .padding()
                                .frame(maxWidth: .infinity)
                        } else {
                            ForEach(Array(completedActivities.enumerated()), id: \.element.id) { index, activity in
                                VStack(spacing: 0) {
                                    DetailedTimelineItem(
                                        activity: activity,
                                        day: day,
                                        showDistance: showDistances,
                                        distance: activityDistances[activity.id],
                                        transportMode: transportMode
                                    )
                                    
                                    // Show distance to next activity
                                    if showDistances && index < completedActivities.count - 1 {
                                        if isCalculatingDistances {
                                            HStack {
                                                Spacer()
                                                ProgressView()
                                                    .padding(.vertical, 8)
                                                Spacer()
                                            }
                                        } else if let distance = activityDistances[activity.id] {
                                            HStack {
                                                Spacer()
                                                Image(systemName: "arrow.down")
                                                    .foregroundStyle(.secondary)
                                                Text(String(format: "%.1f mi", distance))
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                                Image(systemName: transportMode.icon)
                                                    .foregroundStyle(.secondary)
                                                Spacer()
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showingAddActivity = true
                        } label: {
                            Label("New Activity", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showingImportActivity = true
                        } label: {
                            Label("Import Activity", systemImage: "arrow.down.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImportActivity) {
                ActivityImportSheet(day: day)
            }
            .sheet(isPresented: $showingAddActivity) {
                AddActivityFromScheduleView(day: day)
            }
        }
    }
    
    private func calculateDistances() {
        guard showDistances else { return }
        
        isCalculatingDistances = true
        activityDistances = [:]
        
        Task {
            var distances: [UUID: Double] = [:]
            let transportType: MKDirectionsTransportType = self.transportMode == .driving ? .automobile : .walking
            
            // Build route pairs
            var routes: [(from: String, to: String, activityId: UUID)] = []
            for (index, activity) in completedActivities.enumerated() {
                guard index < completedActivities.count - 1 else { break }
                let nextActivity = completedActivities[index + 1]
                routes.append((from: activity.location, to: nextActivity.location, activityId: activity.id))
            }
            
            // Calculate all routes in parallel using RouteCalculator
            for route in routes {
                if let routeInfo = try? await RouteCalculator.shared.calculateRoute(
                    from: route.from,
                    to: route.to,
                    transportType: transportType
                ) {
                    distances[route.activityId] = routeInfo.distanceInMiles
                }
            }
            
            await MainActor.run {
                activityDistances = distances
                isCalculatingDistances = false
            }
        }
    }
}

struct DetailedTimelineItem: View {
    let activity: Activity
    let day: TripDay
    let showDistance: Bool
    let distance: Double?
    let transportMode: DayDetailScheduleView.TransportMode
    
    var categoryColor: Color {
        switch activity.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Time Badge
                if let time = activity.scheduledTime {
                    VStack(spacing: 2) {
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor)
                            .cornerRadius(6)
                        
                        if let duration = activity.duration {
                            Text("\(Int(duration * 60))m")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Text("No Time")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                    }
                }
                
                // Activity Details
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(activity.name)
                            .font(.headline)
                        
                        Spacer()
                        
                        Image(systemName: categoryIcon)
                            .foregroundStyle(categoryColor)
                    }
                    
                    Label(activity.location, systemImage: "mappin.circle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let notes = activity.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
    }
    
    var categoryIcon: String {
        switch activity.category {
        case "Food": return "fork.knife"
        case "Attraction": return "star.fill"
        case "Hotel": return "bed.double.fill"
        default: return "mappin"
        }
    }
}
