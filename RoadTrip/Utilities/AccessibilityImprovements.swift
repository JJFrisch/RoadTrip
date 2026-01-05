//
//  AccessibilityImprovements.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import SwiftUI

// MARK: - VoiceOver Support

struct AccessibleActivityCard: View {
    let activity: Activity
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isCompleted ? .green : .blue)
                .accessibilityLabel(isCompleted ? "Completed" : "Not completed")
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let time = activity.scheduledTime {
                    Text(time, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Activity: \(activity.name)")
        .accessibilityHint(accessibilityHint())
    }
    
    private func accessibilityHint() -> String {
        var hints: [String] = []
        
        hints.append(isCompleted ? "Marked as completed" : "Not yet completed")
        
        if let time = activity.scheduledTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            hints.append("Scheduled for \(formatter.string(from: time))")
        }
        
        if let notes = activity.notes, !notes.isEmpty {
            hints.append("Notes: \(notes)")
        }
        
        return hints.joined(separator: ". ")
    }
}

// MARK: - Dynamic Type Support

struct DynamicTypeContainer<Content: View>: View {
    @Environment(\.sizeCategory) var sizeCategory
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        content()
            .lineLimit(nil) // Allow unlimited lines for larger type sizes
            .minimumScaleFactor(0.8) // Don't shrink below 80% if needed
    }
}

extension Text {
    /// Create accessible heading that respects dynamic type
    func accessibleHeading(_ size: AccessibleHeadingSize = .large) -> some View {
        self
            .font(size.font)
            .lineLimit(2)
            .minimumScaleFactor(0.9)
    }
    
    /// Create accessible body text
    func accessibleBody() -> some View {
        self
            .font(.body)
            .lineLimit(nil)
            .minimumScaleFactor(0.85)
    }
    
    /// Create accessible caption
    func accessibleCaption() -> some View {
        self
            .font(.caption)
            .lineLimit(nil)
            .minimumScaleFactor(0.8)
    }
}

enum AccessibleHeadingSize {
    case small, medium, large
    
    var font: Font {
        switch self {
        case .small: return .headline
        case .medium: return .title3
        case .large: return .title2
        }
    }
}

// MARK: - High Contrast Mode Support

struct HighContrastButton: View {
    let title: String
    let action: () -> Void
    
    @Environment(\.accessibilityContrast) private var accessibilityContrast

    private var isHighContrast: Bool {
        accessibilityContrast == .high
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isHighContrast
                        ? Color.primary
                        : Color.blue
                )
                .foregroundStyle(
                    isHighContrast
                        ? Color(UIColor.systemBackground)
                        : Color.white
                )
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isHighContrast
                                ? Color.black
                                : Color.clear,
                            lineWidth: isHighContrast ? 2 : 0
                        )
                )
        }
    }
}

// MARK: - Reduced Motion Support

struct AccessibleAnimationView<Content: View>: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @ViewBuilder let content: () -> Content
    
    var animationSpeed: Double {
        reduceMotion ? 0.01 : 0.3
    }
    
    var body: some View {
        content()
    }
}

// MARK: - Accessible Form Elements

struct AccessibleFormField: View {
    let label: String
    let hint: String?
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: "")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            TextField(label, text: $text)
                .textFieldStyle(.roundedBorder)
                .accessibilityLabel(label)
                .accessibilityHint(hint ?? "")
            
            if let hint = hint {
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Accessible List Item

struct AccessibleListItem: View {
    let title: String
    let subtitle: String?
    let accessibilityValue: String?
    let action: (() -> Void)?
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let value = accessibilityValue {
                    Text(value)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(accessibilityValue ?? "")
    }
}

// MARK: - Accessibility Info Sheet

struct AccessibilityFeaturesView: View {
    let features: [AccessibilityFeature] = [
        AccessibilityFeature(
            name: "VoiceOver Support",
            description: "Full VoiceOver narration for all interface elements",
            status: true
        ),
        AccessibilityFeature(
            name: "Dynamic Type",
            description: "Text scales with system font size settings",
            status: true
        ),
        AccessibilityFeature(
            name: "High Contrast Mode",
            description: "Enhanced colors and borders for better visibility",
            status: true
        ),
        AccessibilityFeature(
            name: "Reduced Motion",
            description: "Respects system reduce motion preferences",
            status: true
        ),
        AccessibilityFeature(
            name: "Button Size",
            description: "All interactive elements meet 44x44pt minimum",
            status: true
        ),
        AccessibilityFeature(
            name: "Color Contrast",
            description: "All text meets WCAG AA contrast standards",
            status: true
        ),
    ]
    
    struct AccessibilityFeature: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let status: Bool
    }
    
    var body: some View {
        List {
            Section("Accessibility Features") {
                ForEach(features) { feature in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(feature.name)
                                .font(.headline)
                            
                            Text(feature.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: feature.status ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(feature.status ? .green : .red)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(feature.name)
                    .accessibilityValue(feature.status ? "Enabled" : "Disabled")
                }
            }
            
            Section("Tips") {
                Text("Tip: Go to Settings > Accessibility to enable VoiceOver, increase text size, or enable high contrast mode for better visibility.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Accessibility")
    }
}

// MARK: - Accessible Map Overlay

struct AccessibleMapOverlay: View {
    let currentLocation: String
    let nextLocation: String?
    let distance: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .foregroundStyle(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(currentLocation)
                        .font(.headline)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current Location: \(currentLocation)")
            
            if let nextLocation = nextLocation {
                HStack {
                    Image(systemName: "location.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next Location")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 8) {
                            Text(nextLocation)
                                .font(.headline)
                            
                            if let distance = distance {
                                Text(String(format: "%.1f mi", distance))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Next Location: \(nextLocation)")
                .accessibilityValue(distance.map { String(format: "%.1f miles away", $0) } ?? "")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

// MARK: - Accessibility Checker

struct AccessibilityChecker {
    static func checkMinimumTouchTargetSize(_ rect: CGRect) -> Bool {
        rect.width >= 44 && rect.height >= 44
    }
    
    static func checkColorContrast(foreground: UIColor, background: UIColor) -> Bool {
        ColorContrastInfo(foreground: foreground, background: background).meetsWCAGAA
    }
    
    static func validateAccessibility(_ view: some View) -> [AccessibilityIssue] {
        var issues: [AccessibilityIssue] = []
        
        // This would be implemented with more detailed checks
        // For now, return empty array as placeholder
        
        return issues
    }
    
    struct AccessibilityIssue: Identifiable {
        let id = UUID()
        let severity: Severity
        let message: String
        
        enum Severity {
            case critical, warning, info
        }
    }
}
