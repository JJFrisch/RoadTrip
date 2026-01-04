//
//  HotelDetailView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI
import SwiftData
import MapKit

struct HotelDetailView: View {
    let hotel: HotelSearchResult
    let day: TripDay
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    
    @State private var showingSaveConfirmation = false
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    imageCarousel
                    hotelDetailsSection
                }
            }
            .navigationTitle("Hotel Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        saveHotelToDay()
                    } label: {
                        Label("Add to Day", systemImage: "plus.circle.fill")
                    }
                }
            }
            .alert("Hotel Added", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("\(hotel.name) has been added to your trip itinerary.")
            }
        }
    }
    
    private var imageCarousel: some View {
        TabView(selection: $selectedImageIndex) {
            ForEach(0..<max(hotel.imageURLs.count, 1), id: \.self) { index in
                if !hotel.imageURLs.isEmpty, let url = URL(string: hotel.imageURLs[index]) {
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
                    .tag(index)
                } else {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                        .tag(index)
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(height: 250)
    }
    
    private var hotelDetailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Hotel Header
            VStack(alignment: .leading, spacing: 12) {
                // Name and Rating
                VStack(alignment: .leading, spacing: 6) {
                    Text(hotel.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 12) {
                        // Stars
                        if let stars = hotel.starRating {
                            HStack(spacing: 2) {
                                ForEach(0..<stars, id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                        
                        // Rating
                        if let rating = hotel.rating {
                            HStack(spacing: 4) {
                                Text(String(format: "%.1f", rating))
                                    .font(.headline)
                        }
                    }
                }
                
                // Review Count
                if let count = hotel.reviewCount {
                    Text("(\(count) reviews)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        // Address
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "location.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 2) {
                Text(hotel.address)
                Text("\(hotel.city), \(hotel.country)")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        
        Divider()
        
        // Price
        if let price = hotel.pricePerNight {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("$\(Int(price))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.green)
                    Text("per night")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                
                                if let total = hotel.totalPrice {
                                    Text("Total: $\(Int(total))")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Description
                    if let description = hotel.description {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About")
                                .font(.headline)
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        
                        Divider()
                    }
                    
                    // Amenities
                    if !hotel.amenities.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Amenities")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], alignment: .leading, spacing: 12) {
                                ForEach(hotel.amenities, id: \.self) { amenity in
                                    HStack(spacing: 8) {
                                        Image(systemName: amenityIcon(amenity))
                                            .foregroundStyle(.blue)
                                            .frame(width: 20)
                                        Text(amenity)
                                            .font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding()
                        
                        Divider()
                    }
                    
                    // Map
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                        
                        Map(initialPosition: .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(
                                latitude: hotel.latitude,
                                longitude: hotel.longitude
                            ),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))) {
                            Marker(hotel.name, coordinate: CLLocationCoordinate2D(
                                latitude: hotel.latitude,
                                longitude: hotel.longitude
                            ))
                            .tint(.red)
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .allowsHitTesting(false)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Booking Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Book This Hotel")
                            .font(.headline)
                        
                        // Source Button
                        Button {
                            if let url = URL(string: hotel.bookingURL) {
                                openURL(url)
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Book on \(hotel.source.rawValue)")
                                        .font(.headline)
                                    Text("Opens in Safari")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.right")
                            }
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(sourceColor(hotel.source))
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
        }
    
    private func saveHotelToDay() {
        // Convert search result to Hotel model
        let newHotel = hotel.toHotel()
        modelContext.insert(newHotel)
        
        // Add hotel as activity to the day
        let hotelActivity = Activity(
            name: "🏨 \(hotel.name)",
            location: hotel.address,
            category: "Hotel"
        )
        hotelActivity.scheduledTime = Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: day.date) ?? day.date
        hotelActivity.duration = 20.0 // 20 hours (check-in to check-out)
        hotelActivity.estimatedCost = hotel.totalPrice ?? hotel.pricePerNight ?? 0
        hotelActivity.latitude = hotel.latitude
        hotelActivity.longitude = hotel.longitude
        hotelActivity.rating = hotel.rating
        hotelActivity.sourceType = "booking"
        
        day.activities.append(hotelActivity)
        
        showingSaveConfirmation = true
    }
    
    private func ratingColor(_ rating: Double) -> Color {
        switch rating {
        case 9...: return .green
        case 8..<9: return .blue
        case 7..<8: return .orange
        default: return .red
        }
    }
    
    private func ratingText(_ rating: Double) -> String {
        switch rating {
        case 9...: return "Exceptional"
        case 8..<9: return "Excellent"
        case 7..<8: return "Good"
        case 6..<7: return "Fair"
        default: return "Poor"
        }
    }
    
    private func sourceColor(_ source: HotelSearchResult.BookingSource) -> Color {
        switch source {
        case .booking: return .blue
        case .hotels: return .red
        case .expedia: return .yellow
        case .airbnb: return .pink
        case .direct: return .green
        }
    }
    
    private func amenityIcon(_ amenity: String) -> String {
        let lower = amenity.lowercased()
        if lower.contains("wifi") || lower.contains("internet") {
            return "wifi"
        } else if lower.contains("parking") {
            return "parkingsign"
        } else if lower.contains("pool") {
            return "figure.pool.swim"
        } else if lower.contains("gym") || lower.contains("fitness") {
            return "figure.run"
        } else if lower.contains("breakfast") {
            return "cup.and.saucer.fill"
        } else if lower.contains("restaurant") {
            return "fork.knife"
        } else if lower.contains("bar") {
            return "wineglass"
        } else if lower.contains("spa") {
            return "sparkles"
        } else if lower.contains("ac") || lower.contains("air") {
            return "snowflake"
        } else if lower.contains("pet") {
            return "pawprint.fill"
        } else if lower.contains("shuttle") {
            return "bus"
        } else if lower.contains("business") {
            return "briefcase.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }
}

#Preview {
    let hotel = HotelSearchResult(
        id: "1",
        name: "Grand Plaza Hotel",
        address: "123 Main Street",
        city: "San Francisco",
        state: "CA",
        country: "USA",
        latitude: 37.7749,
        longitude: -122.4194,
        rating: 8.5,
        reviewCount: 1234,
        starRating: 4,
        thumbnailURL: nil,
        imageURLs: [],
        pricePerNight: 199,
        totalPrice: 597,
        currency: "USD",
        amenities: ["Free WiFi", "Pool", "Gym", "Restaurant", "Free Parking", "Pet Friendly"],
        description: "Experience luxury in the heart of San Francisco. Our hotel features modern rooms, exceptional dining, and stunning city views.",
        bookingURL: "https://booking.com",
        source: .booking
    )
    
    let day = TripDay(
        dayNumber: 1,
        date: Date(),
        startLocation: "San Francisco",
        endLocation: "San Francisco"
    )
    
    HotelDetailView(hotel: hotel, day: day)
        .modelContainer(for: [Trip.self, TripDay.self, Activity.self, Hotel.self])
}
