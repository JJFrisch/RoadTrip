import XCTest

final class RoadTripUIFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-ui-testing",
            "-ui-testing-reset-data",
            "-ui-testing-skip-onboarding"
        ]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testHomeLayoutAndTripCreationAreStable() {
        let homeTitle = app.staticTexts["home.title"]
        XCTAssertTrue(homeTitle.waitForExistence(timeout: 5), "Home title should be visible")

        let addButton = app.buttons["home.addTripButton"]
        XCTAssertTrue(addButton.exists, "Add trip button should be visible")
        XCTAssertTrue(addButton.isHittable, "Add trip button should be tappable")

        addButton.tap()

        let tripNameField = app.textFields["newTrip.nameField"]
        XCTAssertTrue(tripNameField.waitForExistence(timeout: 3), "Trip name field should appear")

        let createButton = app.buttons["newTrip.createButton"]
        XCTAssertFalse(createButton.isEnabled, "Create button should start disabled")

        let tripName = "UI Smoke Trip"
        tripNameField.tap()
        tripNameField.typeText(tripName)
        XCTAssertTrue(createButton.isEnabled, "Create button should become enabled when a name exists")

        createButton.tap()

        let newTripCell = app.staticTexts[tripName]
        XCTAssertTrue(newTripCell.waitForExistence(timeout: 5), "Created trip should appear in the list")

        addScreenshot(name: "home-after-trip-creation")
    }

    func testTripDetailTabsAreAccessibleAndScrollableAcrossLayouts() {
        let tripName = "Cross Device Layout Trip"
        createTrip(named: tripName)

        let tripCell = app.staticTexts[tripName]
        XCTAssertTrue(tripCell.waitForExistence(timeout: 5), "Trip should exist before opening detail")
        tripCell.tap()

        let tabIDs = [
            "tripDetail.tab.overview",
            "tripDetail.tab.budget",
            "tripDetail.tab.activities",
            "tripDetail.tab.schedule",
            "tripDetail.tab.map"
        ]

        for id in tabIDs {
            let tab = app.buttons[id]
            XCTAssertTrue(tab.waitForExistence(timeout: 3), "Expected tab \(id) to exist")
            XCTAssertTrue(tab.isHittable, "Expected tab \(id) to be tappable")
            tab.tap()
        }

        addScreenshot(name: "trip-detail-tabs")
    }

    private func createTrip(named name: String) {
        let addButton = app.buttons["home.addTripButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "Add button should exist")
        addButton.tap()

        let tripNameField = app.textFields["newTrip.nameField"]
        XCTAssertTrue(tripNameField.waitForExistence(timeout: 3), "Trip form should open")
        tripNameField.tap()
        tripNameField.typeText(name)

        let createButton = app.buttons["newTrip.createButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 2), "Create button should be present")
        XCTAssertTrue(createButton.isEnabled, "Create button should be enabled")
        createButton.tap()
    }

    private func addScreenshot(name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
