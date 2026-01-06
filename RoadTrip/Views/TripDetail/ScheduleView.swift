//
//  ScheduleView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/1/26.
//

// Views/TripDetail/ScheduleView.swift
import SwiftUI
import SwiftData
import MapKit
import CoreLocation

// Extension to make Date Identifiable for sheet presentation
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}

struct ScheduleView: View {
    let trip: Trip
    @State private var selectedDay: TripDay?
    @State private var isRefreshing = false
    @State private var dayToCopy: TripDay?
    @State private var showingCopyOptions = false
    @State private var collapsedDayIDs: Set<UUID> = []
    
    var body: some View {
        List {
            ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                DayScheduleSection(
                    day: day,
                    isCollapsed: collapsedDayIDs.contains(day.id),
                    onToggleCollapse: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if collapsedDayIDs.contains(day.id) {
                                collapsedDayIDs.remove(day.id)
                            } else {
                                collapsedDayIDs.insert(day.id)
                            }
                        }
                    },
                    onTapDay: {
                        selectedDay = day
                    }
                )
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
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
    let isCollapsed: Bool
    let onToggleCollapse: () -> Void
    let onTapDay: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAddActivity = false
    @State private var showingTemplates = false
    @StateObject private var undoManager = ActivityUndoManager.shared
    
    var completedActivities: [Activity] {
        day.activities.filter { $0.isCompleted }.sorted { a, b in
            guard let timeA = a.scheduledTime, let timeB = b.scheduledTime else {
                return a.scheduledTime != nil
            }
            return timeA < timeB
        }
    }
    
    // MARK: - Day Summary Stats
    private var totalPlannedTime: Double {
        completedActivities.compactMap { $0.duration }.reduce(0, +)
    }
    
    private var totalEstimatedCost: Double {
        day.activities.compactMap { $0.estimatedCost }.reduce(0, +)
    }
    
    private var freeTimeGaps: [(start: Date, end: Date, duration: TimeInterval)] {
        guard completedActivities.count > 1 else { return [] }
        
        var gaps: [(start: Date, end: Date, duration: TimeInterval)] = []
        let sorted = completedActivities
        
        for i in 0..<(sorted.count - 1) {
            guard let currentTime = sorted[i].scheduledTime,
                  let currentDuration = sorted[i].duration,
                  let nextTime = sorted[i + 1].scheduledTime else { continue }
            
            let currentEnd = currentTime.addingTimeInterval(currentDuration * 3600)
            
            if nextTime > currentEnd {
                let gapDuration = nextTime.timeIntervalSince(currentEnd)
                if gapDuration >= 900 { // Only show gaps of 15+ minutes
                    gaps.append((start: currentEnd, end: nextTime, duration: gapDuration))
                }
            }
        }
        
        return gaps
    }
    
