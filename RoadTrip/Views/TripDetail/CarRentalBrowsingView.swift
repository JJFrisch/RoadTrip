//
//  CarRentalBrowsingView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI
import SwiftData
import CoreLocation

struct CarRentalBrowsingView: View {
    let trip: Trip
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var searchService = CarRentalSearchService.shared
    @State private var pickUpLocation: String
    @State private var dropOffLocation: String
    @State private var pickUpDate: Date
    @State private var dropOffDate: Date
    @State private var pickUpTime = "10:00"
    @State private var dropOffTime = "10:00"
    @State private var driverAge = 30
    @State private var showingFilters = false
    @State private var filters = CarRentalFilters()
    @State private var selectedCar: CarRentalSearchResult?
    @State private var hasSearched = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(trip: Trip) {
        self.trip = trip
        let firstDay = trip.days.sorted(by: { $0.dayNumber < $1.dayNumber }).first
        _pickUpLocation = State(initialValue: firstDay?.startLocation ?? "")
        _dropOffLocation = State(initialValue: trip.days.sorted(by: { $0.dayNumber < $1.dayNumber }).last?.endLocation ?? firstDay?.startLocation ?? "")
        _pickUpDate = State(initialValue: firstDay?.date ?? Date())
        _dropOffDate = State(initialValue: trip.days.sorted(by: { $0.dayNumber < $1.dayNumber }).last?.date ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Network Status Banner
                NetworkStatusBanner()
                
                // Search Header
                ScrollView {
                    VStack(spacing: 16) {
                        // Pick-up Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pick-up Location")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundStyle(.green)
                                TextField("Pick-up location", text: $pickUpLocation)
                                    .textFieldStyle(.plain)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Drop-off Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Drop-off Location")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundStyle(.red)
                                TextField("Drop-off location", text: $dropOffLocation)
                                    .textFieldStyle(.plain)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Dates
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pick-up")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                DatePicker("", selection: $pickUpDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Drop-off")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                DatePicker("", selection: $dropOffDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Driver Age & Search
                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.blue)
                                Stepper("Age: \(driverAge)", value: $driverAge, in: 18...99)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            Button {
                                performSearch()
                            } label: {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Search")
                                        .fontWeight(.semibold)
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                        }
                        
                        // Filter & Sort
                        HStack(spacing: 12) {
                            Button {
                                showingFilters = true
                            } label: {
                                HStack {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                    Text("Filters")
                                    if hasActiveFilters {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(20)
                            }
                            
                            Spacer()
                            
                            Menu {
                                Picker("Sort By", selection: $filters.sortBy) {
                                    ForEach(CarRentalFilters.SortOption.allCases, id: \.self) { option in
                                        Text(option.rawValue).tag(option)
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.up.arrow.down")
                                    Text("Sort")
                                }
                                .font(.subheadline)
                                .foregroundStyle(.purple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(20)
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 400)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Results
                if searchService.isSearching {
                    VStack(spacing: 20) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Searching for cars...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else if !hasSearched {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        Text("Search for Rental Cars")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Enter your pick-up and drop-off details to find available cars")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else if searchService.searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(.secondary)
                        Text("No Cars Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Try adjusting your filters or search criteria")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Retry Button
                        Button {
                            performSearch()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Try Again")
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                } else if let apiError = searchService.errorMessage {
                    // API Error State
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)
                        Text("Search Error")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text(apiError)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Retry Button
                        Button {
                            performSearch()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry Search")
                            }
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(width: 200)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(searchService.searchResults) { car in
                                CarResultCard(car: car)
                                    .onTapGesture {
                                        selectedCar = car
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Rent a Car")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                CarRentalFiltersSheet(filters: $filters)
            }
            .sheet(item: $selectedCar) { car in
                CarRentalDetailView(car: car, trip: trip, pickUpDate: pickUpDate, dropOffDate: dropOffDate)
            }
            .alert("Search Error", isPresented: $showingError) {
                Button("Retry") {
                    performSearch()
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        filters.minPrice != nil ||
        filters.maxPrice != nil ||
        !filters.carTypes.isEmpty ||
        filters.transmissionType != nil ||
        filters.minSeats != nil ||
        filters.requireAirConditioning ||
        filters.requireGPS ||
        filters.requireUnlimitedMileage ||
        !filters.fuelTypes.isEmpty
    }
    
    private func performSearch() {
        hasSearched = true
        Task {
            do {
                // Geocode pick-up location
                let pickUpCoordinates = try await GeocodingService.shared.geocode(location: pickUpLocation)
                print("📍 Pick-up: \(pickUpCoordinates.latitude), \(pickUpCoordinates.longitude)")
                
                // Geocode drop-off location
                let dropOffCoordinates = try await GeocodingService.shared.geocode(location: dropOffLocation)
                print("📍 Drop-off: \(dropOffCoordinates.latitude), \(dropOffCoordinates.longitude)")
                
                _ = await searchService.searchCarRentals(
                    pickUpLocation: pickUpLocation,
                    pickUpLatitude: pickUpCoordinates.latitude,
                    pickUpLongitude: pickUpCoordinates.longitude,
                    dropOffLocation: dropOffLocation,
                    dropOffLatitude: dropOffCoordinates.latitude,
                    dropOffLongitude: dropOffCoordinates.longitude,
                    pickUpDate: pickUpDate,
                    pickUpTime: pickUpTime,
                    dropOffDate: dropOffDate,
                    dropOffTime: dropOffTime,
                    driverAge: driverAge,
                    filters: filters
                )
            } catch {
                print("❌ Geocoding error: \(error.localizedDescription)")
                errorMessage = "Unable to find one or both locations. Please check your spelling and try again."
                showingError = true
                
                // Fallback to default coordinates (San Francisco)
                _ = await searchService.searchCarRentals(
                    pickUpLocation: pickUpLocation,
                    pickUpLatitude: 37.7749,
                    pickUpLongitude: -122.4194,
                    dropOffLocation: dropOffLocation,
                    dropOffLatitude: 37.7749,
                    dropOffLongitude: -122.4194,
                    pickUpDate: pickUpDate,
                    pickUpTime: pickUpTime,
                    dropOffDate: dropOffDate,
                    dropOffTime: dropOffTime,
                    driverAge: driverAge,
                    filters: filters
                )
            }
        }
    }
}

// MARK: - Car Result Card
struct CarResultCard: View {
    let car: CarRentalSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Car Image
            ZStack(alignment: .topTrailing) {
                if let imageURL = car.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .overlay {
                                    Image(systemName: "car.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                        @unknown default:
                            Rectangle()
                                .fill(Color(.systemGray5))
                        }
                    }
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "car.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                }
                
                // Source Badge
                Text(car.source.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.blue)
                    .cornerRadius(6)
                    .padding(8)
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 12, corners: [.topLeft, .topRight]))
            
            // Car Info
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(car.carName)
                        .font(.headline)
                    Text("\(car.company) • \(car.carType)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Features
                HStack(spacing: 16) {
                    Label("\(car.seats)", systemImage: "person.2.fill")
                    Label(car.transmission, systemImage: "gearshape.fill")
                    if car.hasAirConditioning {
                        Image(systemName: "snowflake")
                    }
                    if car.hasUnlimitedMileage {
                        Image(systemName: "infinity")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                
                // Price
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$\(Int(car.totalPrice))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                            Text("total")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("$\(Int(car.pricePerDay))/day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {} label: {
                        Text("View Details")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}
