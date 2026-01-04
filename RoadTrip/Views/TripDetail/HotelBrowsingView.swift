//
//  HotelBrowsingView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI
import SwiftData
import CoreLocation

struct HotelBrowsingView: View {
    let day: TripDay
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var searchService = HotelSearchService.shared
    @Query private var preferences: [HotelPreferences]
    
    @State private var searchLocation: String
    @State private var checkInDate: Date
    @State private var checkOutDate: Date
    @State private var adults: Int = 2
    @State private var children: Int = 0
    @State private var rooms: Int = 1
    @State private var childrenAges: [Int] = []
    @State private var showingFilters = false
    @State private var showingSourceSettings = false
    @State private var filters = HotelFilters()
    @State private var selectedHotel: HotelSearchResult?
    @State private var hotelToSet: HotelSearchResult?
    @State private var hasSearched = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingGuestPicker = false
    
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
                // Network Status Banner
                NetworkStatusBanner()
                
                // Compact Search Header
                VStack(spacing: 12) {
                    // Location Search
                    HStack(spacing: 12) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            TextField("Where are you staying?", text: $searchLocation)
                                .textFieldStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        
                        // Search Button
                        Button {
                            performSearch()
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 48, height: 48)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                    }
                    
                    // Dates Row
                    HStack(spacing: 10) {
                        // Check-in
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.blue)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Check-in")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(checkInDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay {
                            DatePicker("", selection: $checkInDate, displayedComponents: .date)
                                .labelsHidden()
                                .blendMode(.destinationOver)
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        // Check-out
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.orange)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Check-out")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(checkOutDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .overlay {
                            DatePicker("", selection: $checkOutDate, displayedComponents: .date)
                                .labelsHidden()
                                .blendMode(.destinationOver)
                        }
                    }
                    
                    // Guests & Filters Row
                    HStack(spacing: 10) {
                        // Guests Summary Button
                        Button {
                            showingGuestPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .foregroundStyle(.purple)
                                Text(guestsSummary)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        // Quick action buttons
                        Button {
                            showingFilters = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "slider.horizontal.3")
                                if hasActiveFilters {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 6, height: 6)
                                }
                            }
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .padding(10)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                        
                        Menu {
                            Picker("Sort By", selection: $filters.sortBy) {
                                ForEach(HotelFilters.SortOption.allCases, id: \.self) { option in
                                    Label(option.rawValue, systemImage: sortIcon(for: option))
                                        .tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.subheadline)
                                .foregroundStyle(.purple)
                                .padding(10)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
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
                        
                        VStack(spacing: 12) {
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
                            
                            // Use Mock Data Button
                            Button {
                                loadMockData()
                            } label: {
                                HStack {
                                    Image(systemName: "doc.text")
                                    Text("Use Sample Data")
                                }
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                                .frame(width: 200)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(searchService.searchResults) { hotel in
                                HotelResultCard(hotel: hotel)
                                    .onTapGesture {
                                        hotelToSet = hotel
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
            .sheet(isPresented: $showingGuestPicker) {
                GuestPickerSheet(adults: $adults, children: $children, childrenAges: $childrenAges, rooms: $rooms)
            }
            .confirmationDialog(
                "Set as Night's Hotel?",
                isPresented: Binding(
                    get: { hotelToSet != nil },
                    set: { isPresented in
                        if !isPresented {
                            hotelToSet = nil
                        }
                    }
                ),
                titleVisibility: .visible
            ) {
                Button("Set as Night's Hotel") {
                    guard let selected = hotelToSet else { return }

                    Task {
                        if let existing = day.hotel {
                            modelContext.delete(existing)
                        }

                        let hotel = selected.toHotel()

                        // If the provider didn't give coordinates (or they look invalid), geocode the full address.
                        let lat = hotel.latitude
                        let lon = hotel.longitude
                        let hasValidCoordinate = {
                            guard let lat, let lon else { return false }
                            return (-90...90).contains(lat) && (-180...180).contains(lon)
                        }()

                        if !hasValidCoordinate {
                            do {
                                let coordinate = try await GeocodingService.shared.geocode(location: geocodingQuery(for: selected))
                                hotel.latitude = coordinate.latitude
                                hotel.longitude = coordinate.longitude
                            } catch {
                                // Best-effort; keep nil if geocoding fails.
                            }
                        }

                        modelContext.insert(hotel)
                        day.hotel = hotel
                        day.hotelName = hotel.name

                        try? modelContext.save()
                        await MainActor.run {
                            hotelToSet = nil
                            dismiss()
                        }
                    }
                }

                Button("View Details") {
                    selectedHotel = hotelToSet
                    hotelToSet = nil
                }

                Button("Cancel", role: .cancel) {
                    hotelToSet = nil
                }
            } message: {
                if let selected = hotelToSet {
                    Text(selected.name)
                }
            }
            .sheet(item: $selectedHotel) { hotel in
                HotelDetailView(hotel: hotel, day: day)
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
        .onAppear {
            syncChildrenAges()
        }
        .onChange(of: children) { _, _ in
            syncChildrenAges()
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
    
    private var guestsSummary: String {
        var parts: [String] = []
        parts.append("\(adults) Adult\(adults == 1 ? "" : "s")")
        if children > 0 {
            parts.append("\(children) Kid\(children == 1 ? "" : "s")")
        }
        if rooms > 1 {
            parts.append("\(rooms) Rooms")
        }
        return parts.joined(separator: ", ")
    }
    
    private func sortIcon(for option: HotelFilters.SortOption) -> String {
        switch option {
        case .recommended: return "star"
        case .priceLowest: return "arrow.down"
        case .priceHighest: return "arrow.up"
        case .rating: return "hand.thumbsup"
        case .distance: return "location"
        }
    }

    private func syncChildrenAges() {
        if children <= 0 {
            childrenAges = []
            return
        }

        let targetCount = min(children, 10)
        if childrenAges.count > targetCount {
            childrenAges = Array(childrenAges.prefix(targetCount))
        } else if childrenAges.count < targetCount {
            childrenAges.append(contentsOf: Array(repeating: 5, count: targetCount - childrenAges.count))
        }
    }
    
    private func loadMockData() {
        Task {
            // Load mock data directly without API call
            let results = await generateSampleHotels()
            await MainActor.run {
                searchService.searchResults = results
            }
        }
    }
    
    private func generateSampleHotels() async -> [HotelSearchResult] {
        let hotelNames = ["Grand Plaza Hotel", "Comfort Inn & Suites", "Luxury Resort & Spa", "Downtown Boutique Hotel", "Mountain View Lodge"]
        let amenities = ["Free WiFi", "Free Parking", "Pool", "Fitness Center", "Restaurant", "Breakfast Included"]

        let baseCoordinate: CLLocationCoordinate2D
        do {
            baseCoordinate = try await GeocodingService.shared.geocode(location: searchLocation)
        } catch {
            baseCoordinate = CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795)
        }
        
        return hotelNames.enumerated().map { index, name in
            let latOffset = Double.random(in: -0.03...0.03)
            let lonOffset = Double.random(in: -0.03...0.03)
            return HotelSearchResult(
                id: "sample-\(index)",
                name: name,
                address: "\(100 + index * 50) Main Street",
                city: searchLocation,
                state: "CA",
                country: "USA",
                latitude: baseCoordinate.latitude + latOffset,
                longitude: baseCoordinate.longitude + lonOffset,
                rating: Double.random(in: 3.8...4.9),
                reviewCount: Int.random(in: 100...2000),
                starRating: Int.random(in: 3...5),
                thumbnailURL: nil,
                imageURLs: [],
                pricePerNight: Double.random(in: 100...350),
                totalPrice: nil,
                currency: "USD",
                amenities: Array(amenities.shuffled().prefix(4)),
                description: nil,
                bookingURL: "https://booking.com/hotel/\(index)",
                source: .booking
            )
        }
    }

    private func geocodingQuery(for hotel: HotelSearchResult) -> String {
        let parts: [String] = [
            hotel.address,
            hotel.city,
            hotel.state ?? "",
            hotel.country
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

        // Avoid obvious duplicates like address == city.
        var deduped: [String] = []
        for part in parts {
            if deduped.contains(where: { $0.caseInsensitiveCompare(part) == .orderedSame }) {
                continue
            }
            deduped.append(part)
        }

        return deduped.joined(separator: ", ")
    }
    
    private func performSearch() {
        hasSearched = true
        Task {
            // Geocode the location first
            do {
                let coordinates = try await GeocodingService.shared.geocode(location: searchLocation)
                
                print("📍 Search coordinates: \(coordinates.latitude), \(coordinates.longitude)")
                
                _ = await searchService.searchHotels(
                    location: searchLocation,
                    checkInDate: checkInDate,
                    checkOutDate: checkOutDate,
                    adults: adults,
                    children: children,
                    childrenAges: childrenAges,
                    rooms: rooms,
                    enabledSources: userPreferences.enabledSources,
                    filters: filters
                )
            } catch {
                print("❌ Geocoding error: \(error.localizedDescription)")
                errorMessage = "Unable to find location '\(searchLocation)'. Please try a different city name or check your spelling."
                showingError = true
                
                // Still search with location string, API will handle it
                _ = await searchService.searchHotels(
                    location: searchLocation,
                    checkInDate: checkInDate,
                    checkOutDate: checkOutDate,
                    adults: adults,
                    children: children,
                    childrenAges: childrenAges,
                    rooms: rooms,
                    enabledSources: userPreferences.enabledSources,
                    filters: filters
                )
            }
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
                if let imageURL = hotel.imageURLs.first, let url = URL(string: imageURL) {
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
                                    Image(systemName: "photo")
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
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
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

// MARK: - Guest Picker Sheet
struct GuestPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var adults: Int
    @Binding var children: Int
    @Binding var childrenAges: [Int]
    @Binding var rooms: Int
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Adults
                    HStack {
                        Label("Adults", systemImage: "person.fill")
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                if adults > 1 { adults -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(adults > 1 ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                            .disabled(adults <= 1)
                            
                            Text("\(adults)")
                                .font(.headline)
                                .frame(minWidth: 30)
                            
                            Button {
                                if adults < 10 { adults += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(adults < 10 ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                            .disabled(adults >= 10)
                        }
                    }
                    
                    // Children
                    HStack {
                        Label("Children", systemImage: "figure.and.child.holdinghands")
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                if children > 0 { 
                                    children -= 1
                                    syncChildrenAges()
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(children > 0 ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                            .disabled(children <= 0)
                            
                            Text("\(children)")
                                .font(.headline)
                                .frame(minWidth: 30)
                            
                            Button {
                                if children < 10 { 
                                    children += 1
                                    syncChildrenAges()
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(children < 10 ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                            .disabled(children >= 10)
                        }
                    }
                    
                    // Rooms
                    HStack {
                        Label("Rooms", systemImage: "bed.double.fill")
                        Spacer()
                        HStack(spacing: 16) {
                            Button {
                                if rooms > 1 { rooms -= 1 }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(rooms > 1 ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                            .disabled(rooms <= 1)
                            
                            Text("\(rooms)")
                                .font(.headline)
                                .frame(minWidth: 30)
                            
                            Button {
                                if rooms < 5 { rooms += 1 }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(rooms < 5 ? .blue : .gray)
                            }
                            .buttonStyle(.plain)
                            .disabled(rooms >= 5)
                        }
                    }
                }
                
                if children > 0 {
                    Section("Children's Ages") {
                        ForEach(childrenAges.indices, id: \.self) { index in
                            HStack {
                                Text("Child \(index + 1)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Picker("Age", selection: Binding(
                                    get: { childrenAges[index] },
                                    set: { childrenAges[index] = $0 }
                                )) {
                                    ForEach(0..<18) { age in
                                        Text(age == 0 ? "Under 1" : "\(age) years").tag(age)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Guests & Rooms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func syncChildrenAges() {
        if children <= 0 {
            childrenAges = []
            return
        }
        
        let targetCount = min(children, 10)
        if childrenAges.count > targetCount {
            childrenAges = Array(childrenAges.prefix(targetCount))
        } else if childrenAges.count < targetCount {
            childrenAges.append(contentsOf: Array(repeating: 5, count: targetCount - childrenAges.count))
        }
    }
}
