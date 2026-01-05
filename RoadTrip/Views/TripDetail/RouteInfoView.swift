// Views/TripDetail/RouteInfoView.swift
import SwiftUI
import MapKit

struct RouteInfo: Identifiable {
    var id = UUID()
    let dayNumber: Int
    let from: String
    let to: String
    let distance: Double
    let estimatedTime: TimeInterval
    let displayDistance: String
    let displayTime: String
    
    // Computed properties for convenience
    var distanceInMiles: Double {
        distance * 0.000621371 // Convert meters to miles
    }
    
    var durationInHours: Double {
        estimatedTime / 3600 // Convert seconds to hours
    }
    
    init(dayNumber: Int, from: String, to: String, distance: Double, estimatedTime: TimeInterval) {
        self.dayNumber = dayNumber
        self.from = from
        self.to = to
        self.distance = distance
        self.estimatedTime = estimatedTime
        self.displayDistance = String(format: "%.1f mi", distance)
        
        let hours = Int(estimatedTime / 3600)
        let minutes = Int((estimatedTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            self.displayTime = "\(hours)h \(minutes)m"
        } else {
            self.displayTime = "\(minutes)m"
        }
    }
    
    // Simpler initializer for RouteCalculator
    init(distance: Double, expectedTravelTime: TimeInterval) {
        self.id = UUID()
        self.dayNumber = 0
        self.from = ""
        self.to = ""
        self.distance = distance
        self.estimatedTime = expectedTravelTime
        self.displayDistance = String(format: "%.1f mi", distance * 0.000621371)
        
        let hours = Int(expectedTravelTime / 3600)
        let minutes = Int((expectedTravelTime.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            self.displayTime = "\(hours)h \(minutes)m"
        } else {
            self.displayTime = "\(minutes)m"
        }
    }
}

struct RouteInfoView: View {
    let trip: Trip
    @State private var routes: [RouteInfo] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                VStack {
                    ProgressView()
                    Text("Calculating routes...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if routes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "road.lanes")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("No routes available")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(routes) { route in
                            RouteCard(route: route)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "sum")
                                    .font(.headline)
                                
                                Text("Trip Summary")
                                    .font(.headline)
                                
                                Spacer()
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Distance")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(String(format: "%.1f mi", trip.totalDistance))
                                        .font(.headline)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Total Driving Time")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(formatTotalTime())
                                        .font(.headline)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding()
                    }
                    .padding(.vertical)
                }
            }
        }
        .onAppear {
            calculateRoutes()
        }
    }
    
    private func calculateRoutes() {
        isLoading = true
        routes.removeAll()
        
        let sortedDays = trip.safeDays.sorted(by: { $0.dayNumber < $1.dayNumber })
        let group = DispatchGroup()
        var tempRoutes: [RouteInfo] = []
        
        for day in sortedDays {
            group.enter()
            calculateRoute(from: day.startLocation, to: day.endLocation, dayNumber: day.dayNumber) { route in
                if let route = route {
                    tempRoutes.append(route)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            routes = tempRoutes.sorted(by: { $0.dayNumber < $1.dayNumber })
            isLoading = false
        }
    }
    
    private func calculateRoute(from: String, to: String, dayNumber: Int, completion: @escaping (RouteInfo?) -> Void) {
        let fromRequest = MKLocalSearch.Request()
        fromRequest.naturalLanguageQuery = from
        let fromSearch = MKLocalSearch(request: fromRequest)
        
        fromSearch.start { response, _ in
            guard let fromCoord = response?.mapItems.first?.placemark.coordinate else {
                completion(nil)
                return
            }
            
            let toRequest = MKLocalSearch.Request()
            toRequest.naturalLanguageQuery = to
            let toSearch = MKLocalSearch(request: toRequest)
            
            toSearch.start { response, _ in
                guard let toCoord = response?.mapItems.first?.placemark.coordinate else {
                    completion(nil)
                    return
                }
                
                let directionsRequest = MKDirections.Request()
                directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: fromCoord))
                directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: toCoord))
                directionsRequest.transportType = .automobile
                
                let directions = MKDirections(request: directionsRequest)
                directions.calculate { response, _ in
                    if let route = response?.routes.first {
                        let distance = route.distance / 1609.34 // Convert meters to miles
                        let routeInfo = RouteInfo(dayNumber: dayNumber, from: from, to: to, distance: distance, estimatedTime: route.expectedTravelTime)
                        completion(routeInfo)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    private func formatTotalTime() -> String {
        let totalSeconds = routes.reduce(0) { $0 + $1.estimatedTime }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int((totalSeconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct RouteCard: View {
    let route: RouteInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Day \(route.dayNumber)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text("Route")
                        .font(.headline)
                }
                
                Spacer()
                
                Image(systemName: "road.lanes")
                    .font(.title3)
                    .foregroundStyle(.blue)
            }
            
            Divider()
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("From")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(route.from)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
                
                VStack {
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 30)
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("To")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(route.to)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }
            }
            
            Divider()
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        Text(route.displayDistance)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Estimated Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        
                        Text(route.displayTime)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
