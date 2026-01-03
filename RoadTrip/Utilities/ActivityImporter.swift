import Foundation
import MapKit

/// A lightweight importer that can fetch and parse basic place information from common sources.
final class ActivityImporter {
    struct ImportedPlace {
        var name: String
        var address: String?
        var rating: Double?
        var coordinate: CLLocationCoordinate2D?
        var category: String?
        var typicalDurationHours: Double?
    }

    static let shared = ActivityImporter()

    private init() {}

    enum ImportError: Error {
        case network
        case parse
    }

    /// Import attractions from a TripAdvisor page URL. Implementation uses simple HTML heuristics and is best-effort.
    func importFromTripAdvisor(url: URL) async throws -> [ImportedPlace] {
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200...299 ~= http.statusCode else { throw ImportError.network }

        guard let html = String(data: data, encoding: .utf8) else { throw ImportError.parse }
        return parseTripAdvisor(html: html)
    }

    /// Import attractions from a Google Maps place list / search URL. Uses simple heuristics.
    func importFromGoogleMaps(url: URL) async throws -> [ImportedPlace] {
        let (data, resp) = try await URLSession.shared.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200...299 ~= http.statusCode else { throw ImportError.network }

        guard let html = String(data: data, encoding: .utf8) else { throw ImportError.parse }
        return parseGoogleMaps(html: html)
    }

    /// Bulk add a few popular attractions for a given coordinate by using a simple POI search.
    func bulkAddPopularAttractions(near coordinate: CLLocationCoordinate2D, radiusMeters: Double = 2000) async -> [ImportedPlace] {
        let request = MKLocalPointsOfInterestRequest(center: coordinate, radius: radiusMeters)
        request.pointOfInterestFilter = .includingAll

        do {
            let mapItems = try await MKLocalSearch(request: MKLocalSearch.Request(pointOfInterestFilter: request.pointOfInterestFilter, naturalLanguageQuery: nil)).start()
            return mapItems.map { item in
                ImportedPlace(name: item.name ?? "Unknown", address: item.placemark.title, rating: nil, coordinate: item.placemark.coordinate, category: item.pointOfInterestCategory?.rawValue, typicalDurationHours: 1)
            }
        } catch {
            return []
        }
    }

    // MARK: - Parsing helpers (best-effort)

    private func parseTripAdvisor(html: String) -> [ImportedPlace] {
        // Very basic heuristics: find sections with `data-attraction-name` or <a> tags with known classes
        var results: [ImportedPlace] = []

        // Try to extract titles inside <a ...>...</a> with `ui_header` like classes
        let regex = try? NSRegularExpression(pattern: "<a[^>]*>([A-Za-z0-9\s'\-:,\.\&]+)</a>", options: [.caseInsensitive])
        if let regex = regex {
            let ns = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
            for m in matches.prefix(50) {
                if m.numberOfRanges >= 2 {
                    let title = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if title.count > 3 && title.count < 100 {
                        results.append(ImportedPlace(name: title, address: nil, rating: nil, coordinate: nil, category: "Attraction", typicalDurationHours: 1.5))
                    }
                }
            }
        }

        // De-duplicate by name
        var uniq: [String: ImportedPlace] = [:]
        for r in results {
            if uniq[r.name] == nil { uniq[r.name] = r }
        }

        return Array(uniq.values)
    }

    private func parseGoogleMaps(html: String) -> [ImportedPlace] {
        // Google serves data in JS – this is best-effort parsing for small lists; real integration should use Places API.
        var results: [ImportedPlace] = []
        let regex = try? NSRegularExpression(pattern: "\\\"(.*?)\\\",\\\[\\\d\\\]", options: [])
        if let regex = regex {
            let ns = html as NSString
            let matches = regex.matches(in: html, range: NSRange(location: 0, length: ns.length))
            for m in matches.prefix(80) {
                if m.numberOfRanges >= 2 {
                    let title = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                    if title.count > 3 && title.count < 80 {
                        results.append(ImportedPlace(name: title, address: nil, rating: nil, coordinate: nil, category: "Attraction", typicalDurationHours: 1.5))
                    }
                }
            }
        }

        // fallback: simple <span> tags
        if results.isEmpty {
            let spanRegex = try? NSRegularExpression(pattern: "<span[^>]*>([A-Za-z0-9\s'\-:,\.\&]+)</span>", options: [.caseInsensitive])
            if let sr = spanRegex {
                let ns = html as NSString
                let matches = sr.matches(in: html, range: NSRange(location: 0, length: ns.length))
                for m in matches.prefix(100) {
                    if m.numberOfRanges >= 2 {
                        let title = ns.substring(with: m.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                        if title.count > 3 && title.count < 80 {
                            results.append(ImportedPlace(name: title, address: nil, rating: nil, coordinate: nil, category: "Attraction", typicalDurationHours: 1.5))
                        }
                    }
                }
            }
        }

        // De-duplicate
        var uniq: [String: ImportedPlace] = [:]
        for r in results { if uniq[r.name] == nil { uniq[r.name] = r } }
        return Array(uniq.values)
    }
}
