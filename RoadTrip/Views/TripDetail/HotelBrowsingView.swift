//
//  HotelBrowsingView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI
import SwiftData

struct HotelBrowsingView: View {
    let day: TripDay
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var searchService = HotelSearchService.shared
    @Query private var preferences: [HotelPreferences]
    
    @State private var searchLocation: String
    @State private var checkInDate: Date
    @State private var checkOutDate: Date
    @State private var guests: Int = 2
    @State private var showingFilters = false
    @State private var showingSourceSettings = false
    @State private var filters = HotelFilters()
    @State private var selectedHotel: HotelSearchResult?
    @State private var hasSearched = false
    
    private var userPreferences: HotelPreferences {
        preferences.first ?? {
            let prefs = HotelPreferences()
            modelContext.insert(prefs)
            return prefs
        }()
    }
    
    init(day: TripDay) {
        self.day = day
        _searchLocation = State(initialValue: day.endLocation.isEmpty ? day.startLocation : day.endLocation)
        _checkInDate = State(initialValue: day.date)
        
        // Default checkout to next day
        let calendar = Calendar.current
        _checkOutDate = State(initialValue: calendar.date(byAdding: .day, value: 1, to: day.date) ?? day.date)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    // Location Search
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        TextField("Destination", text: $searchLocation)
                            .textFieldStyle(.plain)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Dates and Guests
                    HStack(spacing: 12) {
                        // Check-in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Check-in")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $checkInDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Check-out
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Check-out")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            DatePicker("", selection: $checkOutDate, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Guests and Search
                    HStack(spacing: 12) {
                        // Guests
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundStyle(.blue)
                            Stepper("\(guests) Guest\(guests == 1 ? "" : "s")", value: $guests, in: 1...10)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Search Button
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
                    
                    // Filter and Source Buttons
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
                        
                        Button {
                            showingSourceSettings = true
                        } label: {
                            HStack {
                                Image(systemName: "globe")
                                Text("\(userPreferences.enabledSources.count) Sources")
                            }
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(20)
                        }
                        
                        Spacer()
                        
                        // Sort Picker
                        Menu {
                            Picker("Sort By", selection: $filters.sortBy) {
                                ForEach(HotelFilters.SortOption.allCases, id: \.self) { option in
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
                .background(Color(.systemBackground))
                
                Divider()
                
                // Results
                if searchService.isSearching {
                    VStack(spacing: 20) {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Searching hotels...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Checking \(userPreferences.enabledSources.count) booking site\(userPreferences.enabledSources.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else if !hasSearched {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        Text("Search for Hotels")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Enter your destination and dates to find the best hotels")
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
                        Text("No Hotels Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Try adjusting your filters or search criteria")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(searchService.searchResults) { hotel in
                                HotelResultCard(hotel: hotel)
                                    .onTapGesture {
                                        selectedHotel = hotel
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Find Hotels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                HotelFiltersSheet(filters: $filters)
            }
            .sheet(isPresented: $showingSourceSettings) {
                HotelSourceSettingsSheet(preferences: userPreferences)
            }
            .sheet(item: $selectedHotel) { hotel in
                HotelDetailView(hotel: hotel, day: day)
            }
        }
    }
    
    private var hasActiveFilters: Bool {
        filters.minPrice != nil ||
        filters.maxPrice != nil ||
        filters.minRating != nil ||
        filters.minStars != nil ||
        filters.requireWiFi ||
        filters.requireParking ||
        filters.requireBreakfast ||
        filters.requirePool ||
        filters.petFriendly
    }
    
    private func performSearch() {
        hasSearched = true
        Task {
            _ = await searchService.searchHotels(
                location: searchLocation,
                checkInDate: checkInDate,
                checkOutDate: checkOutDate,
                guests: guests,
                enabledSources: userPreferences.enabledSources,
                filters: filters
            )
        }
    }
}

// MARK: - Hotel Result Card
struct HotelResultCard: View {
    let hotel: HotelSearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hotel Image
            ZStack(alignment: .topTrailing) {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(16/9, contentMode: .fill)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                
                // Source Badge
                Text(hotel.source.rawValue)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(sourceColor(hotel.source))
                    .cornerRadius(6)
                    .padding(8)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12, corners: [.topLeft, .topRight]))
            
            // Hotel Info
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(hotel.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 4) {
                        if let stars = hotel.starRating {
                            HStack(spacing: 2) {
                                ForEach(0..<stars, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                        
                        if let rating = hotel.rating {
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f", rating))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.blue)
                                
                                if let reviewCount = hotel.reviewCount {
                                    Text("(\(reviewCount) reviews)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    Text("\(hotel.address), \(hotel.city)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                // Amenities
                if !hotel.amenities.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(hotel.amenities.prefix(4), id: \.self) { amenity in
                                Text(amenity)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(4)
                            }
                            if hotel.amenities.count > 4 {
                                Text("+\(hotel.amenities.count - 4)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                
                // Price
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let price = hotel.pricePerNight {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$\(Int(price))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                                Text("/night")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("Price on request")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        // View details
                    } label: {
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
    
    private func sourceColor(_ source: HotelSearchResult.BookingSource) -> Color {
        switch source {
        case .booking: return Color.blue
        case .hotels: return Color.red
        case .expedia: return Color.yellow
        case .airbnb: return Color.pink
        case .direct: return Color.green
        }
    }
}

extension RoundedRectangle {
    init(cornerRadius: CGFloat, corners: UIRectCorner) {
        self.init(cornerRadius: cornerRadius)
    }
}
