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
        
        let startRequest = MKLocalSearch.Request()
        startRequest.naturalLanguageQuery = startLocation
        let startSearch = MKLocalSearch(request: startRequest)
        
        let endRequest = MKLocalSearch.Request()
        endRequest.naturalLanguageQuery = endLocation
        let endSearch = MKLocalSearch(request: endRequest)
        
        Task {
            do {
                let startResult = try await startSearch.start()
                let endResult = try await endSearch.start()
                
                guard let startPlacemark = startResult.mapItems.first?.placemark,
                      let endPlacemark = endResult.mapItems.first?.placemark else {
                    await MainActor.run { isCalculatingRoute = false }
                    return
                }
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: startPlacemark)
                request.destination = MKMapItem(placemark: endPlacemark)
                request.transportType = .automobile
                
                let directions = MKDirections(request: request)
                let response = try await directions.calculate()
                
                if let route = response.routes.first {
                    await MainActor.run {
                        distance = route.distance / 1609.34 // Convert meters to miles
                        drivingTime = route.expectedTravelTime / 3600.0 // Convert seconds to hours
                        isCalculatingRoute = false
                    }
                }
            } catch {
                await MainActor.run {
                    isCalculatingRoute = false
                }
            }
        }
    }
    
    private func updateEndLocationRegion() {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = endLocation
        let search = MKLocalSearch(request: request)
        
        Task {
            do {
                let result = try await search.start()
                if let mapItem = result.mapItems.first {
                    await MainActor.run {
                        endLocationRegion = MKCoordinateRegion(
                            center: mapItem.placemark.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                        )
                    }
                }
            } catch {
                // Silently fail - region will remain nil
            }
        }
    }
}
