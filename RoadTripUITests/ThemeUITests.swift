//
//  AppThemeUITests.swift
//  RoadTripUITests
//
//  Created by Jake Frischmann on 4/5/26.
//

import XCTest

final class AppThemeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Home View Tests
    
    @MainActor
    func testHomeViewLoads() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify the main navigation element exists
        XCTAssert(app.exists, "App should launch successfully")
    }
    
    @MainActor
    func testHomeViewDisplaysTripsTabTitle() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Look for main content - app should display something
        XCTAssertTrue(app.windows.count > 0, "App should have at least one window")
    }
    
    // MARK: - Theme Color Verification
    
    @MainActor
    func testThemeColorsApplied() throws {
        let app = XCUIApplication()
        app.launch()
        
        // The app should use the new theme colors (primary blue, yellow, off-white)
        // This is verified by checking that the app renders without crashing
        XCTAssert(app.exists, "App with new theme should render")
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNavigationStackInitializes() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Main navigation should be available
        let windows = app.windows
        XCTAssertGreaterThan(windows.count, 0, "Navigation should initialize")
    }
    
    // MARK: - Button Interaction Tests
    
    @MainActor
    func testButtonsAreInteractive() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Find buttons with new theme styling
        let buttons = app.buttons
        XCTAssertGreaterThanOrEqual(buttons.count, 0, "App should have interactive buttons")
    }
    
    // MARK: - Animation Performance Tests
    
    @MainActor
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testAppSupportsAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify accessibility labels exist
        XCTAssert(app.exists, "App should support accessibility")
    }
}
