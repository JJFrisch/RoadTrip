//
//  HotelSourceSettingsSheet.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI

struct HotelSourceSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var preferences: HotelPreferences
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Select which booking sites to search when looking for hotels. More sources mean more options but slower searches.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Search Sources")
                }
                
                Section {
                    ForEach(HotelSearchResult.BookingSource.allCases.filter { $0 != .direct }, id: \.self) { source in
                        Toggle(isOn: Binding(
                            get: { preferences.enabledSources.contains(source.rawValue) },
                            set: { enabled in
                                if enabled {
                                    if !preferences.enabledSources.contains(source.rawValue) {
                                        preferences.enabledSources.append(source.rawValue)
                                    }
                                } else {
                                    preferences.enabledSources.removeAll { $0 == source.rawValue }
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: sourceIcon(source))
                                    .foregroundStyle(sourceColor(source))
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(source.rawValue)
                                        .font(.headline)
                                    Text(sourceDescription(source))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Booking Sites")
                } footer: {
                    Text("At least one source must be enabled")
                        .font(.caption)
                }
                
                Section {
                    HStack {
                        Text("Enabled Sources")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(preferences.enabledSources.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Search Speed")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(searchSpeed)
                            .fontWeight(.semibold)
                            .foregroundStyle(searchSpeedColor)
                    }
                } header: {
                    Text("Summary")
                }
            }
            .navigationTitle("Booking Sites")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Ensure at least one source is enabled
                        if preferences.enabledSources.isEmpty {
                            preferences.enabledSources = ["Booking.com"]
                        }
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func sourceIcon(_ source: HotelSearchResult.BookingSource) -> String {
        switch source {
        case .booking: return "b.circle.fill"
        case .hotels: return "h.circle.fill"
        case .expedia: return "e.circle.fill"
        case .airbnb: return "house.fill"
        case .direct: return "globe"
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
    
    private func sourceDescription(_ source: HotelSearchResult.BookingSource) -> String {
        switch source {
        case .booking: return "Wide selection of hotels worldwide"
        case .hotels: return "Rewards program and member prices"
        case .expedia: return "Bundle deals with flights"
        case .airbnb: return "Homes and unique stays"
        case .direct: return "Book directly with hotels"
        }
    }
    
    private var searchSpeed: String {
        switch preferences.enabledSources.count {
        case 1: return "Fast"
        case 2: return "Medium"
        case 3: return "Slower"
        default: return "Slowest"
        }
    }
    
    private var searchSpeedColor: Color {
        switch preferences.enabledSources.count {
        case 1: return .green
        case 2: return .orange
        default: return .red
        }
    }
}

#Preview {
    let preferences = HotelPreferences()
    HotelSourceSettingsSheet(preferences: preferences)
}
