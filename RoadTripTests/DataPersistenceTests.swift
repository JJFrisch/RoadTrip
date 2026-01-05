// RoadTripTests/DataPersistenceTests.swift
import XCTest
import SwiftData
@testable import RoadTrip

final class DataPersistenceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        // Create in-memory model container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: Trip.self, TripDay.self, Activity.self,
            configurations: config
        )
        modelContext = ModelContext(modelContainer)
    }
    
    override func tearDownWithError() throws {
        // Clean up
        try modelContext.delete(model: Trip.self)
        modelContext = nil
        modelContainer = nil
    }
    
    // MARK: - Trip Persistence
    
    func testSaveTripToDatabase() throws {
        let trip = Trip(name: "Persistence Test", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.name == "Persistence Test" })
        let fetchedTrips = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedTrips.count, 1)
        XCTAssertEqual(fetchedTrips.first?.name, "Persistence Test")
    }
    
    func testUpdateTripInDatabase() throws {
        let trip = Trip(name: "Original", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        try modelContext.save()
        
        // Update
        trip.name = "Updated"
        try modelContext.save()
        
        // Fetch and verify
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.id == trip.id })
        let fetchedTrips = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedTrips.first?.name, "Updated")
    }
    
    func testDeleteTripFromDatabase() throws {
        let trip = Trip(name: "To Delete", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        try modelContext.save()
        
        // Delete
        modelContext.delete(trip)
        try modelContext.save()
        
        // Verify deletion
        let descriptor = FetchDescriptor<Trip>(predicate: #Predicate { $0.name == "To Delete" })
        let fetchedTrips = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedTrips.count, 0)
    }
    
    func testMultipleTripsInDatabase() throws {
        for i in 0..<5 {
            let trip = Trip(name: "Trip \(i)", startDate: Date(), endDate: Date().addingTimeInterval(86400))
            modelContext.insert(trip)
        }
        try modelContext.save()
        
        // Fetch all
        let descriptor = FetchDescriptor<Trip>()
        let fetchedTrips = try modelContext.fetch(descriptor)
        
        XCTAssertEqual(fetchedTrips.count, 5)
    }
    
    // MARK: - Trip Day Persistence
    
    func testSaveTripDayToDatabase() throws {
        let trip = Trip(name: "Trip with Days", startDate: Date(), endDate: Date().addingTimeInterval(86400 * 2))
        modelContext.insert(trip)
        try modelContext.save()
        
        // Verify days were created
        XCTAssertGreaterThan(trip.days.count, 0)
        
        let firstDay = trip.days.first
        XCTAssertNotNil(firstDay)
        XCTAssertEqual(firstDay?.dayNumber, 1)
    }
    
    func testUpdateTripDayDetails() throws {
        let trip = Trip(name: "Trip", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        
        if let day = trip.days.first {
            day.startLocation = "New York"
            day.endLocation = "Boston"
            day.distance = 215
            day.hotelName = "Hilton"
        }
        
        try modelContext.save()
        
        // Fetch and verify
        let fetchedTrip = try modelContext.fetch(FetchDescriptor<Trip>()).first
        if let fetchedDay = fetchedTrip?.days.first {
            XCTAssertEqual(fetchedDay.startLocation, "New York")
            XCTAssertEqual(fetchedDay.distance, 215)
            XCTAssertEqual(fetchedDay.hotelName, "Hilton")
        }
    }
    
    // MARK: - Activity Persistence
    
    func testSaveActivityToDatabase() throws {
        let trip = Trip(name: "Trip with Activities", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        
        if let day = trip.days.first {
            let activity = Activity(name: "Dinner", location: "Times Square", category: "Food")
            activity.notes = "Make reservation"
            day.activities.append(activity)
        }
        
        try modelContext.save()
        
        // Fetch and verify
        let fetchedTrip = try modelContext.fetch(FetchDescriptor<Trip>()).first
        let activities = fetchedTrip?.days.first?.activities ?? []
        
        XCTAssertEqual(activities.count, 1)
        XCTAssertEqual(activities.first?.name, "Dinner")
        XCTAssertEqual(activities.first?.notes, "Make reservation")
    }
    
    func testUpdateActivityInDatabase() throws {
        let trip = Trip(name: "Trip", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        
        if let day = trip.days.first {
            let activity = Activity(name: "Museum", location: "MoMA", category: "Attraction")
            day.activities.append(activity)
        }
        
        try modelContext.save()
        
        // Update activity
        if let activity = trip.days.first?.activities.first {
            activity.category = "Other"
            activity.duration = 2.5
        }
        
        try modelContext.save()
        
        // Fetch and verify
        let fetchedTrip = try modelContext.fetch(FetchDescriptor<Trip>()).first
        let activity = fetchedTrip?.days.first?.activities.first
        
        XCTAssertEqual(activity?.category, "Other")
        XCTAssertEqual(activity?.duration, 2.5)
    }
    
    func testDeleteActivityFromDatabase() throws {
        let trip = Trip(name: "Trip", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        
        if let day = trip.days.first {
            let activity = Activity(name: "Activity", location: "Location", category: "Other")
            day.activities.append(activity)
        }
        
        try modelContext.save()
        
        // Delete activity
        if let activity = trip.days.first?.activities.first {
            if let day = trip.days.first {
                day.activities.removeAll { $0.id == activity.id }
            }
        }
        
        try modelContext.save()
        
        // Verify deletion
        let activities = trip.days.first?.activities ?? []
        XCTAssertEqual(activities.count, 0)
    }
    
    // MARK: - Data Integrity Tests
    
    func testTripWithMultipleActivitiesIntegrity() throws {
        let trip = Trip(name: "Complex Trip", startDate: Date(), endDate: Date().addingTimeInterval(86400 * 2))
        modelContext.insert(trip)
        
        for (dayIndex, day) in trip.days.enumerated() {
            for actIndex in 0..<3 {
                let activity = Activity(
                    name: "Activity \(actIndex)",
                    location: "Location \(actIndex)",
                    category: actIndex % 2 == 0 ? "Food" : "Attraction"
                )
                day.activities.append(activity)
            }
        }
        
        try modelContext.save()
        
        // Verify integrity
        for day in trip.days {
            XCTAssertEqual(day.activities.count, 3)
        }
        
        let totalActivities = trip.days.reduce(0) { $0 + $1.activities.count }
        XCTAssertEqual(totalActivities, 6)
    }
    
    func testCascadeDeletion() throws {
        let trip = Trip(name: "To Delete", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        
        if let day = trip.days.first {
            for i in 0..<5 {
                let activity = Activity(name: "Activity \(i)", location: "Location", category: "Other")
                day.activities.append(activity)
            }
        }
        
        try modelContext.save()
        
        // Delete trip
        modelContext.delete(trip)
        try modelContext.save()
        
        // Verify all related data is deleted
        let fetchedTrips = try modelContext.fetch(FetchDescriptor<Trip>())
        XCTAssertEqual(fetchedTrips.count, 0)
    }
    
    // MARK: - Data Consistency Tests
    
    func testTripDateConsistency() throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 5, to: startDate)!
        let trip = Trip(name: "Date Test", startDate: startDate, endDate: endDate)
        
        modelContext.insert(trip)
        try modelContext.save()
        
        let fetchedTrip = try modelContext.fetch(FetchDescriptor<Trip>()).first
        
        XCTAssertEqual(fetchedTrip?.startDate, startDate)
        XCTAssertEqual(fetchedTrip?.endDate, endDate)
        XCTAssertEqual(fetchedTrip?.numberOfNights, 5)
    }
    
    func testActivityTimeConsistency() throws {
        let trip = Trip(name: "Time Test", startDate: Date(), endDate: Date().addingTimeInterval(86400))
        modelContext.insert(trip)
        
        let scheduledTime = Date()
        if let day = trip.days.first {
            let activity = Activity(name: "Timed Activity", location: "Location", category: "Food")
            activity.scheduledTime = scheduledTime
            activity.duration = 1.5
            day.activities.append(activity)
        }
        
        try modelContext.save()
        
        let fetchedTrip = try modelContext.fetch(FetchDescriptor<Trip>()).first
        let activity = fetchedTrip?.days.first?.activities.first
        
        XCTAssertEqual(activity?.scheduledTime, scheduledTime)
        XCTAssertEqual(activity?.duration, 1.5)
    }
    
    // MARK: - Large Data Tests
    
    func testSaveAndRetrieveLargeDataset() throws {
        let startDate = Date()
        let trip = Trip(name: "Large Trip", startDate: startDate, endDate: Calendar.current.date(byAdding: .day, value: 30, to: startDate)!)
        modelContext.insert(trip)
        
        // Add activities to each day
        for day in trip.days {
            for i in 0..<10 {
                let activity = Activity(name: "Activity \(i)", location: "Location \(i)", category: "Attraction")
                day.activities.append(activity)
            }
        }
        
        try modelContext.save()
        
        // Verify
        let totalActivities = trip.days.reduce(0) { $0 + $1.activities.count }
        XCTAssertGreaterThan(totalActivities, 0)
    }
}
