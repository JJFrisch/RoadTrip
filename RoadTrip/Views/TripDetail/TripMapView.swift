// Views/TripDetail/TripMapView.swift
import SwiftUI
import MapKit

struct TripMapView: View {
    let trip: Trip
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var offlineManager = MapboxOfflineManager.shared

    @AppStorage("useOfflineMapsWhenOffline") private var useOfflineMapsWhenOffline: Bool = true
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
    ))
    @State private var annotations: [TripLocationAnnotation] = []
    @State private var routeCoordinates: [CLLocationCoordinate2D] = []
    @State private var selectedAnnotation: TripLocationAnnotation?
    @State private var isLoading = true
    @State private var hasError = false
    @State private var showingLocationDetail: TripLocationAnnotation?
    @State private var isRefreshing = false

    // Dark mode adaptive route color
    private var routeColor: Color {
        colorScheme == .dark 
            ? Color(red: 0.4, green: 0.7, blue: 1.0) 
            : Color.blue
    }

    var body: some View {
        ZStack {
            Map(position: $position, selection: $selectedAnnotation) {
                // Draw blue route line connecting all locations in order
                if routeCoordinates.count >= 2 {
                    MapPolyline(coordinates: routeCoordinates)
                        .stroke(routeColor, lineWidth: 4)
                }
                
                ForEach(annotations, id: \.id) { annotation in
                    Annotation("", coordinate: annotation.coordinate) {
                        LocationMapMarker(location: annotation.location, isSelected: selectedAnnotation?.id == annotation.id, colorScheme: colorScheme)
                            .onTapGesture {
                                selectedAnnotation = annotation
                                showingLocationDetail = annotation
                            }
                    }
                }
            }
            .mapStyle(.standard)
            
            VStack {
                HStack {
                    Text("Trip Route")
                        .font(.headline)
                        .padding()
                    
                    Spacer()
                    
                    if isLoading || isRefreshing {
                        ProgressView()
                            .padding()
                    }
                    
                    // Pull-to-refresh button
                    Button {
                        refreshRoutes()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundStyle(colorScheme == .dark ? .white : .blue)
                    }
                    .disabled(isRefreshing)
                    .padding(.trailing)
                }
                .background(.ultraThinMaterial)
                
                Spacer()
                
                if hasError {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                        Text("Unable to load map locations")
                            .font(.caption)
                        Button("Retry") {
                            refreshRoutes()
                        }
                        .buttonStyle(.bordered)
                    }
                    .foregroundStyle(.secondary)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding()
                }
                
                if !annotations.isEmpty {
                    VStack(spacing: 8) {
                        Text("\(annotations.count) locations on map")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button(action: zoomToFitAllLocations) {
                            Label("Fit All Locations", systemImage: "rectangle.portrait.arrowtriangle.2.outward")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                    .padding()
                }

                if !networkMonitor.isConnected, useOfflineMapsWhenOffline, !offlineManager.downloadedRegions.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.map")
                        Text("Offline maps enabled")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom)
                }
            }
        }
        .onAppear {
            fetchLocations()
        }
        .sheet(item: $showingLocationDetail) { location in
            LocationDetailSheet(
                location: location.location,
                coordinate: location.coordinate,
                onCenterOnMap: { centerMap(on: location.coordinate) }
            )
        }
        .refreshable {
            await refreshRoutesAsync()
        }
    }
    
    private func refreshRoutes() {
        isRefreshing = true
        fetchLocations()
    }
    
    @MainActor
    private func refreshRoutesAsync() async {
        isRefreshing = true
        // Wait a bit for visual feedback
        try? await Task.sleep(nanoseconds: 500_000_000)
        fetchLocations()
    }

    private func fetchLocations() {
        isLoading = true
        hasError = false
        annotations.removeAll()
        routeCoordinates.removeAll()
        
        var locations: [TripLocation] = []

        // Collect all locations across the entire trip.
        // Order is day start -> activities -> day end for each day.
        let sortedDays = trip.days.sorted(by: { $0.dayNumber < $1.dayNumber })
        for (dayIndex, day) in sortedDays.enumerated() {
            let base = dayIndex * 1000

            locations.append(
                TripLocation(
                    title: day.startLocation,
                    subtitle: "Day \(day.dayNumber) - Start",
                    type: .dayStart,
                    dayNumber: day.dayNumber,
                    orderIndex: base
                )
            )

            let sortedActivities = day.activities.sorted { a, b in
                switch (a.scheduledTime, b.scheduledTime) {
                case let (ta?, tb?): return ta < tb
                case (_?, nil): return true
                case (nil, _?): return false
                default: return a.order < b.order
                }
            }

            for (activityIndex, activity) in sortedActivities.enumerated() {
                let trimmed = activity.location.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }

                locations.append(
                    TripLocation(
                        title: trimmed,
                        subtitle: "Day \(day.dayNumber) - \(activity.name)",
                        type: .activity,
                        dayNumber: day.dayNumber,
                        orderIndex: base + 100 + activityIndex
                    )
                )
            }

            locations.append(
                TripLocation(
                    title: day.endLocation,
                    subtitle: "Day \(day.dayNumber) - End",
                    type: .dayEnd,
                    dayNumber: day.dayNumber,
                    orderIndex: base + 999
                )
            )
        }

        // Remove duplicate consecutive locations (e.g., Day 1 end = Day 2 start)
        var uniqueLocations: [TripLocation] = []
        for location in locations {
            let key = canonicalLocationKey(location.title)
            if uniqueLocations.last.map({ canonicalLocationKey($0.title) }) != key {
                uniqueLocations.append(location)
            }
        }

        // Geocode unique titles once, then apply coordinates back to each location instance.
        let groupedByKey = Dictionary(grouping: uniqueLocations) { canonicalLocationKey($0.title) }
        
        let group = DispatchGroup()
        var tempAnnotations: [(TripLocation, CLLocationCoordinate2D)] = []
        let lock = NSLock()
        
        for (key, groupedLocations) in groupedByKey {
            guard let title = groupedLocations.first?.title else { continue }

            if let placemark = LocationCache.shared.getCachedPlacemark(for: title) {
                lock.lock()
                for loc in groupedLocations {
                    tempAnnotations.append((loc, placemark.coordinate))
                }
                lock.unlock()
                continue
            }

            group.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = title
            let search = MKLocalSearch(request: request)

            search.start { response, error in
                defer { group.leave() }

                if let item = response?.mapItems.first {
                    let coordinate = item.placemark.coordinate
                    LocationCache.shared.cachePlacemark(item.placemark, for: title)
                    lock.lock()
                    for loc in groupedLocations {
                        tempAnnotations.append((loc, coordinate))
                    }
                    lock.unlock()
                }
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            isRefreshing = false
            
            if tempAnnotations.isEmpty {
                hasError = true
            } else {
                // Sort by order index to maintain route order
                let sorted = tempAnnotations.sorted { $0.0.orderIndex < $1.0.orderIndex }
                
                // Create annotations
                annotations = sorted.map { TripLocationAnnotation(location: $0.0, coordinate: $0.1) }
                
                // Create route coordinates in order
                routeCoordinates = sorted.map { $0.1 }
                
                zoomToFitAllLocations()
            }
        }
    }

    private func canonicalLocationKey(_ title: String) -> String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut(duration: 0.4)) {
            position = .region(
                MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
                )
            )
        }
    }
    
    private func zoomToFitAllLocations() {
        guard !annotations.isEmpty else { return }
        
        let coordinates = annotations.map { $0.coordinate }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.5),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.5)
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            position = .region(MKCoordinateRegion(center: center, span: span))
        }
    }
}

