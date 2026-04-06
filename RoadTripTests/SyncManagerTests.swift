import XCTest
@testable import RoadTrip

final class SyncManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        SyncManager.shared.clear()
    }

    func testTypedOperationQueueRoundTrip() {
        let op = SyncManager.SyncOperation(
            kind: .createActivity,
            entityId: UUID(),
            tripId: UUID(),
            dayId: UUID(),
            payload: ["name": "Lunch"]
        )

        SyncManager.shared.enqueue(op)

        let queued = SyncManager.shared.allOperations()
        XCTAssertEqual(queued.count, 1)
        XCTAssertEqual(queued[0].kind, .createActivity)
        XCTAssertEqual(queued[0].payload["name"], "Lunch")

        let popped = SyncManager.shared.dequeueOperation()
        XCTAssertEqual(popped?.id, op.id)
        XCTAssertTrue(SyncManager.shared.allOperations().isEmpty)
    }

    func testLegacyStringQueueCompatibility() {
        SyncManager.shared.enqueue("legacy-op")

        XCTAssertEqual(SyncManager.shared.all(), ["legacy-op"])
        XCTAssertEqual(SyncManager.shared.dequeue(), "legacy-op")
    }
}
