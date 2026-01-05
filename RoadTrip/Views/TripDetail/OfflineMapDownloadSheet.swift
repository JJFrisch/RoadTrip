//
//  OfflineMapDownloadSheet.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import SwiftUI
import MapKit

struct OfflineMapDownloadSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var mapboxManager = MapboxOfflineManager.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared

    @AppStorage("useOfflineMapsWhenOffline") private var useOfflineMapsWhenOffline: Bool = true
    
    let trip: Trip
    
    @State private var selectedRegion: MKCoordinateRegion?
    @State private var regionName: String = ""
    @State private var maxZoom: Double = 14
    @State private var showingDownloadConfirm = false
    @State private var estimatedSize: String = "Calculating..."
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if !Config.hasValidMapboxToken {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Mapbox Token Required", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.headline)
                            
                            Text("Add your Mapbox access token to Config.swift or Info.plist")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Link("Get Token →", destination: URL(string: "https://account.mapbox.com/access-tokens/")!)
                                .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if !networkMonitor.isConnected {
                        Label("No internet connection", systemImage: "wifi.slash")
                            .foregroundStyle(.red)
                        if !mapboxManager.downloadedRegions.isEmpty {
                            Toggle("Use Offline Maps", isOn: $useOfflineMapsWhenOffline)
                        }
                    } else if networkMonitor.isExpensive {
                        Label("Using cellular data - downloads may be expensive", systemImage: "antenna.radiowaves.left.and.right")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                }
                
                Section("Trip Region") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Download offline maps for your entire trip")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        TextField("Region Name", text: $regionName)
                            .textFieldStyle(.roundedBorder)
                        
                        HStack {
                            Text("Detail Level")
                            Spacer()
                            Text("Zoom \(Int(maxZoom))")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $maxZoom, in: 10...16, step: 1)
                            .onChange(of: maxZoom) { _, _ in
                                updateEstimate()
                            }
                        
                        Text("Higher zoom = more detail + larger download")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            Text("Estimated Size:")
                            Spacer()
                            Text(estimatedSize)
                                .fontWeight(.semibold)
                        }
                        
                        Button {
                            showingDownloadConfirm = true
                        } label: {
                            if mapboxManager.isDownloading {
                                HStack {
                                    ProgressView()
                                    Text("Downloading... \(Int(mapboxManager.downloadProgress * 100))%")
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                Label("Download Trip Region", systemImage: "arrow.down.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!networkMonitor.isConnected || mapboxManager.isDownloading || !Config.hasValidMapboxToken || regionName.isEmpty)
                    }
                }
                
                Section("Downloaded Regions") {
                    if mapboxManager.isDownloading, let current = mapboxManager.currentDownload {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(current.name)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text("Downloading…")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Text("\(Int(mapboxManager.downloadProgress * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }

                            ProgressView(value: mapboxManager.downloadProgress)
                        }
                        .padding(.vertical, 4)
                    }

                    if mapboxManager.downloadedRegions.isEmpty {
                        Text("No offline maps downloaded")
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        ForEach(mapboxManager.downloadedRegions) { region in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(region.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                        
                                        Text("Downloaded \(region.downloadedAt.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(formatBytes(region.sizeInBytes))
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        
                                        if region.isComplete {
                                            Label("Complete", systemImage: "checkmark.circle.fill")
                                                .font(.caption2)
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                                
                                Button(role: .destructive) {
                                    mapboxManager.deleteRegion(region)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                        .font(.caption)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Text("Total Storage Used")
                        Spacer()
                        Text(mapboxManager.getTotalStorageUsed())
                            .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Offline Maps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if regionName.isEmpty {
                    regionName = trip.name
                }
                calculateTripRegion()
                updateEstimate()
            }
            .confirmationDialog("Download Offline Map", isPresented: $showingDownloadConfirm) {
                Button("Download (\(estimatedSize))") {
                    downloadTripRegion()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will download map data for your entire trip. Make sure you have a good internet connection.")
            }
        }
    }
    
    private func calculateTripRegion() {
        // Calculate bounding box for all trip days
        var minLat = 90.0
        var maxLat = -90.0
        var minLon = 180.0
        var maxLon = -180.0
        
        for day in trip.safeDays {
            // Try to geocode start and end locations (simplified)
            // In production, cache these coordinates
            if !day.startLocation.isEmpty {
                // Would geocode here, using placeholder
                minLat = min(minLat, 40.0)
                maxLat = max(maxLat, 42.0)
                minLon = min(minLon, -75.0)
                maxLon = max(maxLon, -73.0)
            }
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.2, 0.5),
            longitudeDelta: max((maxLon - minLon) * 1.2, 0.5)
        )
        
        selectedRegion = MKCoordinateRegion(center: center, span: span)
    }
    
    private func updateEstimate() {
        guard let region = selectedRegion else {
            estimatedSize = "Unknown"
            return
        }
        estimatedSize = mapboxManager.estimateSize(for: region, maxZoom: maxZoom)
    }
    
    private func downloadTripRegion() {
        guard let region = selectedRegion else { return }
        
        Task {
            do {
                try await mapboxManager.downloadRegion(name: regionName, region: region, maxZoom: maxZoom)
            } catch {
                ErrorHandler.shared.handle(error)
            }
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb < 1 {
            return String(format: "%.0f KB", Double(bytes) / 1024)
        } else if mb < 1000 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.2f GB", mb / 1024)
        }
    }
}
