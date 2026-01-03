import Foundation
import MapKit
import UIKit

final class MapThumbnailRenderer {
    static let shared = MapThumbnailRenderer()

    private init() {}

    /// Render a small map snapshot for a coordinate region. Returns a UIImage on completion.
    func renderSnapshot(region: MKCoordinateRegion, size: CGSize = CGSize(width: 200, height: 120), completion: @escaping (UIImage?) -> Void) {
        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = size
        options.scale = UIScreen.main.scale

        let snap = MKMapSnapshotter(options: options)
        snap.start(with: .global(qos: .userInitiated)) { snapshot, error in
            guard let snapshot = snapshot, error == nil else {
                completion(nil)
                return
            }

            completion(snapshot.image)
        }
    }
}
