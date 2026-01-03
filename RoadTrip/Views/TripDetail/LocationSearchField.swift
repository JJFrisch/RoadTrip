// Views/TripDetail/LocationSearchField.swift
import SwiftUI
import MapKit
import CoreLocation

struct LocationSearchField: View {
    let title: String
    @Binding var location: String
    let icon: String
    let iconColor: Color
    var placeholder: String = "Enter location"
    var searchRegion: MKCoordinateRegion? = nil
    var searchQuery: String = ""
    var searchRegionAddress: String? = nil
    
    @State private var searchResults: [MKLocalSearchCompletion] = []
    @State private var isSearching = false
    @StateObject private var searchCompleter = LocationSearchCompleter()
    @FocusState private var isFocused: Bool
    @State private var searchRegionCoordinate: CLLocationCoordinate2D? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                
                TextField(title, text: $location)
                    .focused($isFocused)
                    .onChange(of: location) { oldValue, newValue in
                        if isFocused && !newValue.isEmpty {
                            // Use category-specific search query if provided
                            let query = searchQuery.isEmpty ? newValue : newValue
                            searchCompleter.search(query: query, region: searchRegion)
                            isSearching = true
                        } else {
                            isSearching = false
                        }
                    }
                    .onChange(of: isFocused) { oldValue, newValue in
                        if !newValue {
                            isSearching = false
                        }
                    }
                    .onAppear {
                        if let region = searchRegion {
                            searchCompleter.setRegion(region)
                        } else if let address = searchRegionAddress, !address.isEmpty {
                            // Geocode the address to get search region
                            searchCompleter.geocodeAddress(address)
                        }
                    }
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                
                if !location.isEmpty {
                    Button {
                        location = ""
                        searchResults = []
                        isSearching = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            if isSearching && !searchCompleter.results.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(searchCompleter.results.prefix(5), id: \.self) { result in
                        Button {
                            location = result.title
                            isSearching = false
                            isFocused = false
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(.systemGray6))
                        }
                        .buttonStyle(.plain)
                        
                        if result != searchCompleter.results.prefix(5).last {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.top, 4)
            }
        }
    }
}

class LocationSearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer: MKLocalSearchCompleter
    private let cache = LocationCache.shared
    private var currentQuery: String = ""
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }
    
    func setRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }
    
    func search(query: String, region: MKCoordinateRegion? = nil) {
        currentQuery = query
        
        // Check cache first
        if let cachedResults = cache.getCachedSearchResults(for: query) {
            DispatchQueue.main.async {
                self.results = cachedResults
            }
            return
        }
        
        // If not in cache, perform search
        if let region = region {
            completer.region = region
        }
        completer.queryFragment = query
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
            // Cache the results
            self.cache.cacheSearchResults(completer.results, for: self.currentQuery)
        }
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.results = []
        }
    }
    
    func geocodeAddress(_ address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                let region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                )
                DispatchQueue.main.async {
                    self.setRegion(region)
                }
            }
        }
    }
}

// MKLocalSearchCompletion already conforms to Hashable in MapKit
