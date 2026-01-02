// Views/TripDetail/TripMapView.swift
import SwiftUI
import MapKit

struct TripMapView: View {
    let trip: Trip
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
    )
    @State private var annotations: [TripLocationAnnotation] = []
    @State private var selectedAnnotation: TripLocationAnnotation?
    @State private var isLoading = true
    @State private var hasError = false
    @State private var showingLocationDetail: TripLocation?

    var body: some View {
        ZStack {
            Map(position: .constant(.region(region)), selection: $selectedAnnotation) {
                ForEach(annotations, id: \.id) { annotation in
                    Annotation("", coordinate: annotation.coordinate) {
                        LocationMapMarker(location: annotation.location, isSelected: selectedAnnotation?.id == annotation.id)
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
                    
                    if isLoading {
                        ProgressView()
                            .padding()
                    }
                }
                .background(.ultraThinMaterial)
                
                Spacer()
                
                if hasError {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title2)
                        Text("Unable to load map locations")
                            .font(.caption)
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
            }
        }
        .onAppear {
            fetchLocations()
        }
        .sheet(item: $showingLocationDetail) { location in
            LocationDetailSheet(location: location)
        }
    }

    private func fetchLocations() {
        isLoading = true
        hasError = false
        annotations.removeAll()
        
        var locations: [TripLocation] = []
        
        // Collect all unique locations from trip days
        for (index, day) in trip.days.sorted(by: { $0.dayNumber < $1.dayNumber }).enumerated() {
            locations.append(TripLocation(
                title: day.startLocation,
                subtitle: "Day \(day.dayNumber) - Start",
                type: .dayStart,
                dayNumber: day.dayNumber
            ))
            
            if index == trip.days.count - 1 {
                locations.append(TripLocation(
                    title: day.endLocation,
                    subtitle: "Day \(day.dayNumber) - End",
                    type: .dayEnd,
                    dayNumber: day.dayNumber
                ))
            }
            
            // Add hotel if available
            if let hotelName = day.hotelName {
                locations.append(TripLocation(
                    title: hotelName,
                    subtitle: "Day \(day.dayNumber) - Hotel",
                    type: .hotel,
                    dayNumber: day.dayNumber
                ))
            }
        }
        
        let group = DispatchGroup()
        
        for location in locations {
            group.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = location.title
            let search = MKLocalSearch(request: request)
            
            search.start { response, error in
                defer { group.leave() }
                
                if let item = response?.mapItems.first {
                    let coordinate = item.placemark.coordinate
                    let annotation = TripLocationAnnotation(location: location, coordinate: coordinate)
                    annotations.append(annotation)
                }
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            
            if annotations.isEmpty {
                hasError = true
            } else {
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
            latitudeDelta: max((maxLat - minLat) * 1.3, 0.5),
            longitudeDelta: max((maxLon - minLon) * 1.3, 0.5)
        )
        
        withAnimation {
            region = MKCoordinateRegion(center: center, span: span)
        }
    }
}

struct TripLocation: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let type: LocationType
    let dayNumber: Int
    
    enum LocationType {
        case dayStart
        case dayEnd
        case hotel
    }
}

struct TripLocationAnnotation: Identifiable {
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
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(markerColor)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                
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
