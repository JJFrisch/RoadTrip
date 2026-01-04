//
//  HotelFiltersSheet.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI

struct HotelFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: HotelFilters
    
    @State private var tempFilters: HotelFilters
    
    init(filters: Binding<HotelFilters>) {
        self._filters = filters
        self._tempFilters = State(initialValue: filters.wrappedValue)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Price Range
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Price Range")
                                .font(.headline)
                            Spacer()
                            if tempFilters.minPrice != nil || tempFilters.maxPrice != nil {
                                Button("Clear") {
                                    tempFilters.minPrice = nil
                                    tempFilters.maxPrice = nil
                                }
                                .font(.caption)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading) {
                                Text("Min")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("$0", value: $tempFilters.minPrice, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            Text("–")
                                .foregroundStyle(.secondary)
                            
                            VStack(alignment: .leading) {
                                Text("Max")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                TextField("No max", value: $tempFilters.maxPrice, format: .number)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        if let min = tempFilters.minPrice, let max = tempFilters.maxPrice {
                            Text("$\(Int(min)) - $\(Int(max)) per night")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let min = tempFilters.minPrice {
                            Text("From $\(Int(min)) per night")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else if let max = tempFilters.maxPrice {
                            Text("Up to $\(Int(max)) per night")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Price")
                }
                
                // Rating
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Minimum Rating")
                                .font(.headline)
                            Spacer()
                            if tempFilters.minRating != nil {
                                Button("Clear") {
                                    tempFilters.minRating = nil
                                }
                                .font(.caption)
                            }
                        }
                        
                        if let rating = tempFilters.minRating {
                            Slider(value: Binding(
                                get: { rating },
                                set: { tempFilters.minRating = $0 }
                            ), in: 1...10, step: 0.5)
                            
                            HStack {
                                ForEach(0..<5) { index in
                                    Image(systemName: Double(index) < rating / 2 ? "star.fill" : "star")
                                        .foregroundStyle(.yellow)
                                }
                                Text(String(format: "%.1f", rating))
                                    .font(.headline)
                                    .foregroundStyle(.blue)
                            }
                        } else {
                            Button("Set Minimum Rating") {
                                tempFilters.minRating = 7.0
                            }
                        }
                    }
                } header: {
                    Text("Guest Rating")
                }
                
                // Star Rating
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Minimum Stars")
                                .font(.headline)
                            Spacer()
                            if tempFilters.minStars != nil {
                                Button("Clear") {
                                    tempFilters.minStars = nil
                                }
                                .font(.caption)
                            }
                        }
                        
                        HStack(spacing: 16) {
                            ForEach(1...5, id: \.self) { stars in
                                Button {
                                    tempFilters.minStars = stars
                                } label: {
                                    VStack(spacing: 4) {
                                        HStack(spacing: 2) {
                                            ForEach(0..<stars, id: \.self) { _ in
                                                Image(systemName: "star.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .foregroundStyle(tempFilters.minStars == stars ? .yellow : .secondary)
                                        
                                        if tempFilters.minStars == stars {
                                            Circle()
                                                .fill(Color.blue)
                                                .frame(width: 6, height: 6)
                                        } else {
                                            Circle()
                                                .fill(Color.clear)
                                                .frame(width: 6, height: 6)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                } header: {
                    Text("Hotel Stars")
                }
                
                // Amenities
                Section {
                    Toggle(isOn: $tempFilters.requireWiFi) {
                        Label("Free WiFi", systemImage: "wifi")
                    }
                    
                    Toggle(isOn: $tempFilters.requireParking) {
                        Label("Free Parking", systemImage: "parkingsign")
                    }
                    
                    Toggle(isOn: $tempFilters.requireBreakfast) {
                        Label("Free Breakfast", systemImage: "cup.and.saucer.fill")
                    }
                    
                    Toggle(isOn: $tempFilters.requirePool) {
                        Label("Pool", systemImage: "figure.pool.swim")
                    }
                    
                    Toggle(isOn: $tempFilters.petFriendly) {
                        Label("Pet Friendly", systemImage: "pawprint.fill")
                    }
                } header: {
                    Text("Amenities")
                }
                
                // Sort
                Section {
                    Picker("Sort Results By", selection: $tempFilters.sortBy) {
                        ForEach(HotelFilters.SortOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Sort Order")
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        filters = tempFilters
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button("Reset All Filters") {
                        tempFilters = HotelFilters()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
}

#Preview {
    @Previewable @State var filters = HotelFilters()
    HotelFiltersSheet(filters: $filters)
}
