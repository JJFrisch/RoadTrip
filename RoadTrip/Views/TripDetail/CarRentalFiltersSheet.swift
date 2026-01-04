//
//  CarRentalFiltersSheet.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI

struct CarRentalFiltersSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: CarRentalFilters
    @State private var tempFilters: CarRentalFilters
    
    init(filters: Binding<CarRentalFilters>) {
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
                    }
                } header: {
                    Text("Price (Total)")
                }
                
                // Car Type
                Section {
                    let carTypes = ["Economy", "Compact", "Mid-size", "Full-size", "SUV", "Luxury", "Van"]
                    ForEach(carTypes, id: \.self) { type in
                        Toggle(type, isOn: Binding(
                            get: { tempFilters.carTypes.contains(type) },
                            set: { enabled in
                                if enabled {
                                    tempFilters.carTypes.insert(type)
                                } else {
                                    tempFilters.carTypes.remove(type)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Car Type")
                }
                
                // Transmission
                Section {
                    Picker("Transmission", selection: $tempFilters.transmissionType) {
                        Text("Any").tag(nil as CarRentalFilters.TransmissionType?)
                        ForEach(CarRentalFilters.TransmissionType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as CarRentalFilters.TransmissionType?)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Transmission")
                }
                
                // Seats
                Section {
                    Picker("Minimum Seats", selection: $tempFilters.minSeats) {
                        Text("Any").tag(nil as Int?)
                        ForEach([2, 4, 5, 7, 8], id: \.self) { seats in
                            Text("\(seats)+ seats").tag(seats as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Passengers")
                }
                
                // Features
                Section {
                    Toggle(isOn: $tempFilters.requireAirConditioning) {
                        Label("Air Conditioning", systemImage: "snowflake")
                    }
                    
                    Toggle(isOn: $tempFilters.requireGPS) {
                        Label("GPS Navigation", systemImage: "location.fill")
                    }
                    
                    Toggle(isOn: $tempFilters.requireUnlimitedMileage) {
                        Label("Unlimited Mileage", systemImage: "infinity")
                    }
                } header: {
                    Text("Features")
                }
                
                // Fuel Type
                Section {
                    let fuelTypes = ["Gasoline", "Diesel", "Electric", "Hybrid"]
                    ForEach(fuelTypes, id: \.self) { fuel in
                        Toggle(fuel, isOn: Binding(
                            get: { tempFilters.fuelTypes.contains(fuel) },
                            set: { enabled in
                                if enabled {
                                    tempFilters.fuelTypes.insert(fuel)
                                } else {
                                    tempFilters.fuelTypes.remove(fuel)
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Fuel Type")
                }
                
                // Sort
                Section {
                    Picker("Sort Results By", selection: $tempFilters.sortBy) {
                        ForEach(CarRentalFilters.SortOption.allCases, id: \.self) { option in
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
                        tempFilters = CarRentalFilters()
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }
}
