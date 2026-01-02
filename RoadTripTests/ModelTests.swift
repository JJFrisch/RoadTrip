// RoadTripTests/ModelTests.swift
import XCTest
@testable import RoadTrip

class TripModelTests: XCTestCase {
    var testTrip: Trip!
    
    override func setUp() {
        super.setUp()
        testTrip = Trip(name: "Test Trip", startDate: Date(), endDate: Date().addingTimeInterval(86400 * 3))
    }
    
    override func tearDown() {
        testTrip = nil
        super.tearDown()
    }
    
    func testTripInitialization() {
        XCTAssertEqual(testTrip.name, "Test Trip")
        XCTAssertEqual(testTrip.id.uuidString.count, 36)
        XCTAssertEqual(testTrip.days.count, 4)
    }
    
    func testNumberOfNights() {
        let nights = testTrip.numberOfNights
        XCTAssertEqual(nights, 3)
    }
    
    func testTotalDistance() {
        // Initially should be 0
        XCTAssertEqual(testTrip.totalDistance, 0)
        
        // Add a day with distance
        if let firstDay = testTrip.days.first {
            firstDay.distance = 100
            XCTAssertEqual(testTrip.totalDistance, 100)
        }
    }
    
    func testTripDayGeneration() {
        XCTAssertGreaterThan(testTrip.days.count, 0)
        
        for (index, day) in testTrip.days.enumerated() {
            XCTAssertEqual(day.dayNumber, index + 1)
        }
    }
}

class TripDayModelTests: XCTestCase {
    var testDay: TripDay!
    
    override func setUp() {
        super.setUp()
        testDay = TripDay(dayNumber: 1, date: Date(), startLocation: "New York", endLocation: "Boston")
    }
    
    override func tearDown() {
        testDay = nil
        super.tearDown()
    }
    
    func testTripDayInitialization() {
        XCTAssertEqual(testDay.dayNumber, 1)
        XCTAssertEqual(testDay.startLocation, "New York")
        XCTAssertEqual(testDay.endLocation, "Boston")
        XCTAssertEqual(testDay.activities.count, 0)
    }
    
    func testAddActivity() {
        let activity = Activity(name: "Dinner", location: "Times Square", category: "Food")
        testDay.activities.append(activity)
        
        XCTAssertEqual(testDay.activities.count, 1)
        XCTAssertEqual(testDay.activities.first?.name, "Dinner")
    }
    
    func testHotelAssignment() {
        testDay.hotelName = "Hilton"
        XCTAssertEqual(testDay.hotelName, "Hilton")
    }
}

class ActivityModelTests: XCTestCase {
    var testActivity: Activity!
    
    override func setUp() {
        super.setUp()
        testActivity = Activity(name: "Museum Visit", location: "MoMA", category: "Attraction")
    }
    
    override func tearDown() {
        testActivity = nil
        super.tearDown()
    }
    
    func testActivityInitialization() {
        XCTAssertEqual(testActivity.name, "Museum Visit")
        XCTAssertEqual(testActivity.location, "MoMA")
        XCTAssertEqual(testActivity.category, "Attraction")
        XCTAssertNil(testActivity.scheduledTime)
    }
    
    func testActivityCategories() {
        let categories = ["Food", "Attraction", "Hotel", "Other"]
        
        for category in categories {
            let activity = Activity(name: "Test", location: "Location", category: category)
            XCTAssertEqual(activity.category, category)
        }
    }
    
    func testActivityDuration() {
        testActivity.duration = 2.5
        XCTAssertEqual(testActivity.duration, 2.5)
    }
}

class DateCalculationTests: XCTestCase {
    func testDateDifference() {
        let calendar = Calendar.current
        let startDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let endDate = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5))!
        
        let difference = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        XCTAssertEqual(difference, 4)
    }
    
    func testTripWithSingleDay() {
        let today = Date()
        let trip = Trip(name: "Day Trip", startDate: today, endDate: today)
        
        XCTAssertEqual(trip.numberOfNights, 0)
        XCTAssertEqual(trip.days.count, 1)
    }
}

class ValidationTests: XCTestCase {
    func testTripNameValidation() {
        let validNames = ["Test", "My Trip", "Summer Vacation 2026"]
        
        for name in validNames {
            XCTAssertFalse(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    
    func testEmptyNameValidation() {
        let emptyNames = ["", "   ", "\t", "\n"]
        
        for name in emptyNames {
            XCTAssertTrue(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    
    func testDateValidation() {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        XCTAssertLessThan(today, tomorrow)
        XCTAssertGreaterThanOrEqual(tomorrow, today)
    }
}
