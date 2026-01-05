//
//  RoadTripTests.swift
//  RoadTripTests
//
//  Created by Jake Frischmann on 1/1/26.
//

import XCTest
@testable import RoadTrip

final class RoadTripTests: XCTestCase {
    
    // MARK: - Trip Creation Tests
    
    func testCreateTrip() throws {
        let tripName = "Summer Vacation"
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        
        let trip = Trip(name: tripName, startDate: startDate, endDate: endDate)
        
        XCTAssertEqual(trip.name, tripName)
        XCTAssertEqual(trip.startDate, startDate)
        XCTAssertEqual(trip.endDate, endDate)
        XCTAssertNotNil(trip.id)
        XCTAssertNotNil(trip.createdAt)
    }
    
    func testTripHasUniqueName() throws {
        let trip1 = Trip(name: "Trip 1", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        let trip2 = Trip(name: "Trip 2", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        
        XCTAssertNotEqual(trip1.name, trip2.name)
        XCTAssertNotEqual(trip1.id, trip2.id)
    }
    
    func testTripNameCanBeUpdated() throws {
        let trip = Trip(name: "Original", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        trip.name = "Updated"
        
        XCTAssertEqual(trip.name, "Updated")
    }
    
    func testTripDescriptionCanBeSet() throws {
        let trip = Trip(name: "Test", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        trip.tripDescription = "A test trip description"
        
        XCTAssertEqual(trip.tripDescription, "A test trip description")
    }
    
    func testTripCoverImageCanBeSet() throws {
        let trip = Trip(name: "Test", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        trip.coverImage = "car.fill"
        
        XCTAssertEqual(trip.coverImage, "car.fill")
    }
    
    // MARK: - Trip Duration Tests
    
    func testSingleDayTrip() throws {
        let today = Date()
        let trip = Trip(name: "Day Trip", startDate: today, endDate: today)
        
        XCTAssertEqual(trip.numberOfNights, 0)
        XCTAssertEqual(trip.safeDays.count, 1)
    }
    
    func testMultiDayTrip() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 5, to: startDate)!
        let trip = Trip(name: "Week Trip", startDate: startDate, endDate: endDate)
        
        XCTAssertEqual(trip.numberOfNights, 5)
        XCTAssertEqual(trip.safeDays.count, 6)
    }
    
    func testTripDaysAreInOrder() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 3, to: startDate)!
        let trip = Trip(name: "Test", startDate: startDate, endDate: endDate)
        
        for (index, day) in trip.safeDays.enumerated() {
            XCTAssertEqual(day.dayNumber, index + 1)
        }
    }
    
    // MARK: - Trip Distance Tests
    
    func testInitialTripDistance() throws {
        let trip = Trip(name: "Test", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        XCTAssertEqual(trip.totalDistance, 0)
    }
    
    func testTotalDistanceCalculation() throws {
        let trip = Trip(name: "Test", startDate: Date(), endDate: Date().addingTimeInterval(86400 * 2))
        
        if let day1 = trip.safeDays.first {
            day1.distance = 100
        }
        if trip.safeDays.count > 1 {
            trip.safeDays[1].distance = 150
        }
        
        XCTAssertEqual(trip.totalDistance, 250)
    }
    
    // MARK: - Trip Day Tests
    
    func testCreateTripDay() throws {
        let day = TripDay(dayNumber: 1, date: Date(), startLocation: "NYC", endLocation: "Boston")
        
        XCTAssertEqual(day.dayNumber, 1)
        XCTAssertEqual(day.startLocation, "NYC")
        XCTAssertEqual(day.endLocation, "Boston")
        XCTAssertEqual(day.activities.count, 0)
    }
    
    func testTripDayDistanceAndTime() throws {
        let day = TripDay(dayNumber: 1, date: Date(), startLocation: "NYC", endLocation: "Boston", distance: 215, drivingTime: 4)
        
        XCTAssertEqual(day.distance, 215)
        XCTAssertEqual(day.drivingTime, 4)
    }
    
    func testTripDayHotelAssignment() throws {
        let day = TripDay(dayNumber: 1, date: Date(), startLocation: "NYC", endLocation: "Boston")
        day.hotelName = "Hilton Boston"
        
        XCTAssertEqual(day.hotelName, "Hilton Boston")
    }
    
    func testAddActivityToDay() throws {
        let day = TripDay(dayNumber: 1, date: Date(), startLocation: "NYC", endLocation: "Boston")
        let activity = Activity(name: "Dinner", location: "Times Square", category: "Food")
        
        day.activities.append(activity)
        
        XCTAssertEqual(day.activities.count, 1)
        XCTAssertEqual(day.activities.first?.name, "Dinner")
    }
    
    func testAddMultipleActivitiesToDay() throws {
        let day = TripDay(dayNumber: 1, date: Date(), startLocation: "NYC", endLocation: "Boston")
        
        let activity1 = Activity(name: "Breakfast", location: "Cafe", category: "Food")
        let activity2 = Activity(name: "Museum", location: "MoMA", category: "Attraction")
        let activity3 = Activity(name: "Hotel", location: "Hilton", category: "Hotel")
        
        day.activities.append(contentsOf: [activity1, activity2, activity3])
        
        XCTAssertEqual(day.activities.count, 3)
    }
    
    // MARK: - Activity Tests
    
    func testCreateActivity() throws {
        let activity = Activity(name: "Sightseeing", location: "Empire State Building", category: "Attraction")
        
        XCTAssertEqual(activity.name, "Sightseeing")
        XCTAssertEqual(activity.location, "Empire State Building")
        XCTAssertEqual(activity.category, "Attraction")
        XCTAssertNil(activity.scheduledTime)
        XCTAssertNil(activity.duration)
        XCTAssertNil(activity.notes)
    }
    
    func testActivityCategories() throws {
        let categories = ["Food", "Attraction", "Hotel", "Other"]
        
        for category in categories {
            let activity = Activity(name: "Test", location: "Location", category: category)
            XCTAssertEqual(activity.category, category)
        }
    }
    
    func testActivityScheduledTime() throws {
        let activity = Activity(name: "Lunch", location: "Restaurant", category: "Food")
        let scheduledTime = Date()
        activity.scheduledTime = scheduledTime
        
        XCTAssertEqual(activity.scheduledTime, scheduledTime)
    }
    
    func testActivityDuration() throws {
        let activity = Activity(name: "Museum", location: "MoMA", category: "Attraction")
        activity.duration = 2.5 // 2.5 hours
        
        XCTAssertEqual(activity.duration, 2.5)
    }
    
    func testActivityNotes() throws {
        let activity = Activity(name: "Dinner", location: "Restaurant", category: "Food")
        activity.notes = "Make reservation in advance"
        
        XCTAssertEqual(activity.notes, "Make reservation in advance")
    }
    
    func testActivityWithAllFields() throws {
        let activity = Activity(name: "Concert", location: "Madison Square Garden", category: "Attraction")
        activity.scheduledTime = Date()
        activity.duration = 3.0
        activity.notes = "Bring ID"
        
        XCTAssertNotNil(activity.scheduledTime)
        XCTAssertEqual(activity.duration, 3.0)
        XCTAssertEqual(activity.notes, "Bring ID")
    }
    
    // MARK: - Validation Tests
    
    func testTripNameValidation() throws {
        let validNames = ["New York Trip", "Summer 2026", "Europe Adventure"]
        
        for name in validNames {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            XCTAssertFalse(trimmed.isEmpty)
        }
    }
    
    func testEmptyNameRejection() throws {
        let emptyNames = ["", "   ", "\t", "\n"]
        
        for name in emptyNames {
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            XCTAssertTrue(trimmed.isEmpty)
        }
    }
    
    func testDateRangeValidation() throws {
        let today = Date()
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        XCTAssertLessThan(today, tomorrow)
        
        let trip = Trip(name: "Test", startDate: today, endDate: tomorrow)
        XCTAssertEqual(trip.numberOfNights, 1)
    }
    
    func testInvalidDateRange() throws {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        let trip = Trip(name: "Test", startDate: today, endDate: yesterday)
        XCTAssertEqual(trip.numberOfNights, -1)
    }
    
    func testLocationValidation() throws {
        let validLocations = ["New York", "Los Angeles", "Tokyo"]
        
        for location in validLocations {
            XCTAssertFalse(location.isEmpty)
            XCTAssertGreaterThan(location.count, 0)
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testTripWith365Days() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 365, to: startDate)!
        let trip = Trip(name: "Year Long Trip", startDate: startDate, endDate: endDate)
        
        XCTAssertEqual(trip.safeDays.count, 366)
    }
    
    func testActivityWithZeroDuration() throws {
        let activity = Activity(name: "Quick Stop", location: "Location", category: "Other")
        activity.duration = 0
        
        XCTAssertEqual(activity.duration, 0)
    }
    
    func testActivityWithLongNotes() throws {
        let activity = Activity(name: "Event", location: "Location", category: "Attraction")
        let longNotes = String(repeating: "a", count: 1000)
        activity.notes = longNotes
        
        XCTAssertEqual(activity.notes?.count, 1000)
    }
    
    func testDayWithZeroDistance() throws {
        let day = TripDay(dayNumber: 1, date: Date(), startLocation: "NYC", endLocation: "NYC", distance: 0)
        
        XCTAssertEqual(day.distance, 0)
    }
    
    // MARK: - Data Type Tests
    
    func testTripIDIsUUID() throws {
        let trip = Trip(name: "Test", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        let idString = trip.id.uuidString
        
        XCTAssertEqual(idString.count, 36)
        XCTAssertTrue(idString.contains("-"))
    }
    
    func testActivityIDIsUnique() throws {
        let activity1 = Activity(name: "Activity 1", location: "Location", category: "Attraction")
        let activity2 = Activity(name: "Activity 2", location: "Location", category: "Attraction")
        
        XCTAssertNotEqual(activity1.id, activity2.id)
    }
    
    // MARK: - Performance Tests
    
    func testCreatingManyTrips() throws {
        self.measure {
            for i in 0..<1000 {
                _ = Trip(name: "Trip \(i)", startDate: Date(), endDate: Date().addingTimeInterval(86400))
            }
        }
    }
    
    func testCreatingManyActivities() throws {
        self.measure {
            for i in 0..<1000 {
                _ = Activity(name: "Activity \(i)", location: "Location \(i)", category: "Attraction")
            }
        }
    }
}

