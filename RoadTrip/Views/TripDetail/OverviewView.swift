// Views/TripDetail/OverviewView.swift
import SwiftUI
import SwiftData
import MapKit

struct OverviewView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    @State private var showingAddDay = false
    @State private var editingDay: TripDay?
    @State private var addingActivityDay: TripDay?
    @State private var showingShareSheet = false
    @State private var sharePDFData: Data?
    @State private var dayToDelete: TripDay?
    @State private var showingDeleteConfirmation = false
    @State private var showingMap = false
    
    var body: some View {
        VStack(spacing: 0) {
            if trip.days.isEmpty {
                emptyDaysView
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Summary Card
                        summaryCardView

                        OverviewMiniMapView(trip: trip)
                            .padding(.horizontal, 16)
                        
                        // Days List
                        VStack(spacing: 0) {
                            ForEach(trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                                dayRowCard(day)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddDay = true
                } label: {
                    Image(systemName: "plus.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddDay) {
            AddDayView(trip: trip)
        }
        .sheet(item: $editingDay) { day in
            EditTripDayView(day: day)
        }
        .sheet(item: $addingActivityDay) { day in
            AddActivityFromScheduleView(day: day)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = sharePDFData {
                ShareSheet(items: [pdfData], fileName: "\(trip.name).pdf")
            }
        }
        .sheet(isPresented: $showingMap) {
            let allActivities = trip.days.flatMap { $0.activities }
            ActivitiesMapView(activities: allActivities)
        }
        .overlay {
            ConfirmationSheet(
                isPresented: $showingDeleteConfirmation,
                title: dayToDelete.map { "Delete Day \($0.dayNumber)?" } ?? "Delete Day?",
                message: dayToDelete.map { "This will permanently remove Day \($0.dayNumber) and all its activities. Remaining days will be renumbered automatically." },
                actionTitle: "Delete Day",
                cancelTitle: "Keep Day",
                actionStyle: .destructive,
                onConfirm: {
                    confirmDeleteDay()
                    showingDeleteConfirmation = false
                },
                onCancel: {
                    dayToDelete = nil
                    showingDeleteConfirmation = false
                }
            )
        }
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
    
    private func dayRowCard(_ day: TripDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Day \(day.dayNumber)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        
                        Text(day.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(role: .destructive) {
                    deleteDay(day)
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .foregroundStyle(Color.red.opacity(0.6))
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .overlay(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.2))
            
            VStack(spacing: 12) {
                Button {
                    editingDay = day
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "location.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("From")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(day.startLocation)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    editingDay = day
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.0))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("To")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(day.endLocation)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
            }
            
            if day.distance > 0 || day.drivingTime > 0 {
                Divider()
                    .overlay(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.2))
                
                HStack(spacing: 16) {
                    if day.distance > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "road.lanes")
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85))
                                
                                Text("Distance")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(String(format: "%.0f mi", day.distance))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                        }
                        
                        Spacer()
                    }
                    
                    if day.drivingTime > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 4) {
                                Image(systemName: "car.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.0))
                                
                                Text("Driving Time")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            let hours = Int(day.drivingTime)
                            let minutes = Int((day.drivingTime - Double(hours)) * 60)
                            
                            if hours > 0 {
                                Text("\(hours)h \(minutes)m")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                            } else {
                                Text("\(minutes)m")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.1), radius: 4, y: 2)
        .padding(.bottom, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                addingActivityDay = day
            } label: {
                Label("Add Activity", systemImage: "plus.circle")
            }

            Button {
                duplicateActivities(in: day)
            } label: {
                Label("Duplicate Day", systemImage: "plus.square.on.square")
            }

            Button {
                if let data = PDFExportService.shared.generateTripPDF(trip: trip) {
                    sharePDFData = data
                    showingShareSheet = true
                }
            } label: {
                Label("Share PDF", systemImage: "square.and.arrow.up")
            }
        }
        .onTapGesture {
            editingDay = day
        }
    }

    private func duplicateActivities(in day: TripDay) {
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
        try? modelContext.save()
    }
    
    private var emptyDaysView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.4))
            
            VStack(spacing: 8) {
                Text("No Days Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                
                Text("Add your first day to start planning")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                showingAddDay = true
            } label: {
                Label("Add First Day", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.29, green: 0.62, blue: 0.85),
                                Color(red: 0.20, green: 0.52, blue: 0.75)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.97, blue: 0.96))
    }
    
    private var summaryCardView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trip Summary")
                        .font(.headline)
                        .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                    Text("\(trip.days.count) day\(trip.days.count == 1 ? "" : "s") planned")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let desc = trip.tripDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                Button {
                    showingMap = true
                } label: {
                    Image(systemName: "map.circle.fill")
                        .font(.title2)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.29, green: 0.62, blue: 0.85),
                                    Color(red: 1.0, green: 0.78, blue: 0.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .buttonStyle(.plain)
            }
            
            Divider()
                .overlay(Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.2))
            
            summaryStatsView
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.1), radius: 4, y: 2)
        .padding()
    }
    
    private var summaryStatsView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "road.lanes")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85))
                    
                    Text("Distance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(String(format: "%.0f mi", trip.totalDistance))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "car.fill")
                        .font(.caption)
                        .foregroundStyle(Color(red: 1.0, green: 0.78, blue: 0.0))
                    
                    Text("Drive Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(formatDrivingTime(trip.totalDrivingTime))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color(red: 0.29, green: 0.62, blue: 0.85))
                    
                    Text("Budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(String(format: "$%.0f", trip.estimatedTotalCost))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
            }
        }
    }
    
    private func deleteDay(_ day: TripDay) {
        dayToDelete = day
        showingDeleteConfirmation = true
    }
    
    private func confirmDeleteDay() {
        guard let dayToDelete = dayToDelete else { return }
        
        trip.days.removeAll(where: { $0.id == dayToDelete.id })
        
        let sortedDays = trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })
        for (index, day) in sortedDays.enumerated() {
            day.dayNumber = index + 1
        }
        
        if !trip.days.isEmpty {
            let calendar = Calendar.current
            let sortedDays = trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })
            if let firstDay = sortedDays.first, let lastDay = sortedDays.last {
                trip.startDate = firstDay.date
                trip.endDate = lastDay.date
            }
        }
        
        try? modelContext.save()
        self.dayToDelete = nil
        self.showingDeleteConfirmation = false
    }
}

