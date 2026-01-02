import SwiftUI
import MapKit

struct IdentifiableMapItem: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
    let activity: Activity
}

class ActivityAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    let id = UUID()
    let activity: Activity
    
    init(activity: Activity, coordinate: CLLocationCoordinate2D) {
        self.activity = activity
        self.coordinate = coordinate
        super.init()
    }
}

struct ActivitiesMapView: View {
    let activities: [Activity]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of USA
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
    )
    @State private var annotations: [ActivityAnnotation] = []
    @State private var selectedAnnotation: ActivityAnnotation?
    @State private var isLoading = true
    @State private var hasError = false
    @State private var showingActivityDetail: Activity?

    var body: some View {
        ZStack {
            Map(position: .constant(.region(region)), selection: $selectedAnnotation) {
                ForEach(annotations, id: \.id) { annotation in
                    Annotation("", coordinate: annotation.coordinate) {
                        ActivityMapMarker(activity: annotation.activity, isSelected: selectedAnnotation?.id == annotation.id)
                            .onTapGesture {
                                selectedAnnotation = annotation
                                showingActivityDetail = annotation.activity
                            }
                    }
                }
            }
            .mapStyle(.standard)
            
            VStack {
                HStack {
                    Text("Activities Map")
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
                        Text("\(annotations.count) activities on map")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Button(action: zoomToFitAllActivities) {
                            Label("Fit All Activities", systemImage: "rectangle.portrait.arrowtriangle.2.outward")
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
            fetchMapItems()
        }
        .sheet(item: $showingActivityDetail) { activity in
            ActivityDetailSheet(activity: activity)
        }
    }

    private func fetchMapItems() {
        isLoading = true
        hasError = false
        annotations.removeAll()
        
        let group = DispatchGroup()
        var coordinates: [CLLocationCoordinate2D] = []
        
        for activity in activities {
            group.enter()
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = activity.location
            let search = MKLocalSearch(request: request)
            
            search.start { response, error in
                defer { group.leave() }
                
                if let item = response?.mapItems.first {
                    let coordinate = item.placemark.coordinate
                    coordinates.append(coordinate)
                    let annotation = ActivityAnnotation(activity: activity, coordinate: coordinate)
                    annotations.append(annotation)
                }
            }
        }
        
        group.notify(queue: .main) {
            isLoading = false
            
            if annotations.isEmpty {
                hasError = true
            } else {
                zoomToFitAllActivities()
            }
        }
    }
    
    private func zoomToFitAllActivities() {
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

struct ActivityMapMarker: View {
    let activity: Activity
    let isSelected: Bool
    
    var categoryColor: Color {
        switch activity.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
    
    var categoryIcon: String {
        switch activity.category {
        case "Food": return "fork.knife"
        case "Attraction": return "star.fill"
        case "Hotel": return "bed.double.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                
                Circle()
                    .stroke(.white, lineWidth: 3)
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: isSelected ? 18 : 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            if isSelected {
                VStack(spacing: 2) {
                    Text(activity.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text(activity.location)
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

struct ActivityDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let activity: Activity
    
    var categoryColor: Color {
        switch activity.category {
        case "Food": return .orange
        case "Attraction": return .blue
        case "Hotel": return .purple
        default: return .gray
        }
    }
    
    var categoryIcon: String {
        switch activity.category {
        case "Food": return "fork.knife"
        case "Attraction": return "star.fill"
        case "Hotel": return "bed.double.fill"
        default: return "mappin.circle.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Activity Details")
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
                                .fill(categoryColor.opacity(0.2))
                            
                            Image(systemName: categoryIcon)
                                .font(.title2)
                                .foregroundStyle(categoryColor)
                        }
                        .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(activity.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(activity.category)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label(activity.location, systemImage: "mappin.circle")
                            .font(.subheadline)
                    }
                    
                    if let time = activity.scheduledTime {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(time.formatted(date: .omitted, time: .shortened), systemImage: "clock")
                                .font(.subheadline)
                            
                            if let duration = activity.duration {
                                Label("\(Int(duration * 60)) minutes", systemImage: "hourglass")
                                    .font(.subheadline)
                            }
                        }
                    }
                    
                    if let notes = activity.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            
                            Text(notes)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: openInMaps) {
                            Label("Open in Maps", systemImage: "map")
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(categoryColor.opacity(0.2))
                                .foregroundStyle(categoryColor)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func openInMaps() {
        let query = activity.location.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
        if let url = URL(string: "http://maps.apple.com/?q=\(query)") {
            UIApplication.shared.open(url)
        }
    }
}
