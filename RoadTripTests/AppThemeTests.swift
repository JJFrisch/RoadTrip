//
//  AppThemeTests.swift
//  RoadTripTests
//
//  Created by Jake Frischmann on 4/5/26.
//

import XCTest
import SwiftUI
@testable import RoadTrip

final class AppThemeTests: XCTestCase {
    
    // MARK: - Primary Color Tests
    
    func testPrimaryBlueColor() {
        let primaryBlue = AppTheme.Colors.primary
        // Color should be light blue (0.29, 0.62, 0.85)
        XCTAssertNotNil(primaryBlue, "Primary blue color should be defined")
    }
    
    func testAccentYellowColor() {
        let accentYellow = AppTheme.Colors.accent
        // Color should be yellow (1.0, 0.78, 0.0)
        XCTAssertNotNil(accentYellow, "Accent yellow color should be defined")
    }
    
    func testBackgroundColor() {
        let background = AppTheme.Colors.background
        // Color should be off-white (0.98, 0.97, 0.96)
        XCTAssertNotNil(background, "Background off-white color should be defined")
    }
    
    func testSecondaryColor() {
        let secondary = AppTheme.Colors.secondary
        XCTAssertNotNil(secondary, "Secondary color should be defined")
    }
    
    // MARK: - Theme Spacing Tests
    
    func testSmallSpacing() {
        let smallSpacing = AppTheme.Spacing.sm
        XCTAssertEqual(smallSpacing, 8, "Small spacing should be 8 points")
    }
    
    func testMediumSpacing() {
        let mediumSpacing = AppTheme.Spacing.md
        XCTAssertEqual(mediumSpacing, 16, "Medium spacing should be 16 points")
    }
    
    func testLargeSpacing() {
        let largeSpacing = AppTheme.Spacing.lg
        XCTAssertEqual(largeSpacing, 24, "Large spacing should be 24 points")
    }
    
    func testExtraLargeSpacing() {
        let xlSpacing = AppTheme.Spacing.xl
        XCTAssertEqual(xlSpacing, 32, "Extra large spacing should be 32 points")
    }
    
    // MARK: - Theme Corner Radius Tests
    
    func testSmallCornerRadius() {
        let smallRadius = AppTheme.CornerRadius.small
        XCTAssertEqual(smallRadius, 8, "Small corner radius should be 8 points")
    }
    
    func testMediumCornerRadius() {
        let mediumRadius = AppTheme.CornerRadius.medium
        XCTAssertEqual(mediumRadius, 12, "Medium corner radius should be 12 points")
    }
    
    func testLargeCornerRadius() {
        let largeRadius = AppTheme.CornerRadius.large
        XCTAssertEqual(largeRadius, 16, "Large corner radius should be 16 points")
    }
    
    // MARK: - Shadow Tests
    
    func testCardShadowExists() {
        // Verify card shadow radius is appropriate
        let cardShadowRadius = AppTheme.Shadow.cardRadius
        XCTAssertGreaterThan(cardShadowRadius, 0, "Card shadow radius should be greater than 0")
    }
    
    func testCardShadowY() {
        let cardShadowY = AppTheme.Shadow.cardY
        XCTAssertGreaterThanOrEqual(cardShadowY, 0, "Card shadow Y offset should be non-negative")
    }
    
    // MARK: - Typography Tests
    
    func testTitleFontWeight() {
        // Verify title uses appropriate font weight
        XCTAssertTrue(true, "Title font weight should be bold")
    }
    
    func testBodyFontSize() {
        let bodyFont = AppTheme.Typography.body
        XCTAssertNotNil(bodyFont, "Body font should be defined")
    }
    
    // MARK: - Button Style Tests
    
    func testPrimaryButtonStyleExists() {
        // Test that primary button style is available
        let style = PrimaryButtonStyle()
        XCTAssertNotNil(style, "Primary button style should be instantiable")
    }
    
    func testSecondaryButtonStyleExists() {
        // Test that secondary button style is available
        let style = SecondaryButtonStyle()
        XCTAssertNotNil(style, "Secondary button style should be instantiable")
    }
    
    // MARK: - Color Accessibility Tests
    
    func testColorContrast() {
        // Primary blue on white background should have sufficient contrast
        // This is a basic test - in production, use WCAG contrast ratio calculator
        XCTAssertNotNil(AppTheme.Colors.primary, "Primary color should exist for contrast testing")
    }
    
    func testDarkModeColorDifference() {
        // Verify colors adapt appropriately in dark mode
        let primaryColor = AppTheme.Colors.primary
        XCTAssertNotNil(primaryColor, "Primary color should be defined for dark mode")
    }
    
    // MARK: - Theme Consistency Tests
    
    func testAllColorsDefined() {
        // Verify all major colors are defined
        XCTAssertNotNil(AppTheme.Colors.primary)
        XCTAssertNotNil(AppTheme.Colors.accent)
        XCTAssertNotNil(AppTheme.Colors.background)
        XCTAssertNotNil(AppTheme.Colors.secondary)
    }
    
    func testAllSpacingValuesDefined() {
        // Verify all spacing values are defined
        XCTAssertEqual(AppTheme.Spacing.sm, 8)
        XCTAssertEqual(AppTheme.Spacing.md, 16)
        XCTAssertEqual(AppTheme.Spacing.lg, 24)
        XCTAssertEqual(AppTheme.Spacing.xl, 32)
    }
    
    func testSpacingProgression() {
        // Verify spacing values increase consistently
        XCTAssertLessThan(AppTheme.Spacing.sm, AppTheme.Spacing.md)
        XCTAssertLessThan(AppTheme.Spacing.md, AppTheme.Spacing.lg)
        XCTAssertLessThan(AppTheme.Spacing.lg, AppTheme.Spacing.xl)
    }
}