    private var totalFreeTime: TimeInterval {
        freeTimeGaps.map { $0.duration }.reduce(0, +)
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
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
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

                        Button {
                            onToggleCollapse()
                        } label: {
                            Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white.opacity(0.95))
                                .padding(8)
                                .background(.white.opacity(0.18))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        
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

                    // Hotel discovery/browsing is currently disabled (coming soon)
                    
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
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .contentShape(Rectangle())
            .onTapGesture {
                onTapDay()
            }
            
            if !isCollapsed {
                // Timeline View
                if completedActivities.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        
                        Text("No activities in schedule")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Check activities in Activities to show them here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    CalendarTimelineView(activities: completedActivities, day: day)
                        .padding(.vertical, 16)
                }
                
                // Day Summary Stats (shown when there are activities)
                if !completedActivities.isEmpty {
                    DaySummaryStatsView(
                        totalPlannedTime: totalPlannedTime,
                        totalFreeTime: totalFreeTime,
                        totalEstimatedCost: totalEstimatedCost,
                        freeTimeGaps: freeTimeGaps
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            
            // Action Buttons Row
            HStack(spacing: 12) {
                // Add Activity Button
                Button {
                    showingAddActivity = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.body)
                        Text("Add Activity")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                // Kinds of Activities Button
                Button {
                    showingTemplates = true
                } label: {
                    HStack {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.body)
                        Text("Kinds")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                Button {} label: {
                    HStack {
                        Image(systemName: "bed.double.fill")
                            .font(.body)
                        Text("Hotels (Coming soon)")
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(true)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
            
            // Undo/Redo buttons
            if undoManager.canUndo || undoManager.canRedo {
                HStack(spacing: 12) {
                    Button {
                        // Undo action
                        if let snapshot = undoManager.undo(in: day) {
                            applyUndo(snapshot)
                        }
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                            .font(.caption)
                    }
                    .disabled(!undoManager.canUndo)
                    
                    Button {
                        // Redo action
                        if let snapshot = undoManager.redo(in: day) {
                            applyRedo(snapshot)
                        }
                    } label: {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                            .font(.caption)
                    }
                    .disabled(!undoManager.canRedo)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            } else {
                Spacer()
                    .frame(height: 8)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        .sheet(isPresented: $showingAddActivity) {
            AddActivityFromScheduleView(day: day)
        }
        .sheet(isPresented: $showingTemplates) {
            TemplatePickerSheet(day: day)
        }
    }
    
    private func applyUndo(_ snapshot: ActivityUndoManager.ActivitySnapshot) {
        if let activity = day.activities.first(where: { $0.id == snapshot.activityId }) {
            activity.name = snapshot.name
            activity.location = snapshot.location
            activity.scheduledTime = snapshot.scheduledTime
            activity.duration = snapshot.duration
            activity.notes = snapshot.notes
            activity.isCompleted = snapshot.isCompleted
            activity.estimatedCost = snapshot.estimatedCost
            activity.costCategory = snapshot.costCategory
        }
    }
    
    private func applyRedo(_ snapshot: ActivityUndoManager.ActivitySnapshot) {
        applyUndo(snapshot) // Same logic for redo
    }
}

struct CalendarTimelineView: View {
    let activities: [Activity]
    let day: TripDay
    
    @State private var travelTimes: [UUID: TimeInterval] = [:] // Travel time to next activity
    @State private var isCalculatingTravel = false
    @State private var selectedActivityForEdit: Activity?
    @State private var draggedActivity: Activity?
    @State private var showingAddAtTime: Date?
    @State private var zoomScale: CGFloat = 1.0
    
    // Base hour height that can be zoomed
    private var hourHeight: CGFloat { 80 * zoomScale }
    private let timeColumnWidth: CGFloat = 60
    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 2.0
    
    // Check if this day is today
    private var isToday: Bool {
        Calendar.current.isDateInToday(day.date)
    }
    
    // Current time offset for the red line
    private var currentTimeOffset: CGFloat? {
        guard isToday else { return nil }
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        
        // Check if current time is within visible range
        guard hour >= timeRange.start && hour < timeRange.end else { return nil }
        
        let hoursFromStart = Double(hour - timeRange.start)
        let minuteFraction = Double(minute) / 60.0
        return CGFloat(hoursFromStart + minuteFraction) * hourHeight
    }
    
    // Time periods for color coding
    private enum TimePeriod {
        case earlyMorning // 5-8 AM
        case morning      // 8-12 PM
        case afternoon    // 12-5 PM
        case evening      // 5-9 PM
        case night        // 9 PM - 5 AM
        
        var backgroundColor: Color {
            switch self {
            case .earlyMorning: return Color.orange.opacity(0.05)
            case .morning: return Color.yellow.opacity(0.05)
            case .afternoon: return Color.blue.opacity(0.05)
            case .evening: return Color.purple.opacity(0.05)
            case .night: return Color.indigo.opacity(0.08)
            }
        }
        
        static func forHour(_ hour: Int) -> TimePeriod {
            switch hour {
            case 5..<8: return .earlyMorning
            case 8..<12: return .morning
            case 12..<17: return .afternoon
            case 17..<21: return .evening
            default: return .night
            }
        }
    }
    
    // Check for time conflicts
    private func hasConflict(_ activity: Activity) -> Bool {
        guard let time = activity.scheduledTime,
              let duration = activity.duration else { return false }
        
        let endTime = time.addingTimeInterval(duration * 3600)
        
        for other in activities where other.id != activity.id {
            guard let otherTime = other.scheduledTime,
                  let otherDuration = other.duration else { continue }
            
            let otherEndTime = otherTime.addingTimeInterval(otherDuration * 3600)
            
            // Check if they overlap
            if time < otherEndTime && endTime > otherTime {
                return true
            }
        }
        return false
    }
    
    // Find free time slots
    private func findFreeSlots() -> [(start: Date, end: Date)] {
        let calendar = Calendar.current
        let dayStart = calendar.date(bySettingHour: timeRange.start, minute: 0, second: 0, of: day.date)!
        let dayEnd = calendar.date(bySettingHour: timeRange.end, minute: 0, second: 0, of: day.date)!
        
        var slots: [(start: Date, end: Date)] = []
        var currentTime = dayStart
        
        let sortedActivities = activities
            .filter { $0.scheduledTime != nil && $0.duration != nil }
            .sorted { $0.scheduledTime! < $1.scheduledTime! }
        
        for activity in sortedActivities {
            guard let activityStart = activity.scheduledTime,
                  let duration = activity.duration else { continue }
            
            if currentTime < activityStart {
                slots.append((start: currentTime, end: activityStart))
            }
            
            let activityEnd = activityStart.addingTimeInterval(duration * 3600)
            currentTime = max(currentTime, activityEnd)
        }
        
        if currentTime < dayEnd {
            slots.append((start: currentTime, end: dayEnd))
        }
        
        return slots
    }
    
    // Check if a time slot is free
    private func isTimeSlotFree(at time: Date) -> Bool {
        for activity in activities {
            guard let activityTime = activity.scheduledTime,
                  let duration = activity.duration else { continue }
            
            let activityEnd = activityTime.addingTimeInterval(duration * 3600)
            
            if time >= activityTime && time < activityEnd {
                return false
            }
        }
        return true
    }
    
    // Dynamically calculate time range based on current activities
    private var timeRange: (start: Int, end: Int) {
        // Filter activities with valid scheduled times
        let scheduledActivities = activities.filter { activity in
            guard activity.scheduledTime != nil,
                  let duration = activity.duration,
                  !duration.isNaN && !duration.isInfinite && duration >= 0 else {
                return false
            }
            return true
        }
        
        // Only calculate dynamic range if we have activities with times
        guard !scheduledActivities.isEmpty else {
            return (8, 10) // Minimal default range when no times set
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
        VStack(spacing: 0) {
            // Zoom controls
            HStack {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        zoomScale = max(minZoom, zoomScale - 0.25)
                    }
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                        .font(.caption)
                        .padding(6)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
                .disabled(zoomScale <= minZoom)
                
                Text("\(Int(zoomScale * 100))%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 40)
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        zoomScale = min(maxZoom, zoomScale + 0.25)
                    }
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.caption)
                        .padding(6)
                        .background(Color(.systemGray5))
                        .cornerRadius(6)
                }
                .disabled(zoomScale >= maxZoom)
                
                Spacer()
                
                if isToday {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 6, height: 6)
                        Text("Now")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
            
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Hour grid background with time period colors and tappable slots
                    VStack(spacing: 0) {
                        ForEach(timeRange.start..<timeRange.end, id: \.self) { hour in
                            ZStack(alignment: .leading) {
                                // Time period background color
                                TimePeriod.forHour(hour).backgroundColor
                                
                                HStack(spacing: 0) {
                                    // Time label
                                    Text(formatHour(hour))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: timeColumnWidth, alignment: .trailing)
                                        .padding(.trailing, 8)
                                    
                                    // Tappable hour slot
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            let calendar = Calendar.current
                                            if let tappedTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day.date),
                                               isTimeSlotFree(at: tappedTime) {
                                                showingAddAtTime = tappedTime
                                            }
                                        }
                                    
                                    // Hour line overlay
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 1)
                                        .allowsHitTesting(false)
                                }
                            }
                            .frame(height: hourHeight)
                        }
                    }
                    .padding(.leading, 8)
                    
                    // Current time indicator (red line)
                    if let offset = currentTimeOffset {
                        HStack(spacing: 0) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                            
                            Rectangle()
                                .fill(Color.red)
                                .frame(height: 2)
                        }
                        .offset(x: timeColumnWidth + 8, y: offset - 5)
                        .allowsHitTesting(false)
                    }
                    
                    // Activity blocks with drag reordering
                    ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                        if let startTime = activity.scheduledTime,
                           let duration = activity.duration {
                            VStack(spacing: 0) {
                                EnhancedActivityBlock(
                                    activity: activity,
                                    startTime: startTime,
                                    duration: duration,
                                    hasConflict: hasConflict(activity),
                                    travelTimeToNext: travelTimes[activity.id],
                                    hourHeight: hourHeight,
                                    onQuickEdit: {
                                        selectedActivityForEdit = activity
                                    }
                                )
                                .draggable(activity.id.uuidString) {
                                    // Drag preview
                                    Text(activity.name)
                                        .padding(8)
                                        .background(categoryColor(for: activity).opacity(0.8))
                                        .foregroundStyle(.white)
                                        .cornerRadius(8)
                                }
                                .dropDestination(for: String.self) { items, _ in
                                    guard let droppedIdString = items.first,
                                          let droppedId = UUID(uuidString: droppedIdString),
                                          let droppedActivity = activities.first(where: { $0.id == droppedId }),
                                          droppedActivity.id != activity.id else {
                                        return false
                                    }
                                    
                                    // Swap scheduled times
                                    let targetTime = activity.scheduledTime
                                    activity.scheduledTime = droppedActivity.scheduledTime
                                    droppedActivity.scheduledTime = targetTime
                                    return true
                                }
                                
                                // Travel time indicator
                                if index < activities.count - 1, let travelTime = travelTimes[activity.id] {
                                    TravelTimeIndicator(travelTime: travelTime)
                                }
                            }
                            .offset(y: calculateOffset(for: startTime))
                            .padding(.leading, timeColumnWidth + 16)
                        }
                    }
                }
                .padding()
            }
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let newScale = zoomScale * value
                        zoomScale = min(maxZoom, max(minZoom, newScale))
                    }
            )
        }
        .onAppear {
            calculateTravelTimes()
        }
        .sheet(item: $selectedActivityForEdit) { activity in
            QuickTimeEditSheet(activity: activity, day: day)
        }
        .sheet(item: $showingAddAtTime) { time in
            AddActivityAtTimeSheet(day: day, suggestedTime: time)
        }
    }
    
    private func calculateTravelTimes() {
        guard activities.count > 1 else { return }
        isCalculatingTravel = true
        
        Task {
            var times: [UUID: TimeInterval] = [:]
            
            for i in 0..<(activities.count - 1) {
                let current = activities[i]
                let next = activities[i + 1]
                
                if let routeInfo = try? await RouteCalculator.shared.calculateRoute(
                    from: current.location,
                    to: next.location,
                    transportType: .automobile
                ) {
                    times[current.id] = routeInfo.estimatedTime
                }
            }
            
            await MainActor.run {
                travelTimes = times
                isCalculatingTravel = false
            }
        }
    }
    
    private func categoryColor(for activity: Activity) -> Color {
        switch activity.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
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

// MARK: - Enhanced Activity Block with Conflict Detection
struct EnhancedActivityBlock: View {
    let activity: Activity
    let startTime: Date
    let duration: Double
    let hasConflict: Bool
    let travelTimeToNext: TimeInterval?
    let hourHeight: CGFloat
    let onQuickEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator - red if conflict
            RoundedRectangle(cornerRadius: 4)
                .fill(hasConflict ? Color.red : categoryColor)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(startTime.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(hasConflict ? .red : categoryColor)
                    
                    if hasConflict {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    Spacer()
                    
                    // Quick edit button
                    Button {
                        onQuickEdit()
                    } label: {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    Text(activity.category)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(hasConflict ? .red : categoryColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background((hasConflict ? Color.red : categoryColor).opacity(0.15))
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
        .background(hasConflict ? Color.red.opacity(0.1) : categoryColor.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(hasConflict ? Color.red.opacity(0.5) : categoryColor.opacity(0.3), lineWidth: hasConflict ? 2 : 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: (hasConflict ? Color.red : categoryColor).opacity(0.2), radius: 4, y: 2)
        .contentShape(Rectangle())
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

// MARK: - Travel Time Indicator
struct TravelTimeIndicator: View {
    let travelTime: TimeInterval
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "car.fill")
                .font(.caption2)
            Text(formatTravelTime(travelTime))
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.vertical, 4)
    }
    
    private func formatTravelTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 60 {
            return "\(minutes) min drive"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hr drive"
            } else {
                return "\(hours) hr \(remainingMinutes) min drive"
            }
        }
    }
}

// MARK: - Quick Time Edit Sheet
struct QuickTimeEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let activity: Activity
    let day: TripDay
    
    @State private var selectedTime: Date
    @State private var selectedDuration: Double
    
    init(activity: Activity, day: TripDay) {
        self.activity = activity
        self.day = day
        _selectedTime = State(initialValue: activity.scheduledTime ?? Date())
        _selectedDuration = State(initialValue: activity.duration ?? 1.0)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity") {
                    HStack {
                        Text(activity.name)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(activity.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(categoryColor.opacity(0.15))
                            .foregroundStyle(categoryColor)
                            .cornerRadius(6)
                    }
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formatDuration(selectedDuration))
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $selectedDuration, in: 0.25...4, step: 0.25)
                        
                        // Quick duration buttons
                        HStack(spacing: 8) {
                            ForEach([15, 30, 60, 90, 120], id: \.self) { minutes in
                                Button {
                                    selectedDuration = Double(minutes) / 60.0
                                } label: {
                                    Text(minutes < 60 ? "\(minutes)m" : "\(minutes/60)h")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Int(selectedDuration * 60) == minutes ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundStyle(Int(selectedDuration * 60) == minutes ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section {
                    // Calculate end time
                    let endTime = Calendar.current.date(byAdding: .minute, value: Int(selectedDuration * 60), to: selectedTime) ?? selectedTime
                    HStack {
                        Text("Ends at")
                        Spacer()
                        Text(endTime.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Quick Edit Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
    
    private func saveChanges() {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
        activity.scheduledTime = calendar.date(bySettingHour: timeComponents.hour ?? 9,
                                                minute: timeComponents.minute ?? 0,
                                                second: 0,
                                                of: day.date)
        activity.duration = selectedDuration
        dismiss()
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

// MARK: - Add Activity From Schedule View
struct AddActivityFromScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    let day: TripDay
    
    @State private var activityName = ""
    @State private var location = ""
    @State private var category = "Attraction"
    @State private var includeTime = true
    @State private var scheduledTime: Date
    @State private var duration: Double = 1.0
    @State private var notes = ""
    
    @State private var searchNearLocation = ""
    @State private var useSearchNear = false
    
    let categories = ["Food", "Attraction", "Hotel", "Other"]
    
    // Smart time suggestion
    private var suggestedTime: Date {
        let calendar = Calendar.current
        
        // Get all scheduled activities sorted by time
        let scheduledActivities = day.activities
            .filter { $0.isCompleted && $0.scheduledTime != nil && $0.duration != nil }
            .sorted { $0.scheduledTime! < $1.scheduledTime! }
        
        if let lastActivity = scheduledActivities.last,
           let lastTime = lastActivity.scheduledTime,
           let lastDuration = lastActivity.duration {
            // Suggest 15 minutes after the last activity ends
            return lastTime.addingTimeInterval((lastDuration + 0.25) * 3600)
        }
        
        // Default to 9 AM if no activities
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day.date) ?? Date()
    }
    
    init(day: TripDay) {
        self.day = day
        
        // Calculate suggested time
        let calendar = Calendar.current
        let scheduledActivities = day.activities
            .filter { $0.isCompleted && $0.scheduledTime != nil && $0.duration != nil }
            .sorted { $0.scheduledTime! < $1.scheduledTime! }
        
        if let lastActivity = scheduledActivities.last,
           let lastTime = lastActivity.scheduledTime,
           let lastDuration = lastActivity.duration {
            _scheduledTime = State(initialValue: lastTime.addingTimeInterval((lastDuration + 0.25) * 3600))
        } else {
            _scheduledTime = State(initialValue: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day.date) ?? Date())
        }
    }

    
    var isFormValid: Bool {
        !activityName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Search Near Location") {
                    Toggle("Search near specific location", isOn: $useSearchNear)
                    
                    if useSearchNear {
                        LocationSearchField(
                            title: "Search Near",
                            location: $searchNearLocation,
                            icon: "location.magnifyingglass",
                            iconColor: .orange,
                            placeholder: "Enter city or address"
                        )
                    } else {
                        HStack {
                            Image(systemName: "location.circle")
                                .foregroundStyle(.secondary)
                            Text("Searching near: \(day.startLocation.isEmpty ? "No location set" : day.startLocation)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Activity Details") {
                    TextField("Activity Name", text: $activityName)
                    
                    LocationSearchField(
                        title: "Location",
                        location: $location,
                        icon: "mappin.circle.fill",
                        iconColor: .blue,
                        searchRegionAddress: useSearchNear ? searchNearLocation : day.startLocation
                    )
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("Schedule") {
                    Toggle("Set Time", isOn: $includeTime)
                    
                    if includeTime {
                        DatePicker("Start Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Duration")
                                Spacer()
                                Text(formatDuration(duration))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Slider(value: $duration, in: 0.0833...8, step: 0.0833)
                            
                            // Quick duration buttons
                            HStack(spacing: 8) {
                                ForEach([15, 30, 60, 90, 120], id: \.self) { minutes in
                                    Button {
                                        duration = Double(minutes) / 60.0
                                    } label: {
                                        Text(minutes < 60 ? "\(minutes)m" : "\(minutes/60)h")
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Int(duration * 60) == minutes ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundStyle(Int(duration * 60) == minutes ? .white : .primary)
                                            .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 60)
                }
            }
            .navigationTitle("Add Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addActivity()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func formatDuration(_ hours: Double) -> String {
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
    
    private func addActivity() {
        let newActivity = Activity(
            name: activityName.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            category: category
        )
        
        newActivity.order = day.activities.count
        newActivity.isCompleted = true
        newActivity.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        
        if includeTime {
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
            newActivity.scheduledTime = calendar.date(bySettingHour: timeComponents.hour ?? 9,
                                                       minute: timeComponents.minute ?? 0,
                                                       second: 0,
                                                       of: day.date)
            newActivity.duration = duration
        }
        
        day.activities.append(newActivity)
        dismiss()
    }
}

// MARK: - Day Summary Stats View
struct DaySummaryStatsView: View {
    let totalPlannedTime: Double
    let totalFreeTime: TimeInterval
    let totalEstimatedCost: Double
    let freeTimeGaps: [(start: Date, end: Date, duration: TimeInterval)]
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Total Planned Time
                StatBadge(
                    icon: "clock.fill",
                    value: formatHours(totalPlannedTime),
                    label: "Planned",
                    color: .blue
                )
                
                // Free Time
                StatBadge(
                    icon: "clock.badge.checkmark.fill",
                    value: formatTimeInterval(totalFreeTime),
                    label: "Free",
                    color: .green
                )
                
                // Estimated Cost
                if totalEstimatedCost > 0 {
                    StatBadge(
                        icon: "dollarsign.circle.fill",
                        value: String(format: "$%.0f", totalEstimatedCost),
                        label: "Est. Cost",
                        color: .orange
                    )
                }
            }
            
            // Show free time gaps if any
            if !freeTimeGaps.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(freeTimeGaps.indices, id: \.self) { index in
                            let gap = freeTimeGaps[index]
                            FreeTimeGapChip(
                                start: gap.start,
                                end: gap.end,
                                duration: gap.duration
                            )
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func formatHours(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        if totalMinutes < 60 {
            return "\(totalMinutes)m"
        } else {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            if m == 0 {
                return "\(h)h"
            }
            return "\(h)h \(m)m"
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval / 3600)
        let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FreeTimeGapChip: View {
    let start: Date
    let end: Date
    let duration: TimeInterval
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption2)
            Text("\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
            Text("(\(formatDuration(duration)))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .foregroundStyle(.green)
        .cornerRadius(12)
    }
    
    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval / 60)
        if minutes < 60 {
            return "\(minutes)m free"
        }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if remainingMinutes == 0 {
            return "\(hours)h free"
        }
        return "\(hours)h \(remainingMinutes)m free"
    }
}

// MARK: - Add Activity At Time Sheet (for tap-to-add)
struct AddActivityAtTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let day: TripDay
    let suggestedTime: Date
    
    @State private var activityName = ""
    @State private var location = ""
    @State private var category = "Attraction"
    @State private var scheduledTime: Date
    @State private var duration: Double = 1.0
    @State private var notes = ""
    
    let categories = ["Food", "Attraction", "Hotel", "Other"]
    
    init(day: TripDay, suggestedTime: Date) {
        self.day = day
        self.suggestedTime = suggestedTime
        _scheduledTime = State(initialValue: suggestedTime)
    }
    
    var isFormValid: Bool {
        !activityName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !location.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundStyle(.blue)
                        Text("Adding activity at \(suggestedTime.formatted(date: .omitted, time: .shortened))")
                            .font(.subheadline)
                    }
                }
                
                Section("Activity Details") {
                    TextField("Activity Name", text: $activityName)
                    
                    LocationSearchField(
                        title: "Location",
                        location: $location,
                        icon: "mappin.circle.fill",
                        iconColor: .blue,
                        searchRegionAddress: day.startLocation
                    )
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("Time") {
                    DatePicker("Start Time", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formatDuration(duration))
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            ForEach([30, 60, 90, 120], id: \.self) { minutes in
                                Button {
                                    duration = Double(minutes) / 60.0
                                } label: {
                                    Text(minutes < 60 ? "\(minutes)m" : "\(minutes/60)h\(minutes % 60 > 0 ? "\(minutes % 60)m" : "")")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Int(duration * 60) == minutes ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundStyle(Int(duration * 60) == minutes ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 60)
                }
            }
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addActivity()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        } else {
            let h = totalMinutes / 60
            let m = totalMinutes % 60
            return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
        }
    }
    
    private func addActivity() {
        let newActivity = Activity(
            name: activityName.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            category: category
        )
        
        newActivity.order = day.activities.count
        newActivity.isCompleted = true
        newActivity.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        newActivity.scheduledTime = calendar.date(bySettingHour: timeComponents.hour ?? 9,
                                                   minute: timeComponents.minute ?? 0,
                                                   second: 0,
                                                   of: day.date)
        newActivity.duration = duration
        
        day.activities.append(newActivity)
        dismiss()
    }
}

// MARK: - Template Picker Sheet
struct TemplatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let day: TripDay
    
    @Query(sort: \ActivityTemplate.usageCount, order: .reverse) private var templates: [ActivityTemplate]
    @State private var showingCreateTemplate = false
    
    // Preset quick templates
    private let presetTemplates: [(name: String, category: String, duration: Double, icon: String)] = [
        ("Breakfast", "Food", 1.0, "cup.and.saucer.fill"),
        ("Lunch", "Food", 1.0, "fork.knife"),
        ("Dinner", "Food", 1.5, "wineglass.fill"),
        ("Coffee Break", "Food", 0.5, "cup.and.saucer.fill"),
        ("Hotel Check-in", "Hotel", 0.5, "building.2.fill"),
        ("Hotel Check-out", "Hotel", 0.5, "door.left.hand.open"),
        ("Gas Stop", "Other", 0.25, "fuelpump.fill"),
        ("Rest Stop", "Other", 0.25, "figure.stand"),
        ("Scenic Overlook", "Attraction", 0.5, "binoculars.fill"),
        ("Photo Stop", "Attraction", 0.25, "camera.fill")
    ]
    
    var body: some View {
        NavigationStack {
            List {
                // Quick Presets
                Section("Quick Add") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(presetTemplates, id: \.name) { template in
                            Button {
                                addFromPreset(template)
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: template.icon)
                                        .font(.title2)
                                        .foregroundStyle(categoryColor(template.category))
                                    Text(template.name)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(categoryColor(template.category).opacity(0.1))
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // Saved Kinds
                if !templates.isEmpty {
                    Section("Saved Kinds") {
                        ForEach(templates) { template in
                            Button {
                                addFromTemplate(template)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(template.name)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                        HStack(spacing: 8) {
                                            Text(template.category)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text("•")
                                                .foregroundStyle(.secondary)
                                            Text(formatDuration(template.defaultDuration))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing) {
                                        Text("Used \(template.usageCount)x")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    modelContext.delete(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
                
                // Create New Kind
                Section {
                    Button {
                        showingCreateTemplate = true
                    } label: {
                        Label("Create New Kind", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Kinds of Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateSheet()
            }
        }
    }
    
    private func categoryColor(_ category: String) -> Color {
        switch category {
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
        }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
    
    private func addFromPreset(_ preset: (name: String, category: String, duration: Double, icon: String)) {
        let activity = Activity(name: preset.name, location: day.startLocation, category: preset.category)
        activity.duration = preset.duration
        activity.order = day.activities.count
        activity.isCompleted = true
        
        // Set suggested time based on existing activities
        activity.scheduledTime = suggestNextTime()
        
        day.activities.append(activity)
        dismiss()
    }
    
    private func addFromTemplate(_ template: ActivityTemplate) {
        let activity = template.createActivity(for: day, at: suggestNextTime())
        day.activities.append(activity)
        dismiss()
    }
    
    private func suggestNextTime() -> Date {
        let calendar = Calendar.current
        
        // Get all scheduled activities sorted by time
        let scheduledActivities = day.activities
            .filter { $0.scheduledTime != nil && $0.duration != nil }
            .sorted { $0.scheduledTime! < $1.scheduledTime! }
        
        if let lastActivity = scheduledActivities.last,
           let lastTime = lastActivity.scheduledTime,
           let lastDuration = lastActivity.duration {
            // Suggest 15 minutes after the last activity ends
            return lastTime.addingTimeInterval((lastDuration + 0.25) * 3600)
        }
        
        // Default to 9 AM if no activities
        return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: day.date) ?? day.date
    }
}

// MARK: - Create Template Sheet
struct CreateTemplateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var location = ""
    @State private var category = "Attraction"
    @State private var defaultDuration: Double = 1.0
    @State private var notes = ""
    @State private var estimatedCost: Double = 0
    @State private var includeCost = false
    
    let categories = ["Food", "Attraction", "Hotel", "Other"]
    
    var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Kind Details") {
                    TextField("Kind Name", text: $name)
                    TextField("Default Location (optional)", text: $location)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
                
                Section("Default Duration") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Duration")
                            Spacer()
                            Text(formatDuration(defaultDuration))
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $defaultDuration, in: 0.25...4, step: 0.25)
                        
                        HStack(spacing: 8) {
                            ForEach([15, 30, 60, 90, 120], id: \.self) { minutes in
                                Button {
                                    defaultDuration = Double(minutes) / 60.0
                                } label: {
                                    Text(minutes < 60 ? "\(minutes)m" : "\(minutes/60)h")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Int(defaultDuration * 60) == minutes ? Color.blue : Color.gray.opacity(0.2))
                                        .foregroundStyle(Int(defaultDuration * 60) == minutes ? .white : .primary)
                                        .cornerRadius(6)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Budget") {
                    Toggle("Include Estimated Cost", isOn: $includeCost)
                    
                    if includeCost {
                        HStack {
                            Text("$")
                            TextField("0.00", value: $estimatedCost, format: .number.precision(.fractionLength(2)))
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 60)
                }
            }
            .navigationTitle("New Kind")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func formatDuration(_ hours: Double) -> String {
        let totalMinutes = Int(hours * 60)
        if totalMinutes < 60 {
            return "\(totalMinutes) min"
        }
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return m == 0 ? "\(h) hr" : "\(h) hr \(m) min"
    }
    
    private func saveTemplate() {
        let template = ActivityTemplate(
            name: name.trimmingCharacters(in: .whitespaces),
            location: location.trimmingCharacters(in: .whitespaces),
            category: category,
            defaultDuration: defaultDuration
        )
        template.notes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        
        if includeCost && estimatedCost > 0 {
            template.estimatedCost = estimatedCost
        }
        
        modelContext.insert(template)
        dismiss()
    }
}