struct TripLocation: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let type: LocationType
    let dayNumber: Int
    let orderIndex: Int // For maintaining route order
    
    enum LocationType {
        case dayStart
        case dayEnd
        case activity
    }
}

struct TripLocationAnnotation: Identifiable, Hashable {
    let id: UUID
    let location: TripLocation
    let coordinate: CLLocationCoordinate2D
    
    init(location: TripLocation, coordinate: CLLocationCoordinate2D) {
        self.id = UUID()
        self.location = location
        self.coordinate = coordinate
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: TripLocationAnnotation, rhs: TripLocationAnnotation) -> Bool {
        lhs.id == rhs.id
    }
}

struct LocationMapMarker: View {
    let location: TripLocation
    let isSelected: Bool
    var colorScheme: ColorScheme = .light
    
    var markerColor: Color {
        switch location.type {
        case .dayStart: 
            return colorScheme == .dark 
                ? Color(red: 0.4, green: 0.9, blue: 0.5) 
                : .green
        case .dayEnd: 
            return colorScheme == .dark 
                ? Color(red: 1.0, green: 0.4, blue: 0.4) 
                : .red
        case .activity:
            return colorScheme == .dark
                ? Color(red: 0.4, green: 0.7, blue: 1.0)
                : .blue
        }
    }
    
    var markerIcon: String {
        switch location.type {
        case .dayStart: return "location.circle"
        case .dayEnd: return "mappin.circle"
        case .activity: return "star.circle"
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .shadow(color: markerColor.opacity(0.5), radius: colorScheme == .dark ? 6 : 0)
                
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                
                Image(systemName: markerIcon)
                    .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            if isSelected {
                VStack(spacing: 2) {
                    Text(location.title)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(location.subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(4)
            }
        }
        .transition(.scale)
    }
}

struct LocationDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let location: TripLocation
    let coordinate: CLLocationCoordinate2D
    let onCenterOnMap: () -> Void
    
    var markerColor: Color {
        switch location.type {
        case .dayStart: return .green
        case .dayEnd: return .red
        case .activity: return .blue
        }
    }
    
    var markerIcon: String {
        switch location.type {
        case .dayStart: return "location.circle"
        case .dayEnd: return "mappin.circle"
        case .activity: return "star.circle"
        }
    }
    
    var typeLabel: String {
        switch location.type {
        case .dayStart: return "Day Start"
        case .dayEnd: return "Day End"
        case .activity: return "Activity"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Location Details")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(markerColor.opacity(0.2))
                            
                            Image(systemName: markerIcon)
                                .font(.title2)
                                .foregroundStyle(markerColor)
                        }
                        .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(typeLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        Image(systemName: "calendar")
                            .foregroundStyle(markerColor)
                            .frame(width: 30)
                        
                        Text("Day \(location.dayNumber)")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 12) {
                        Button {
                            onCenterOnMap()
                            dismiss()
                        } label: {
                            Label("Center on Map", systemImage: "scope")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(markerColor.opacity(0.2))
                                .foregroundStyle(markerColor)
                                .cornerRadius(8)
                        }

                        Button(action: openInMaps) {
                            Label("Open in Maps", systemImage: "map")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(markerColor.opacity(0.2))
                                .foregroundStyle(markerColor)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func openInMaps() {
        let query = location.title.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(query)&ll=\(coordinate.latitude),\(coordinate.longitude)") {
            UIApplication.shared.open(url)
        }
    }
}
