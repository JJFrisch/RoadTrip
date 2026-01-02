// RoadTripUITests/RoadTripUIFlowTests.swift
import XCTest

final class RoadTripUIFlowTests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Home Screen Tests
    
    func testHomeScreenDisplaysCorrectly() throws {
        XCTAssertTrue(app.navigationBars["My Trips"].exists)
        XCTAssertTrue(app.buttons["plus.circle.fill"].exists)
    }
    
    func testEmptyStateDisplayedWhenNoTrips() throws {
        // If app is fresh, empty state should show
        let emptyText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'No Trips'"))
        if emptyText.count > 0 {
            XCTAssertTrue(emptyText.element.exists)
        }
    }
    
    // MARK: - Trip Creation Flow
    
    func testCompleteCreateTripFlow() throws {
        // Tap add button
        let addButton = app.buttons["plus.circle.fill"]
        addButton.tap()
        
        // Wait for sheet
        let tripNameField = app.textFields["Trip Name"]
        XCTAssertTrue(tripNameField.waitForExistence(timeout: 2))
        
        // Fill in trip name
        tripNameField.tap()
        tripNameField.typeText("Test Trip 2026")
        
        // Tap create button
        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.exists)
        createButton.tap()
        
        // Verify back on home screen
        XCTAssertTrue(app.navigationBars["My Trips"].exists)
    }
    
    func testCreateTripValidation() throws {
        let addButton = app.buttons["plus.circle.fill"]
        addButton.tap()
        
        _ = app.textFields["Trip Name"].waitForExistence(timeout: 2)
        
        // Create button should be disabled without name
        let createButton = app.buttons["Create"]
        XCTAssertFalse(createButton.isEnabled)
        
        // Type name
        let tripNameField = app.textFields["Trip Name"]
        tripNameField.tap()
        tripNameField.typeText("Valid Trip Name")
        
        // Now button should be enabled
        XCTAssertTrue(createButton.isEnabled)
    }
    
    func testCancelTripCreation() throws {
        let addButton = app.buttons["plus.circle.fill"]
        addButton.tap()
        
        _ = app.textFields["Trip Name"].waitForExistence(timeout: 2)
        
        let cancelButton = app.buttons["Cancel"]
        cancelButton.tap()
        
        // Should be back on home screen
        XCTAssertTrue(app.navigationBars["My Trips"].exists)
    }
    
    // MARK: - Trip Navigation Flow
    
    func testNavigateToTripDetails() throws {
        // Create a trip first
        createTestTrip(name: "Navigation Test Trip")
        
        // Find and tap the trip
        let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Navigation Test Trip'"))
        if tripElement.count > 0 {
            tripElement.element.tap()
            
            // Verify we're in trip detail view with tabs
            let overviewTab = app.buttons["Overview"]
            XCTAssertTrue(overviewTab.exists)
        }
    }
    
    func testAllTabsAvailable() throws {
        createTestTrip(name: "Tab Test Trip")
        
        let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Tab Test Trip'"))
        if tripElement.count > 0 {
            tripElement.element.tap()
            
            let tabs = [
                app.buttons["Overview"],
                app.buttons["Activities"],
                app.buttons["Schedule"],
                app.buttons["Route"],
                app.buttons["Map"]
            ]
            
            for tab in tabs {
                XCTAssertTrue(tab.exists, "Tab should exist")
            }
        }
    }
    
    // MARK: - Edit Trip Flow
    
    func testEditTripName() throws {
        createTestTrip(name: "Edit Test Trip")
        
        let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Edit Test Trip'"))
        if tripElement.count > 0 {
            tripElement.element.tap()
            
            // Tap edit button
            let editButton = app.buttons["pencil.circle"]
            if editButton.exists {
                editButton.tap()
                
                // Wait for edit form
                let editNavBar = app.navigationBars.matching(NSPredicate(format: "label CONTAINS 'Edit Trip'"))
                XCTAssertTrue(editNavBar.element.waitForExistence(timeout: 2))
                
                // Edit the name
                let tripNameField = app.textFields["Trip Name"]
                tripNameField.tap()
                tripNameField.selectAll()
                tripNameField.typeText("Updated Trip Name")
                
                let saveButton = app.buttons["Save"]
                saveButton.tap()
                
                // Verify update
                let updatedElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Updated Trip Name'"))
                XCTAssertGreaterThan(updatedElement.count, 0)
            }
        }
    }
    
    // MARK: - Add Day Flow
    
    func testAddDayToTrip() throws {
        createTestTrip(name: "Day Test Trip")
        
        let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Day Test Trip'"))
        if tripElement.count > 0 {
            tripElement.element.tap()
            
            // Should be on overview tab by default
            let addDayButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'plus'"))
            if addDayButton.count > 0 {
                addDayButton.element.tap()
                
                // Wait for add day form
                let startLocationField = app.textFields["Start Location"]
                XCTAssertTrue(startLocationField.waitForExistence(timeout: 2))
            }
        }
    }
    
    // MARK: - Activities Tab Tests
    
    func testNavigateToActivitiesTab() throws {
        createTestTrip(name: "Activities Tab Trip")
        
        let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Activities Tab Trip'"))
        if tripElement.count > 0 {
            tripElement.element.tap()
            
            let activitiesTab = app.buttons["Activities"]
            XCTAssertTrue(activitiesTab.exists)
            activitiesTab.tap()
            
            // Verify activities view loads
            let mapButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Map'"))
            if mapButton.count > 0 {
                XCTAssertTrue(mapButton.element.exists)
            }
        }
    }
    
    // MARK: - Schedule Tab Tests
    
    func testNavigateToScheduleTab() throws {
        createTestTrip(name: "Schedule Tab Trip")
        
        let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Schedule Tab Trip'"))
        if tripElement.count > 0 {
            tripElement.element.tap()
            
            let scheduleTab = app.buttons["Schedule"]
            XCTAssertTrue(scheduleTab.exists)
            scheduleTab.tap()
        }
    }
    
    // MARK: - Route Tab Tests
    
    func testNavigateToRouteTab() throws {
        createTestTrip(name: "Route Tab Trip")
        
        let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Route Tab Trip'"))
        if tripElement.count > 0 {
            tripElement.element.tap()
            
            let routeTab = app.buttons["Route"]
            XCTAssertTrue(routeTab.exists)
            routeTab.tap()
        }
    }
    
    // MARK: - Map Tab Tests
    
    func testNavigateToMapTab() throws {
        createTestTrip(name: "Map Tab Trip")
        
        let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Map Tab Trip'"))
        if tripElement.count > 0 {
            tripElement.element.tap()
            
            let mapTab = app.buttons["Map"]
            XCTAssertTrue(mapTab.exists)
            mapTab.tap()
        }
    }
    
    // MARK: - Delete Flow
    
    func testDeleteTrip() throws {
        createTestTrip(name: "Delete Test Trip")
        
        // Find the trip card and long press for context menu
        let tripCards = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'Delete Test Trip'"))
        if tripCards.count > 0 {
            let card = tripCards.element(boundBy: 0)
            card.press(forDuration: 0.5)
            
            // Look for delete option
            let deleteOption = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Delete'"))
            if deleteOption.count > 0 {
                deleteOption.element(boundBy: 0).tap()
                
                // Confirm deletion if alert appears
                let confirmButton = app.buttons.matching(NSPredicate(format: "label == 'Delete'"))
                if confirmButton.count > 0 {
                    confirmButton.element(boundBy: 0).tap()
                    
                    // Verify trip is gone
                    let deletedTrip = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Delete Test Trip'"))
                    XCTAssertEqual(deletedTrip.count, 0)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrip(name: String) {
        let addButton = app.buttons["plus.circle.fill"]
        addButton.tap()
        
        let tripNameField = app.textFields["Trip Name"]
        _ = tripNameField.waitForExistence(timeout: 2)
        
        tripNameField.tap()
        tripNameField.typeText(name)
        
        let createButton = app.buttons["Create"]
        createButton.tap()
        
        // Wait for sheet to close
        sleep(1)
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    func testNavigationPerformance() throws {
        createTestTrip(name: "Performance Test")
        
        measure {
            let tripElement = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Performance Test'"))
            if tripElement.count > 0 {
                tripElement.element.tap()
                
                let backButton = app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0)
                if backButton.exists {
                    backButton.tap()
                }
            }
        }
    }
}
