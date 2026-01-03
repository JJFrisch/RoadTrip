//
//  ScheduleView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/1/26.
//

// Views/TripDetail/ScheduleView.swift
import SwiftUI
import MapKit
import CoreLocation

struct ScheduleView: View {
    let trip: Trip
    @State private var selectedDay: TripDay?
    @State private var isRefreshing = false
    @State private var dayToCopy: TripDay?
    @State private var showingCopyOptions = false
    
    var body: some View {
        List {
            ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                DayScheduleSection(day: day)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDay = day
                    }
                    // MARK: - Day Swipe Actions
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            dayToCopy = day
                            showingCopyOptions = true
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            duplicateDay(day)
                        } label: {
                            Label("Duplicate", systemImage: "plus.square.on.square")
                        }
                        .tint(.green)
                    }
            }
        }
        .listStyle(.plain)
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await refreshDrivingTimes()
        }
        .sheet(item: $selectedDay) { day in
            DayDetailScheduleView(day: day)
        }
        .confirmationDialog("Copy Day Activities", isPresented: $showingCopyOptions, presenting: dayToCopy) { day in
            ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { targetDay in
                if targetDay.id != day.id {
                    Button("Copy to Day \(targetDay.dayNumber)") {
                        copyActivities(from: day, to: targetDay)
                    }
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: { day in
            Text("Copy activities from Day \(day.dayNumber) to another day")
        }
    }
    
    private func duplicateDay(_ day: TripDay) {
        // Create a copy of all activities and add to the same day
        for activity in day.activities {
            let copy = Activity(name: "\(activity.name) (Copy)", location: activity.location, category: activity.category)
            copy.duration = activity.duration
            copy.notes = activity.notes
            copy.scheduledTime = activity.scheduledTime
            copy.isCompleted = false
            copy.order = day.activities.count
            copy.estimatedCost = activity.estimatedCost
            copy.costCategory = activity.costCategory
            day.activities.append(copy)
        }
    }
    
    private func copyActivities(from sourceDay: TripDay, to targetDay: TripDay) {
        let startOrder = targetDay.activities.count
        for (index, activity) in sourceDay.activities.enumerated() {
            let copy = Activity(name: activity.name, location: activity.location, category: activity.category)
            copy.duration = activity.duration
            copy.notes = activity.notes
            // Adjust time to target day
            if let sourceTime = activity.scheduledTime {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: sourceTime)
                copy.scheduledTime = calendar.date(bySettingHour: components.hour ?? 9, minute: components.minute ?? 0, second: 0, of: targetDay.date)
            }
            copy.isCompleted = false
            copy.order = startOrder + index
            copy.estimatedCost = activity.estimatedCost
            copy.costCategory = activity.costCategory
            targetDay.activities.append(copy)
        }
    }
    
    @MainActor
    private func refreshDrivingTimes() async {
        isRefreshing = true
        
        // Recalculate driving times for all days
        let sortedDays = trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })
        
        for day in sortedDays {
            guard !day.startLocation.isEmpty && !day.endLocation.isEmpty else { continue }
            
            // Calculate route
            await calculateRoute(for: day)
        }
        
        isRefreshing = false
    }
    
    @MainActor
    private func calculateRoute(for day: TripDay) async {
        let request = MKDirections.Request()
        
        // Geocode start and end locations
        let geocoder = CLGeocoder()
        
        do {
            let startPlacemarks = try await geocoder.geocodeAddressString(day.startLocation)
            let endPlacemarks = try await geocoder.geocodeAddressString(day.endLocation)
            
            guard let startLocation = startPlacemarks.first?.location,
                  let endLocation = endPlacemarks.first?.location else { return }
            
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: startLocation.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: endLocation.coordinate))
            request.transportType = .automobile
            
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            
            if let route = response.routes.first {
                day.distance = route.distance / 1609.34 // Convert to miles
                day.drivingTime = route.expectedTravelTime / 3600 // Convert to hours
            }
        } catch {
            print("Route calculation failed: \(error)")
        }
    }
}

struct DayScheduleSection: View {
    let day: TripDay
    @Environment(\.colorScheme) private var colorScheme
    
