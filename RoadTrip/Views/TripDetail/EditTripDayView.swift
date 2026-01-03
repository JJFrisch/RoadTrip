// Views/TripDetail/EditTripDayView.swift
import SwiftUI
import SwiftData
import MapKit

struct EditTripDayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let day: TripDay
    
    @State private var startLocation: String
    @State private var endLocation: String
    @State private var distance: Double
    @State private var drivingTime: Double
    @State private var hotelName: String
    @State private var isCalculatingRoute = false
    @State private var endLocationRegion: MKCoordinateRegion?
    
    init(day: TripDay) {
        self.day = day
        _startLocation = State(initialValue: day.startLocation)
        _endLocation = State(initialValue: day.endLocation)
        _distance = State(initialValue: day.distance)
        _drivingTime = State(initialValue: day.drivingTime)
        _hotelName = State(initialValue: day.hotelName ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Day Information") {
                    HStack {
                        Text("Day")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(day.dayNumber)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Date")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(day.date.formatted(date: .abbreviated, time: .omitted))
                            .fontWeight(.semibold)
                    }
                }
                
                Section("Route Details") {
                    LocationSearchField(
                        title: "From",
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
                        title: "To",
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
                    
                    HStack {
                        Image(systemName: "road.lanes")
                            .foregroundStyle(.blue)
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
                        Image(systemName: "clock")
                            .foregroundStyle(.orange)
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
                        placeholder: "Optional",
                        searchRegion: endLocationRegion
                    )
                }
            }
            .navigationTitle("Edit Day \(day.dayNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        day.startLocation = startLocation
        day.endLocation = endLocation
        day.distance = distance
        day.drivingTime = drivingTime
        day.hotelName = hotelName.isEmpty ? nil : hotelName
        
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
