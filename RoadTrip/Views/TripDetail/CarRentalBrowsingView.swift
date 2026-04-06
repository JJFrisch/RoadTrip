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
    @Environment(\.colorScheme) private var colorScheme
    
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
    @State private var showingInlineStatus = false
    
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

                if showingInlineStatus {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.Colors.warning)
                        Text(errorMessage)
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                            .lineLimit(2)
                        Spacer()
                        Button("Dismiss") {
                            withAnimation(.easeInOut(duration: AppTheme.Animation.fast)) {
                                showingInlineStatus = false
                            }
                        }
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.primary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.warning.opacity(0.12))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Search Header
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Pick-up Location
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Pick-up Location")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.success)
                                TextField("Pick-up location", text: $pickUpLocation)
                                    .textFieldStyle(.plain)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.background)
                            .cornerRadius(AppTheme.CornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                    .stroke(AppTheme.Colors.divider, lineWidth: 1)
                            )
                        }
                        
                        // Drop-off Location
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            Text("Drop-off Location")
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                            HStack {
                                Image(systemName: "location.circle.fill")
                                    .foregroundStyle(AppTheme.Colors.danger)
                                TextField("Drop-off location", text: $dropOffLocation)
                                    .textFieldStyle(.plain)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.background)
                            .cornerRadius(AppTheme.CornerRadius.large)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                    .stroke(AppTheme.Colors.divider, lineWidth: 1)
                            )
                        }
                        
                        // Dates
                        HStack(spacing: AppTheme.Spacing.sm) {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text("Pick-up")
                                    .font(AppTheme.Typography.caption1)
                                    .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                DatePicker("", selection: $pickUpDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.background)
                            .cornerRadius(AppTheme.CornerRadius.large)
                            
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xxs) {
                                Text("Drop-off")
                                    .font(AppTheme.Typography.caption1)
                                    .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                DatePicker("", selection: $dropOffDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.background)
                            .cornerRadius(AppTheme.CornerRadius.large)
                        }
                        
                        // Driver Age & Search
                        HStack(spacing: AppTheme.Spacing.sm) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(AppTheme.Colors.primary)
                                Stepper("Age: \(driverAge)", value: $driverAge, in: 18...99)
                            }
                            .padding(AppTheme.Spacing.md)
                            .background(AppTheme.Colors.background)
                            .cornerRadius(AppTheme.CornerRadius.large)
                            
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
                                .padding(AppTheme.Spacing.md)
                                .background(AppTheme.Colors.primary)
                                .cornerRadius(AppTheme.CornerRadius.large)
                            }
                            .accessibilityLabel("Search rental cars")
                        }
                        
                        // Filter & Sort
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Button {
                                showingFilters = true
                            } label: {
                                HStack {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                    Text("Filters")
                                    if hasActiveFilters {
                                        Circle()
                                            .fill(AppTheme.Colors.danger)
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.primary)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.vertical, AppTheme.Spacing.xs)
                                .background(AppTheme.Colors.primary.opacity(0.12))
                                .cornerRadius(20)
                            }
                            .accessibilityLabel("Open car rental filters")
                            
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
                                .font(AppTheme.Typography.subheadline)
                                .foregroundStyle(AppTheme.Colors.accent)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.vertical, AppTheme.Spacing.xs)
                                .background(AppTheme.Colors.accent.opacity(0.16))
                                .cornerRadius(20)
                            }
                            .accessibilityLabel("Sort car rental results")
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
                .frame(maxHeight: 400)
                .background(AppTheme.Colors.secondaryBackground)
                
                Divider()
                
                // Results
                if searchService.isSearching {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Searching for cars...")
                            .font(AppTheme.Typography.headline)
                            .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                        Spacer()
                    }
                } else if !hasSearched {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Spacer()
                        Image(systemName: "car.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(AppTheme.Colors.primary)
                        Text("Search for Rental Cars")
                            .font(AppTheme.Typography.title2)
                            .fontWeight(.semibold)
                        Text("Enter your pick-up and drop-off details to find available cars")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        Spacer()
                    }
                } else if searchService.searchResults.isEmpty {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Spacer()
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                        Text("No Cars Found")
                            .font(AppTheme.Typography.title2)
                            .fontWeight(.semibold)
                        Text("Try adjusting your filters or search criteria")
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
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
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .padding(.top, AppTheme.Spacing.xs)
                        
                        Spacer()
                    }
                } else if let apiError = searchService.errorMessage {
                    // API Error State
                    VStack(spacing: AppTheme.Spacing.md) {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(AppTheme.Colors.warning)
                        Text("Search Error")
                            .font(AppTheme.Typography.title2)
                            .fontWeight(.semibold)
                        Text(apiError)
                            .font(AppTheme.Typography.subheadline)
                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xxl)
                        
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
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                        }
                        .padding(.top, AppTheme.Spacing.xs)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
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
                withAnimation(.easeInOut(duration: AppTheme.Animation.fast)) {
                    showingInlineStatus = true
                }
                
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Car Image
            ZStack(alignment: .topTrailing) {
                if let imageURL = car.imageURL, let url = URL(string: imageURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(AppTheme.Colors.background)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Rectangle()
                                .fill(AppTheme.Colors.background)
                                .overlay {
                                    Image(systemName: "car.fill")
                                        .font(.largeTitle)
                                        .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                }
                        @unknown default:
                            Rectangle()
                                .fill(AppTheme.Colors.background)
                        }
                    }
                } else {
                    Rectangle()
                        .fill(AppTheme.Colors.background)
                        .overlay {
                            Image(systemName: "car.fill")
                                .font(.largeTitle)
                                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                        }
                }
            }
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large, corners: [.topLeft, .topRight]))
            
            // Car Info
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(car.carName)
                        .font(.headline)
                    Text("\(car.company) • \(car.carType)")
                        .font(AppTheme.Typography.subheadline)
                        .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
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
                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                
                // Price
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$\(Int(car.totalPrice))")
                                .font(AppTheme.Typography.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.Colors.success)
                            Text("total")
                                .font(AppTheme.Typography.caption1)
                                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                        }
                        Text("$\(Int(car.pricePerDay))/day")
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    Button {} label: {
                        Text("View Details")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.CornerRadius.medium)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(AppTheme.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(AppTheme.Colors.divider, lineWidth: 1)
        )
        .shadow(color: AppTheme.Shadows.small.color, radius: AppTheme.Shadows.small.radius, x: AppTheme.Shadows.small.x, y: AppTheme.Shadows.small.y)
    }
}
