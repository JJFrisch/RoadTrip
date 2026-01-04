// Views/TripDetail/OverviewView.swift
import SwiftUI
import SwiftData
import MapKit

struct OverviewView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip
    @State private var showingAddDay = false
    @State private var editingDay: TripDay?
    
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
                                        
                                        Text("\(trip.days.filter { $0.hotelName != nil }.count)")
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
            
            if let hotelName = day.hotelName {
                Divider()
                
                HStack(spacing: 8) {
                    Image(systemName: "bed.double.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.purple)
                    
                    Text(hotelName)
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
        .onTapGesture {
            editingDay = day
        }
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
    @State private var endLocationRegion: MKCoordinateRegion?
    
    var isFormValid: Bool {
        !startLocation.trimmingCharacters(in: .whitespaces).isEmpty &&
        !endLocation.trimmingCharacters(in: .whitespaces).isEmpty &&
        distance >= 0 &&
        drivingTime >= 0
    }
    
    var validationError: String? {
        if startLocation.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Start location is required"
        }
        if endLocation.trimmingCharacters(in: .whitespaces).isEmpty {
            return "End location is required"
        }
        if distance < 0 {
            return "Distance cannot be negative"
        }
        if drivingTime < 0 {
            return "Driving time cannot be negative"
        }
        return nil
    }
    
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
                    .onChange(of: startLocation) { oldValue, newValue in
                        if !newValue.isEmpty && !endLocation.isEmpty {
                            calculateRoute()
                        }
                    }
                    
                    LocationSearchField(
                        title: "End Location",
                        location: $endLocation,
                        icon: "mappin.circle.fill",
                        iconColor: .red
                    )
                    .onChange(of: endLocation) { oldValue, newValue in
                        if !newValue.isEmpty {
                            if !startLocation.isEmpty {
                                calculateRoute()
                            }
                            updateEndLocationRegion()
                        }
                    }
                }
                
                Section("Route Details") {
                    HStack {
                        Text("Distance (miles)")
                        Spacer()
                        if isCalculatingRoute {
                            ProgressView()
                                .frame(width: 80)
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
                            ProgressView()
                                .frame(width: 80)
                        } else {
                            TextField("0", value: $drivingTime, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                        }
                    }
                }
                
                Section("Accommodation") {
                    LocationSearchField(
                        title: "Hotel",
                        location: $hotelName,
                        icon: "bed.double.circle.fill",
                        iconColor: .purple,
                        placeholder: "Hotel (optional)",
                        searchRegion: endLocationRegion
                    )
                }
                
                if let error = validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
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
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func addDay() {
        let dayNumber = trip.days.count + 1
        let date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: trip.startDate) ?? trip.startDate
        
        let newDay = TripDay(dayNumber: dayNumber, date: date, 
                            startLocation: startLocation.trimmingCharacters(in: .whitespaces), 
                            endLocation: endLocation.trimmingCharacters(in: .whitespaces))
        newDay.hotelName = hotelName.trimmingCharacters(in: .whitespaces).isEmpty ? nil : hotelName
        newDay.distance = distance
        newDay.drivingTime = drivingTime
        trip.days.append(newDay)
        
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
    
    private func updateEndLocationRegion() {
        Task {
            do {
                let placemark = try await RouteCalculator.shared.getPlacemark(for: endLocation)
                await MainActor.run {
                    endLocationRegion = MKCoordinateRegion(
                        center: placemark.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                }
            } catch {
                // Silently fail - region will remain nil
            }
        }
    }
}