    var completedActivities: [Activity] {
        day.activities.filter { $0.isCompleted }.sorted { a, b in
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                return a.scheduledTime != nil
            }
            return timeA < timeB
        }
    }
    
    // Dark mode adaptive gradient colors
    private var gradientColors: [Color] {
        colorScheme == .dark 
            ? [Color.blue.opacity(0.4), Color.purple.opacity(0.3)]
            : [Color.blue.opacity(0.6), Color.purple.opacity(0.4)]
    }
    
    private func formatDrivingTime(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        } else {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            if m == 0 {
                return "\(h) hr"
            } else {
                return "\(h) hr \(m) min"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day Header with gradient
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Day \(day.dayNumber)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            
                            Text(day.date.formatted(date: .complete, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        if !completedActivities.isEmpty {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(completedActivities.count)")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                Text(completedActivities.count == 1 ? "activity" : "activities")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        }
                    }
                    
                    // Route info: start → end with distance and time
                    if !day.startLocation.isEmpty && !day.endLocation.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "car.fill")
                                .font(.caption)
                            Text("\(day.startLocation) → \(day.endLocation)")
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                        
                        HStack(spacing: 12) {
                            if day.distance > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "road.lanes")
                                        .font(.caption)
                                    Text(String(format: "%.0f mi", day.distance))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            if day.drivingTime > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock.fill")
                                        .font(.caption)
                                    Text(formatDrivingTime(day.drivingTime))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .foregroundStyle(.white)
                    }
                    
                    if let firstTime = completedActivities.first?.scheduledTime,
                       let lastTime = completedActivities.last?.scheduledTime,
                       let lastDuration = completedActivities.last?.duration {
                        let endTime = Calendar.current.date(byAdding: .minute, value: Int(lastDuration * 60), to: lastTime)!
                        
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption)
                            Text("Activities: \(firstTime.formatted(date: .omitted, time: .shortened)) - \(endTime.formatted(date: .omitted, time: .shortened))")
                                .font(.caption)
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding()
            }
            .frame(minHeight: 120)
            
            // Timeline View
            if completedActivities.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No scheduled activities")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Tap on activities and set times to see them here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                CalendarTimelineView(activities: completedActivities)
                    .padding(.vertical, 16)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

struct CalendarTimelineView: View {
    let activities: [Activity]
    
    private let hourHeight: CGFloat = 80
    private let timeColumnWidth: CGFloat = 60
    
    // Dynamically calculate time range based on current activities
    private var timeRange: (start: Int, end: Int) {
        // Filter activities with valid scheduled times
        let scheduledActivities = activities.filter { activity in
            guard let time = activity.scheduledTime,
                  let duration = activity.duration,
                  !duration.isNaN && !duration.isInfinite && duration >= 0 else {
                return false
            }
            return true
        }
        
        guard !scheduledActivities.isEmpty else {
            return (8, 20) // Default 8 AM to 8 PM
        }
        
        let calendar = Calendar.current
        
        // Find earliest and latest times from all activities
        var earliestHour = 23
        var latestEndHour = 0
        
        for activity in scheduledActivities {
            guard let time = activity.scheduledTime,
                  let duration = activity.duration else { continue }
            
            let startHour = calendar.component(.hour, from: time)
            let startMinute = calendar.component(.minute, from: time)
            
            // Calculate end hour considering duration
            let endHour = startHour + Int(ceil(duration + Double(startMinute) / 60.0))
            
            earliestHour = min(earliestHour, startHour)
            latestEndHour = max(latestEndHour, endHour)
        }
        
        // Add padding and validate
        let startHour = max(0, earliestHour - 1)
        let finalEndHour = min(24, max(startHour + 2, latestEndHour + 1))
        
        return (startHour, finalEndHour)
    }
    
    var body: some View {
        ScrollView {
            ZStack(alignment: .topLeading) {
                // Hour grid background
                VStack(spacing: 0) {
                    ForEach(timeRange.start..<timeRange.end, id: \.self) { hour in
                        HStack(spacing: 0) {
                            // Time label
                            Text(formatHour(hour))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: timeColumnWidth, alignment: .trailing)
                                .padding(.trailing, 8)
                            
                            // Hour line
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 1)
                        }
                        .frame(height: hourHeight)
                    }
                }
                .padding(.leading, 8)
                
                // Activity blocks
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(activities) { activity in
                        if let startTime = activity.scheduledTime,
                           let duration = activity.duration {
                            ActivityBlock(activity: activity, startTime: startTime, duration: duration)
                                .offset(y: calculateOffset(for: startTime))
                                .padding(.leading, timeColumnWidth + 16)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        return formatter.string(from: date)
    }
    
    private func calculateOffset(for time: Date) -> CGFloat {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        let hoursFromStart = Double(hour - timeRange.start)
        let minuteFraction = Double(minute) / 60.0
        let totalHours = hoursFromStart + minuteFraction
        
        // Ensure we don't return NaN or negative values
        guard !totalHours.isNaN && !totalHours.isInfinite && totalHours >= 0 else {
            return 0
        }
        
        return CGFloat(totalHours) * hourHeight
    }
}

struct ActivityBlock: View {
    let activity: Activity
    let startTime: Date
    let duration: Double
    
    private let hourHeight: CGFloat = 80
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(categoryColor)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(categoryColor)
                    
                    Spacer()
                    
                    Text(activity.category)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.15))
                        .cornerRadius(4)
                }
                
                Text(activity.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(activity.location, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Label("\(formatDuration(duration))", systemImage: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .frame(height: max(40, CGFloat(duration.isNaN || duration.isInfinite || duration < 0 ? 1.0 : duration) * hourHeight))
        .background(categoryColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(categoryColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: categoryColor.opacity(0.2), radius: 4, y: 2)
    }
    
    private var categoryColor: Color {
        switch activity.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            if m == 0 {
                return "\(h)h"
            } else {
                return "\(h)h \(m)m"
            }
        }
    }
}

struct TimelineItemView: View {
    let activity: Activity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time column
            VStack(spacing: 2) {
                if let time = activity.scheduledTime {
                    Text(time.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .fontWeight(.semibold)
                } else {
                    Text("--:--")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 50, alignment: .trailing)
            .foregroundStyle(.secondary)
            
            // Timeline dot and line
            VStack(alignment: .center, spacing: 0) {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 14, height: 14)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    }
            }
            
            // Activity details
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(activity.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(activity.category)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(categoryColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(categoryColor.opacity(0.1))
                        .cornerRadius(4)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(categoryColor.opacity(0.6))
                    
                    Text(activity.location)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let duration = activity.duration {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange.opacity(0.6))
                        
                        Text("\(Int(duration * 60)) minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var categoryColor: Color {
        switch activity.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
}
