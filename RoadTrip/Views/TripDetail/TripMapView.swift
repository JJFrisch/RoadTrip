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
    @State private var showingLocationDetail: TripLocation?
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
                                showingLocationDetail = annotation.location
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
            LocationDetailSheet(location: location)
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
        
        // Collect all unique locations from trip days in order for the route
        let sortedDays = (trip.days ?? []).sorted(by: { $0.dayNumber < $1.dayNumber })
        
        for (index, day) in sortedDays.enumerated() {
            // Add start location
            locations.append(TripLocation(
                title: day.startLocation,
                subtitle: "Day \(day.dayNumber) - Start",
                type: .dayStart,
                dayNumber: day.dayNumber,
                orderIndex: index * 3 // For route ordering
            ))
            
            // Add hotel if available (in between start and end)
            if let hotelName = day.hotelName, !hotelName.isEmpty {
                locations.append(TripLocation(
                    title: hotelName,
                    subtitle: "Day \(day.dayNumber) - Hotel",
                    type: .hotel,
                    dayNumber: day.dayNumber,
                    orderIndex: index * 3 + 1
                ))
            }
            
            // Add end location for each day
            locations.append(TripLocation(
                title: day.endLocation,
                subtitle: "Day \(day.dayNumber) - End",
                type: .dayEnd,
                dayNumber: day.dayNumber,
                orderIndex: index * 3 + 2
            ))
        }
        
        // Remove duplicate consecutive locations (e.g., Day 1 end = Day 2 start)
        var uniqueLocations: [TripLocation] = []
        for location in locations {
            if uniqueLocations.last?.title.lowercased() != location.title.lowercased() {
                uniqueLocations.append(location)
            }
        }
        
        let group = DispatchGroup()
        var tempAnnotations: [(TripLocation, CLLocationCoordinate2D)] = []
        let lock = NSLock()
        
        for location in uniqueLocations {
            guard !location.title.isEmpty else { continue }

            if let placemark = LocationCache.shared.getCachedPlacemark(for: location.title) {
                lock.lock()
                tempAnnotations.append((location, placemark.coordinate))
                lock.unlock()
                continue
            }
            
            group.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = location.title
            let search = MKLocalSearch(request: request)
            
            search.start { response, error in
                defer { group.leave() }
                
                if let item = response?.mapItems.first {
                    let coordinate = item.placemark.coordinate
                    LocationCache.shared.cachePlacemark(item.placemark, for: location.title)
                    lock.lock()
                    tempAnnotations.append((location, coordinate))
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
        case hotel
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
        case .hotel: 
            return colorScheme == .dark 
                ? Color(red: 0.7, green: 0.5, blue: 1.0) 
                : .purple
        }
    }
    
    var markerIcon: String {
        switch location.type {
        case .dayStart: return "location.circle"
        case .dayEnd: return "mappin.circle"
        case .hotel: return "bed.double"
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
    
    var markerColor: Color {
        switch location.type {
        case .dayStart: return .green
        case .dayEnd: return .red
        case .hotel: return .purple
        }
    }
    
    var markerIcon: String {
        switch location.type {
        case .dayStart: return "location.circle"
        case .dayEnd: return "mappin.circle"
        case .hotel: return "bed.double"
        }
    }
    
    var typeLabel: String {
        switch location.type {
        case .dayStart: return "Day Start"
        case .dayEnd: return "Day End"
        case .hotel: return "Hotel"
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
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}
