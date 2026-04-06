import XCTest
@testable import RoadTrip

final class TripBusinessLogicTests: XCTestCase {
    func testUpdateDatesExpandsDaysAndPreservesExistingActivities() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 5))!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        let trip = Trip(name: "Expansion", startDate: start, endDate: end)
        XCTAssertEqual(trip.days.count, 2)

        let activity = Activity(name: "Lunch", location: "Downtown", category: "Food")
        trip.days[0].activities.append(activity)

        let newEnd = calendar.date(byAdding: .day, value: 4, to: start)!
        trip.updateDates(newStartDate: start, newEndDate: newEnd)

        XCTAssertEqual(trip.days.count, 5)
        XCTAssertEqual(trip.days[0].activities.count, 1)
        XCTAssertEqual(trip.days[0].activities.first?.name, "Lunch")
        XCTAssertEqual(trip.days.last?.dayNumber, 5)
    }

    func testUpdateDatesShrinksDaysAndMovesActivitiesToLastRemainingDay() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 1))!
        let end = calendar.date(byAdding: .day, value: 4, to: start)!

        let trip = Trip(name: "Shrink", startDate: start, endDate: end)
        XCTAssertEqual(trip.days.count, 5)

        let trailingActivity = Activity(name: "Late Stop", location: "North", category: "Attraction")
        trip.days[4].activities.append(trailingActivity)

        let newEnd = calendar.date(byAdding: .day, value: 1, to: start)!
        trip.updateDates(newStartDate: start, newEndDate: newEnd)

        XCTAssertEqual(trip.days.count, 2)
        XCTAssertEqual(trip.days[1].activities.count, 1)
        XCTAssertEqual(trip.days[1].activities[0].name, "Late Stop")
    }

    func testBudgetCalculationsUseOnlyCompletedActivities() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 4, day: 10))!
        let end = calendar.date(byAdding: .day, value: 1, to: start)!

        let trip = Trip(name: "Budget", startDate: start, endDate: end)

        let included = Activity(name: "Dinner", location: "Main Street", category: "Food")
        included.isCompleted = true
        included.estimatedCost = 42
        included.costCategory = "Food"

        let excluded = Activity(name: "Future Event", location: "Park", category: "Attraction")
        excluded.isCompleted = false
        excluded.estimatedCost = 100
        excluded.costCategory = "Attractions"

        trip.days[0].activities = [included, excluded]

        XCTAssertEqual(trip.estimatedTotalCost, 42)
        XCTAssertEqual(trip.budgetByCategory("Food"), 42)
        XCTAssertEqual(trip.budgetByCategory("Attractions"), 0)
        XCTAssertEqual(trip.budgetBreakdown.count, 1)
        XCTAssertEqual(trip.budgetBreakdown.first?.category, "Food")
    }

    func testTripWithReversedDatesStillCreatesSingleDay() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 5, day: 5))!
        let end = calendar.date(byAdding: .day, value: -2, to: start)!

        let trip = Trip(name: "Reverse", startDate: start, endDate: end)

        XCTAssertEqual(trip.days.count, 1)
        XCTAssertEqual(trip.days.first?.dayNumber, 1)
        XCTAssertEqual(trip.numberOfNights, 0)
    }
}

final class ActivityUndoManagerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        ActivityUndoManager.shared.clearHistory()
    }

    func testUndoRedoAvailabilityTracksRecordedChanges() {
        let day = TripDay(dayNumber: 1, date: Date(), startLocation: "A", endLocation: "B")
        let activity = Activity(name: "Coffee", location: "Cafe", category: "Food")

        XCTAssertFalse(ActivityUndoManager.shared.canUndo)
        XCTAssertFalse(ActivityUndoManager.shared.canRedo)

        ActivityUndoManager.shared.recordChange(activity, action: .create)

        XCTAssertTrue(ActivityUndoManager.shared.canUndo)
        XCTAssertFalse(ActivityUndoManager.shared.canRedo)

        let undoSnapshot = ActivityUndoManager.shared.undo(in: day)
        XCTAssertNotNil(undoSnapshot)
        XCTAssertFalse(ActivityUndoManager.shared.canUndo)
        XCTAssertTrue(ActivityUndoManager.shared.canRedo)

        let redoSnapshot = ActivityUndoManager.shared.redo(in: day)
        XCTAssertNotNil(redoSnapshot)
        XCTAssertTrue(ActivityUndoManager.shared.canUndo)
    }
}
