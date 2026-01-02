import SwiftUI
import MapKit

struct IdentifiableMapItem: Identifiable {
    let id = UUID()
    let mapItem: MKMapItem
}

struct ActivitiesMapView: View {
    let activities: [Activity]
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.8283, longitude: -98.5795), // Center of USA
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 20)
    )
    @State private var mapItems: [IdentifiableMapItem] = []

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: mapItems) { item in
            MapMarker(coordinate: item.mapItem.placemark.coordinate, tint: .blue)
        }
        .onAppear {
            fetchMapItems()
        }
        .frame(height: 300)
    }

    private func fetchMapItems() {
        mapItems = []
        for activity in activities {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = activity.location
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                if let item = response?.mapItems.first {
                    let identifiableItem = IdentifiableMapItem(mapItem: item)
                    mapItems.append(identifiableItem)
                    if mapItems.count == 1 {
                        region.center = item.placemark.coordinate
                        region.span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
                    }
                }
            }
        }
    }
}
