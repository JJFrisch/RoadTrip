import SwiftUI
import MapKit

struct MapThumbnailView: View {
    var region: MKCoordinateRegion?
    var address: String?
    @State private var image: UIImage? = nil
    @State private var resolvedRegion: MKCoordinateRegion? = nil

    var body: some View {
        Group {
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay(ProgressView())
            }
        }
        .frame(width: 120, height: 72)
        .cornerRadius(8)
        .onAppear {
            if let region = region {
                render(region: region)
                return
            }

            if let address = address {
                geocode(address: address) { reg in
                    if let reg = reg { render(region: reg) }
                }
            }
        }
    }

    private func render(region: MKCoordinateRegion) {
        MapThumbnailRenderer.shared.renderSnapshot(region: region, size: CGSize(width: 240, height: 144)) { img in
            DispatchQueue.main.async { self.image = img }
        }
    }

    private func geocode(address: String, completion: @escaping (MKCoordinateRegion?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { placemarks, error in
            guard let coord = placemarks?.first?.location?.coordinate else { completion(nil); return }
            let region = MKCoordinateRegion(center: coord, span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
            completion(region)
        }
    }
}
