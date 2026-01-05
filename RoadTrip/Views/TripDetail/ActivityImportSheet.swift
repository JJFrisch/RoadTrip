//
//  ActivityImportSheet.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI
import SwiftData
import MapKit

struct ActivityImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    let day: TripDay
    @StateObject private var viewModel = TripDetailViewModel()
    
    @State private var importMode: ImportMode = .url
    @State private var urlString: String = ""
    @State private var searchRadius: Double = 2000
    @State private var isImporting = false
    @State private var importedPlaces: [ActivityImporter.ImportedPlace] = []
    @State private var selectedPlaces: Set<String> = []
    @State private var errorMessage: String?
    
    enum ImportMode: String, CaseIterable {
        case url = "From URL"
        case nearby = "Nearby POIs"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Mode Picker
                Picker("Import Mode", selection: $importMode) {
                    ForEach(ImportMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                if importMode == .url {
                    urlImportView
                } else {
                    nearbyImportView
                }
                
                if !importedPlaces.isEmpty {
                    previewList
                }
            }
            .navigationTitle("Import Activities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Selected") {
                        addSelectedActivities()
                    }
                    .disabled(selectedPlaces.isEmpty)
                }
            }
            .alert("Import Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var urlImportView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Paste URL from TripAdvisor or Google Maps")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                TextField("https://www.tripadvisor.com/...", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                HStack(spacing: 12) {
                    Button {
                        importFromURL()
                    } label: {
                        if isImporting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Import", systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(urlString.isEmpty || isImporting)
                    
                    Button {
                        urlString = ""
                        importedPlaces = []
                        selectedPlaces = []
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .buttonStyle(.bordered)
                    .disabled(urlString.isEmpty && importedPlaces.isEmpty)
                }
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Label("TripAdvisor: Copy URL from attraction list or search results", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("Google Maps: Copy URL from saved lists or search results", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("Import is best-effort and may not capture all details", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private var nearbyImportView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Find popular attractions near \(day.endLocation)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text("Search Radius")
                    Spacer()
                    Text("\(Int(searchRadius))m")
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: $searchRadius, in: 500...10000, step: 500)
                
                Button {
                    importNearby()
                } label: {
                    if isImporting {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Search Nearby", systemImage: "location.magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isImporting)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("How it works")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Label("Uses MapKit to find nearby points of interest", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Label("Results depend on Apple Maps data availability", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Spacer()
        }
    }
    
    private var previewList: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Found \(importedPlaces.count) place\(importedPlaces.count == 1 ? "" : "s")")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
                
                Button {
                    if selectedPlaces.count == importedPlaces.count {
                        selectedPlaces = []
                    } else {
                        selectedPlaces = Set(importedPlaces.map { $0.name })
                    }
                } label: {
                    Text(selectedPlaces.count == importedPlaces.count ? "Deselect All" : "Select All")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            List(importedPlaces, id: \.name) { place in
                HStack(spacing: 12) {
                    Button {
                        toggleSelection(place.name)
                    } label: {
                        Image(systemName: selectedPlaces.contains(place.name) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedPlaces.contains(place.name) ? .blue : .gray)
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if let address = place.address {
                            Text(address)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        
                        HStack(spacing: 12) {
                            if let category = place.category {
                                Label(category, systemImage: "tag")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let duration = place.typicalDurationHours {
                                Label("\(String(format: "%.1f", duration))h", systemImage: "clock")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let rating = place.rating {
                                Label("\(String(format: "%.1f", rating))", systemImage: "star.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.yellow)
                            }
                        }

                        if let blurb = place.blurb, !blurb.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text(blurb)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        if let website = place.website,
                           let url = URL(string: website) {
                            Link(website.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""), destination: url)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleSelection(place.name)
                }
            }
        }
    }
    
    private func toggleSelection(_ name: String) {
        if selectedPlaces.contains(name) {
            selectedPlaces.remove(name)
        } else {
            selectedPlaces.insert(name)
        }
    }
    
    private func importFromURL() {
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespaces)) else {
            errorMessage = "Invalid URL"
            return
        }
        
        isImporting = true
        errorMessage = nil
        
        Task {
            do {
                let activities = try await viewModel.importActivities(from: url, baseActivityIndex: day.activities.count, modelContext: modelContext)
                
                await MainActor.run {
                    // Convert to ImportedPlace for preview
                    importedPlaces = activities.map { activity in
                        ActivityImporter.ImportedPlace(
                            name: activity.name,
                            address: activity.location,
                            rating: nil,
                            coordinate: nil,
                            category: activity.category,
                            typicalDurationHours: activity.duration,
                            blurb: activity.notes,
                            website: activity.website,
                            phoneNumber: activity.phoneNumber,
                            types: nil
                        )
                    }
                    
                    // Select all by default
                    selectedPlaces = Set(importedPlaces.map { $0.name })
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to import: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
    
    private func importNearby() {
        isImporting = true
        errorMessage = nil
        
        Task {
            do {
                // Geocode day's end location to get coordinate
                let geocoder = CLGeocoder()
                
                let placemarks = try await geocoder.geocodeAddressString(day.endLocation)
                
                guard let coordinate = placemarks.first?.location?.coordinate else {
                    await MainActor.run {
                        errorMessage = "Could not find location: '\(day.endLocation)'. Please set the destination for this day."
                        isImporting = false
                    }
                    return
                }
                
                // Use Google Places API for better results
                let places = try await viewModel.importActivitiesFromGooglePlaces(
                    near: coordinate,
                    baseActivityIndex: day.activities.count,
                    modelContext: modelContext,
                    radius: searchRadius
                )
                
                await MainActor.run {
                    // Convert to ImportedPlace for preview
                    importedPlaces = places.map { activity in
                        ActivityImporter.ImportedPlace(
                            name: activity.name,
                            address: activity.location,
                            rating: activity.rating,
                            coordinate: activity.hasCoordinates ? CLLocationCoordinate2D(latitude: activity.latitude!, longitude: activity.longitude!) : nil,
                            category: activity.category,
                            typicalDurationHours: activity.duration,
                            placeId: activity.placeId,
                            photoURL: activity.photoURL,
                            blurb: activity.notes,
                            website: activity.website,
                            phoneNumber: activity.phoneNumber,
                            types: nil
                        )
                    }
                    
                    selectedPlaces = Set(places.map { $0.name })
                    isImporting = false
                }
            } catch let error as AppError {
                await MainActor.run {
                    errorMessage = error.errorDescription ?? "Failed to search nearby"
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to search nearby: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
    
    private func addSelectedActivities() {
        let selected = importedPlaces.filter { selectedPlaces.contains($0.name) }
        
        for (index, place) in selected.enumerated() {
            let activity = Activity(name: place.name, location: place.address ?? day.endLocation, category: place.category ?? "Attraction")
            activity.duration = place.typicalDurationHours
            activity.order = day.activities.count + index
            activity.isCompleted = true
            
            // Use enhanced fields instead of notes
            if let coord = place.coordinate {
                activity.latitude = coord.latitude
                activity.longitude = coord.longitude
            }
            activity.placeId = place.placeId
            activity.sourceType = "google"
            activity.importedAt = Date()
            activity.rating = place.rating
            activity.photoURL = place.photoURL
            activity.website = place.website
            activity.phoneNumber = place.phoneNumber
            
            modelContext.insert(activity)
            day.activities.append(activity)
        }
        
        dismiss()
    }
}
