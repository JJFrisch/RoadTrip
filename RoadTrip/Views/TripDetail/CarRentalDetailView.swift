//
//  CarRentalDetailView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI
import SwiftData

struct CarRentalDetailView: View {
    let car: CarRentalSearchResult
    let trip: Trip
    let pickUpDate: Date
    let dropOffDate: Date
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    
    @State private var showingSaveConfirmation = false
    
    var rentalDays: Int {
        Calendar.current.dateComponents([.day], from: pickUpDate, to: dropOffDate).day ?? 1
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Car Image
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
                                            .font(.system(size: 60))
                                            .foregroundStyle(.secondary)
                                    }
                            @unknown default:
                                Rectangle()
                                    .fill(Color(.systemGray5))
                            }
                        }
                        .frame(height: 250)
                    } else {
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .aspectRatio(16/9, contentMode: .fill)
                            .overlay {
                                Image(systemName: "car.fill")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(height: 250)
                    }
                    
                    // Car Details
                    VStack(alignment: .leading, spacing: 16) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(car.carName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(car.company) • \(car.carType)")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            if let rating = car.rating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                    Text(String(format: "%.1f", rating))
                                        .fontWeight(.semibold)
                                    if let reviewCount = car.reviewCount {
                                        Text("(\(reviewCount) reviews)")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .font(.subheadline)
                            }
                        }
                        
                        Divider()
                        
                        // Specs
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Vehicle Specifications")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], alignment: .leading, spacing: 12) {
                                SpecRow(icon: "person.2.fill", label: "Passengers", value: "\(car.seats)")
                                SpecRow(icon: "door.left.hand.closed", label: "Doors", value: "\(car.doors)")
                                SpecRow(icon: "gearshape.fill", label: "Transmission", value: car.transmission)
                                SpecRow(icon: "fuelpump.fill", label: "Fuel", value: car.fuelType)
                            }
                        }
                        
                        Divider()
                        
                        // Features
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Features & Amenities")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                if car.hasAirConditioning {
                                    CarRentalFeatureRow(icon: "snowflake", text: "Air Conditioning")
                                }
                                if car.hasGPS {
                                    CarRentalFeatureRow(icon: "location.fill", text: "GPS Navigation")
                                }
                                if car.hasUnlimitedMileage {
                                    CarRentalFeatureRow(icon: "infinity", text: "Unlimited Mileage")
                                }
                                ForEach(car.features, id: \.self) { feature in
                                    CarRentalFeatureRow(icon: "checkmark.circle.fill", text: feature)
                                }
                            }
                        }
                        
                        Divider()
                        
                        // Pricing
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Pricing")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Daily Rate")
                                    Spacer()
                                    Text("$\(Int(car.pricePerDay))")
                                        .fontWeight(.semibold)
                                }
                                
                                HStack {
                                    Text("Rental Period")
                                    Spacer()
                                    Text("\(rentalDays) day\(rentalDays == 1 ? "" : "s")")
                                        .foregroundStyle(.secondary)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Total Price")
                                        .font(.headline)
                                    Spacer()
                                    Text("$\(Int(car.totalPrice))")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        Divider()
                        
                        // Rental Period
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Rental Period")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Pick-up")
                                    Spacer()
                                    Text(pickUpDate.formatted(date: .abbreviated, time: .omitted))
                                }
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Drop-off")
                                    Spacer()
                                    Text(dropOffDate.formatted(date: .abbreviated, time: .omitted))
                                }
                            }
                            .font(.subheadline)
                        }
                        
                        // Book Button
                        Button {
                            if let url = URL(string: car.bookingURL) {
                                openURL(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "arrow.up.right")
                                Text("Book on \(car.company)")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Car Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        saveCarRentalToTrip()
                    } label: {
                        Label("Add to Trip", systemImage: "plus.circle.fill")
                    }
                }
            }
            .alert("Car Rental Added", isPresented: $showingSaveConfirmation) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("\(car.carName) has been added to your trip.")
            }
        }
    }
    
    private func saveCarRentalToTrip() {
        // Find first day for pick-up location
        guard let firstDay = trip.safeDays.sorted(by: { $0.dayNumber < $1.dayNumber }).first else { return }
        
        // Create car rental activity
        let rentalActivity = Activity(
            name: "🚗 \(car.carName) Rental",
            location: firstDay.startLocation,
            category: "transportation"
        )
        
        rentalActivity.scheduledTime = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: pickUpDate)
        rentalActivity.duration = 0.5 // 30 minutes for pickup
        rentalActivity.estimatedCost = car.totalPrice
        rentalActivity.costCategory = "Transportation"
        rentalActivity.notes = "Pick up: \(car.company)\nCar: \(car.carName)\n\(car.transmission) • \(car.seats) seats"
        rentalActivity.isMultiDay = true
        rentalActivity.endDate = dropOffDate
        
        firstDay.activities?.append(rentalActivity)
        
        showingSaveConfirmation = true
    }
}

struct SpecRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
    }
}

struct CarRentalFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.green)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}
