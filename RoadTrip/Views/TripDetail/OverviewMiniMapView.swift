import SwiftUI
import MapKit

struct OverviewMiniMapView: View {
    let trip: Trip

    @State private var position: MapCameraPosition = .automatic
    @State private var pins: [MiniMapPin] = []
    @State private var selectedPin: MiniMapPin?

    var body: some View {
        Map(position: $position, interactionModes: [.pan, .zoom]) {
            ForEach(pins) { pin in
                Annotation(pin.title, coordinate: pin.coordinate) {
                    Image(systemName: pin.type == .start ? "location.circle.fill" : "mappin.circle.fill")
                        .font(.title3)
                        .foregroundStyle(pin.type == .start ? Color.green : Color.red)
                        .padding(6)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .onTapGesture {
                            selectedPin = pin
                        }
                }
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .task {
            await loadPins()
        }
        .sheet(item: $selectedPin) { pin in
            NavigationStack {
                VStack(spacing: 16) {
                    Image(systemName: pin.type == .start ? "location.circle.fill" : "mappin.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(pin.type == .start ? .green : .red)
                    
                    Text(pin.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Latitude: \(pin.coordinate.latitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Longitude: \(pin.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Location Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            selectedPin = nil
                        }
                    }
                }
            }
        }
    }

    private func loadPins() async {
        let dayLocations: [MiniMapPinRequest] = trip.days
            .sorted(by: { $0.dayNumber < $1.dayNumber })
            .flatMap { day in
                [
                    MiniMapPinRequest(type: .start, dayNumber: day.dayNumber, locationString: day.startLocation),
                    MiniMapPinRequest(type: .end, dayNumber: day.dayNumber, locationString: day.endLocation)
                ]
            }
            .filter { !$0.locationString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

        guard !dayLocations.isEmpty else {
            await MainActor.run {
                pins = []
                position = .automatic
            }
            return
        }

        var resolvedPins: [MiniMapPin] = []
        resolvedPins.reserveCapacity(dayLocations.count)

        await withTaskGroup(of: MiniMapPin?.self) { group in
            for request in dayLocations {
                group.addTask {
                    do {
                        let coordinate = try await GeocodingService.shared.geocode(location: request.locationString)
                        return MiniMapPin(
                            title: "Day \(request.dayNumber) \(request.type == .start ? "Start" : "End")",
                            coordinate: coordinate,
                            type: request.type
                        )
                    } catch {
                        return nil
                    }
                }
            }

            for await pin in group {
                if let pin { resolvedPins.append(pin) }
            }
        }

        await MainActor.run {
            pins = resolvedPins.sorted { a, b in
                if a.type != b.type { return a.type == .start }
                return a.title < b.title
            }
            zoomToFitAllPins()
        }
    }

    private func zoomToFitAllPins() {
        guard !pins.isEmpty else { return }

        let coordinates = pins.map { $0.coordinate }
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 0.5),
            longitudeDelta: max((maxLon - minLon) * 1.6, 0.5)
        )

        position = .region(MKCoordinateRegion(center: center, span: span))
    }
}

private struct MiniMapPinRequest {
    let type: MiniMapPin.PinType
    let dayNumber: Int
    let locationString: String
}

private struct MiniMapPin: Identifiable {
    enum PinType {
        case start
        case end
    }

    let id = UUID()
    let title: String
    let coordinate: CLLocationCoordinate2D
    let type: PinType
}