// Simple Add Day Form
struct AddDayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let trip: Trip

    @State private var startLocation = ""
    @State private var endLocation = ""
    @State private var hotelName = ""
    @State private var distance: Double = 0
    @State private var drivingTime: Double = 0
    @State private var isCalculatingRoute = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Locations") {
                    LocationSearchField(
                        title: "Start Location",
                        location: $startLocation,
                        icon: "location.circle.fill",
                        iconColor: .green
                    )
                    .onChange(of: startLocation) { _, _ in
                        if !startLocation.isEmpty && !endLocation.isEmpty {
                            calculateRoute()
                        }
                    }

                    LocationSearchField(
                        title: "End Location",
                        location: $endLocation,
                        icon: "mappin.circle.fill",
                        iconColor: .red
                    )
                    .onChange(of: endLocation) { _, _ in
                        if !startLocation.isEmpty && !endLocation.isEmpty {
                            calculateRoute()
                        }
                    }
                }

                Section("Route Details") {
                    HStack {
                        Text("Distance (miles)")
                        Spacer()
                        if isCalculatingRoute {
                            ProgressView().frame(width: 80)
                        } else {
                            TextField("0", value: $distance, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }

                    HStack {
                        Text("Driving Time (hours)")
                        Spacer()
                        if isCalculatingRoute {
                            ProgressView().frame(width: 80)
                        } else {
                            TextField("0", value: $drivingTime, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                }

                Section("Accommodation") {
                    TextField("Hotel (optional)", text: $hotelName)
                }
            }
            .navigationTitle("Add Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addDay()
                    }
                    .disabled(startLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || endLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func addDay() {
        let nextNumber = (trip.days.map { $0.dayNumber }.max() ?? 0) + 1
        let nextDate = (trip.days.sorted(by: { $0.dayNumber < $1.dayNumber }).last?.date).map {
            Calendar.current.date(byAdding: .day, value: 1, to: $0)
        } ?? Calendar.current.date(byAdding: .day, value: 1, to: trip.endDate)

        let date = nextDate ?? Date()

        let newDay = TripDay(
            dayNumber: nextNumber,
            date: date,
            startLocation: startLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            endLocation: endLocation.trimmingCharacters(in: .whitespacesAndNewlines),
            distance: distance,
            drivingTime: drivingTime,
            activities: []
        )

        let trimmedHotel = hotelName.trimmingCharacters(in: .whitespacesAndNewlines)
        newDay.hotelName = trimmedHotel.isEmpty ? nil : trimmedHotel

        trip.days.append(newDay)
        trip.endDate = max(trip.endDate, date)
        try? modelContext.save()
        dismiss()
    }

    private func calculateRoute() {
        isCalculatingRoute = true
        Task {
            do {
                let routeInfo = try await RouteCalculator.shared.calculateRoute(
                    from: startLocation,
                    to: endLocation,
                    transportType: .automobile
                )
                await MainActor.run {
                    distance = routeInfo.distanceInMiles
                    drivingTime = routeInfo.durationInHours
                    isCalculatingRoute = false
                }
            } catch {
                await MainActor.run {
                    isCalculatingRoute = false
                }
            }
        }
    }
}
