//
//  MapboxOfflineManager.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation
import MapKit

// NOTE: This is a placeholder implementation for Mapbox integration
// To use this, you need to:
// 1. Add Mapbox SDK via SPM: https://github.com/mapbox/mapbox-maps-ios
// 2. Add the following to your Package.swift dependencies:
//    .package(url: "https://github.com/mapbox/mapbox-maps-ios.git", from: "11.0.0")
// 3. Import MapboxMaps framework
// 4. Uncomment the actual Mapbox code below

import CoreLocation

final class MapboxOfflineManager: ObservableObject {
    static let shared = MapboxOfflineManager()
    
    @Published var downloadedRegions: [OfflineRegion] = []
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var currentDownload: OfflineRegion?
    
    struct OfflineRegion: Identifiable, Codable {
        let id: String
        let name: String
        let center: Coordinate
        let bounds: Bounds
        let downloadedAt: Date
        var sizeInBytes: Int64
        var isComplete: Bool
        
        struct Coordinate: Codable {
            let latitude: Double
            let longitude: Double
        }
        
        struct Bounds: Codable {
            let north: Double
            let south: Double
            let east: Double
            let west: Double
        }
    }
    
    private let userDefaultsKey = "com.roadtrip.offlineRegions"
    
    private init() {
        loadRegions()
    }
    
    // MARK: - Public Methods
    
    /// Download an offline map region
    /// - Parameters:
    ///   - name: Name for the region
    ///   - region: The map region to download
    ///   - minZoom: Minimum zoom level (default: 0)
    ///   - maxZoom: Maximum zoom level (default: 16, higher = more detail + larger size)
    func downloadRegion(name: String, region: MKCoordinateRegion, minZoom: Double = 0, maxZoom: Double = 16) async throws {
        guard Config.hasValidMapboxToken else {
            throw AppError.invalidAPIKey
        }
        
        guard NetworkMonitor.shared.isConnected else {
            throw AppError.networkUnavailable
        }
        
        if NetworkMonitor.shared.isExpensive {
            // Warn user about cellular download
            print("Warning: Downloading on cellular connection")
        }
        
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
        }
        
        // Create region metadata
        let offlineRegion = OfflineRegion(
            id: UUID().uuidString,
            name: name,
            center: OfflineRegion.Coordinate(latitude: region.center.latitude, longitude: region.center.longitude),
            bounds: OfflineRegion.Bounds(
                north: region.center.latitude + region.span.latitudeDelta / 2,
                south: region.center.latitude - region.span.latitudeDelta / 2,
                east: region.center.longitude + region.span.longitudeDelta / 2,
                west: region.center.longitude - region.span.longitudeDelta / 2
            ),
            downloadedAt: Date(),
            sizeInBytes: 0,
            isComplete: false
        )
        
        await MainActor.run {
            currentDownload = offlineRegion
        }
        
        /* 
         ACTUAL MAPBOX IMPLEMENTATION (Uncomment when SDK is added):
         
         import MapboxMaps
         
         let styleURI = StyleURI.streets // or .outdoors, .satellite, etc.
         let resourceOptions = ResourceOptions(accessToken: Config.mapboxAccessToken)
         let tilePyramid = TilePyramid(
             bounds: CoordinateBounds(
                 southwest: CLLocationCoordinate2D(latitude: offlineRegion.bounds.south, longitude: offlineRegion.bounds.west),
                 northeast: CLLocationCoordinate2D(latitude: offlineRegion.bounds.north, longitude: offlineRegion.bounds.east)
             ),
             minZoom: UInt8(minZoom),
             maxZoom: UInt8(maxZoom)
         )
         
         let tileStore = TileStore.default
         let tileRegionId = offlineRegion.id
         
         let tilesetDescriptorOptions = TilesetDescriptorOptions(
             styleURI: styleURI,
             zoomRange: UInt8(minZoom)...UInt8(maxZoom),
             tilesets: nil
         )
         
         let tilesetDescriptor = offlineManager.createTilesetDescriptor(for: tilesetDescriptorOptions)
         
         let loadOptions = TileRegionLoadOptions(
             geometry: .polygon(Polygon([tilePyramid.bounds.coordinates])),
             descriptors: [tilesetDescriptor],
             metadata: ["name": name],
             acceptExpired: true
         )
         
         // Start download
         let cancellable = tileStore.loadTileRegion(forId: tileRegionId, loadOptions: loadOptions) { progress in
             Task { @MainActor in
                 self.downloadProgress = Double(progress.completedResourceCount) / Double(progress.requiredResourceCount)
             }
         } completion: { result in
             Task { @MainActor in
                 switch result {
                 case .success(let region):
                     var updatedRegion = offlineRegion
                     updatedRegion.isComplete = true
                     updatedRegion.sizeInBytes = region.completedResourceSize
                     self.downloadedRegions.append(updatedRegion)
                     self.saveRegions()
                     self.isDownloading = false
                     self.currentDownload = nil
                 case .failure(let error):
                     self.isDownloading = false
                     self.currentDownload = nil
                     throw AppError.unknown(error)
                 }
             }
         }
         */
        
        // PLACEHOLDER: Simulate download
        for i in 1...100 {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            await MainActor.run {
                downloadProgress = Double(i) / 100.0
            }
        }
        
        // Mark as complete
        var completedRegion = offlineRegion
        completedRegion.isComplete = true
        completedRegion.sizeInBytes = Int64.random(in: 5_000_000...50_000_000) // Placeholder size
        
        let regionToAdd = completedRegion
        await MainActor.run {
            downloadedRegions.append(regionToAdd)
            saveRegions()
            isDownloading = false
            currentDownload = nil
        }
    }
    
    func deleteRegion(_ region: OfflineRegion) {
        /*
         ACTUAL MAPBOX IMPLEMENTATION:
         
         let tileStore = TileStore.default
         tileStore.removeTileRegion(forId: region.id)
         */
        
        downloadedRegions.removeAll { $0.id == region.id }
        saveRegions()
    }
    
    func estimateSize(for region: MKCoordinateRegion, maxZoom: Double = 16) -> String {
        // Rough estimation based on zoom level and area
        let area = region.span.latitudeDelta * region.span.longitudeDelta
        let zoomFactor = pow(4.0, maxZoom - 10) // Each zoom level ~4x more tiles
        let estimatedMB = area * zoomFactor * 0.5
        
        if estimatedMB < 1 {
            return String(format: "%.0f KB", estimatedMB * 1024)
        } else if estimatedMB < 1000 {
            return String(format: "%.1f MB", estimatedMB)
        } else {
            return String(format: "%.2f GB", estimatedMB / 1024)
        }
    }
    
    // MARK: - Persistence
    
    private func loadRegions() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let regions = try? JSONDecoder().decode([OfflineRegion].self, from: data) {
            downloadedRegions = regions
        }
    }
    
    private func saveRegions() {
        if let data = try? JSONEncoder().encode(downloadedRegions) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    func getTotalStorageUsed() -> String {
        let totalBytes = downloadedRegions.reduce(0) { $0 + $1.sizeInBytes }
        let mb = Double(totalBytes) / 1_048_576
        
        if mb < 1 {
            return String(format: "%.0f KB", Double(totalBytes) / 1024)
        } else if mb < 1000 {
            return String(format: "%.1f MB", mb)
        } else {
            return String(format: "%.2f GB", mb / 1024)
        }
    }
}
