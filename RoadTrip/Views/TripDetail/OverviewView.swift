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
    @State private var browsingHotelDay: TripDay?
    @State private var showingShareSheet = false
    @State private var sharePDFData: Data?
    
    var body: some View {
        VStack(spacing: 0) {
            if trip.days.isEmpty {
                emptyDaysView
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        // Summary Card
                        VStack(spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Trip Summary")
                                        .font(.headline)
                                    Text("\(trip.days.count) day\(trip.days.count == 1 ? "" : "s") planned")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "map.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue.gradient)
                            }
                            
                            Divider()
                            
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Distance")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "road.lanes")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                        
                                        Text(String(format: "%.0f mi", trip.totalDistance))
                                            .font(.headline)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .center, spacing: 4) {
                                    Text("Drive Time")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "car.fill")
                                            .font(.caption)
                                            .foregroundStyle(.green)
                                        
                                        Text(formatDrivingTime(trip.totalDrivingTime))
                                            .font(.headline)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Hotel Nights")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "bed.double.fill")
                                            .font(.caption)
                                            .foregroundStyle(.purple)
                                        
                                        Text("\(trip.days.filter { $0.hotel != nil || (($0.hotelName ?? "").isEmpty == false) }.count)")
                                            .font(.headline)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                        .padding()
                        
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
        .sheet(item: $browsingHotelDay) { day in
            HotelBrowsingView(day: day)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let pdfData = sharePDFData {
                ShareSheet(items: [pdfData], fileName: "\(trip.name).pdf")
            }
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
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(day.dayNumber)")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text(day.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive) {
                    deleteDay(day)
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .foregroundStyle(.red.opacity(0.6))
                        .font(.title3)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Button {
                    editingDay = day
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "location.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("From")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(day.startLocation)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
                
                Button {
                    editingDay = day
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("To")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(day.endLocation)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.blue.opacity(0.6))
                    }
                }
                .buttonStyle(.plain)
            }
            
            if day.distance > 0 || day.drivingTime > 0 {
                Divider()
                
                HStack(spacing: 16) {
                    if day.distance > 0 {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Distance")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(String(format: "%.0f mi", day.distance))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                    }
                    
                    if day.drivingTime > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Driving Time")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            let hours = Int(day.drivingTime)
                            let minutes = Int((day.drivingTime - Double(hours)) * 60)
                            
                            if hours > 0 {
                                Text("\(hours)h \(minutes)m")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            } else {
                                Text("\(minutes)m")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                }
            }
            
            let hotelDisplayName = day.hotel?.name ?? day.hotelName ?? ""
            if !hotelDisplayName.isEmpty {
                Divider()
                
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    
                    Text(hotelDisplayName)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.bottom, 12)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                addingActivityDay = day
            } label: {
                Label("Add Activity", systemImage: "plus.circle")
            }

            Button {
                browsingHotelDay = day
            } label: {
                Label("Add/Change Hotel", systemImage: "bed.double")
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
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
            Text("No days added yet")
                .foregroundStyle(.secondary)
            Button("Add First Day") {
                showingAddDay = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func deleteDay(_ day: TripDay) {
        modelContext.delete(day)
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
