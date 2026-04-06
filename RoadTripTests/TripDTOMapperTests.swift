import XCTest
@testable import RoadTrip

final class TripDTOMapperTests: XCTestCase {
    func testTripMapsToDTOWithNestedDaysAndActivities() {
        let start = Date()
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        let trip = Trip(name: "Mapper Test", startDate: start, endDate: end)

        XCTAssertFalse(trip.days.isEmpty)
        let activity = Activity(name: "Museum", location: "Downtown", category: "Attraction")
        activity.order = 2
        activity.duration = 1.5
        trip.days[0].activities.append(activity)

        let dto = trip.asDTO(sync: SyncMetadataDTO(version: 3, updatedAt: start))

        XCTAssertEqual(dto.name, "Mapper Test")
        XCTAssertEqual(dto.days.count, trip.days.count)
        XCTAssertEqual(dto.days[0].activities.count, 1)
        XCTAssertEqual(dto.days[0].activities[0].name, "Museum")
        XCTAssertEqual(dto.days[0].activities[0].duration, 1.5)
        XCTAssertEqual(dto.sync.version, 3)
    }
}
