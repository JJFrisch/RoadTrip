//
//  DarkModeRefinement.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import SwiftUI

// MARK: - Dark Mode Color Palette

struct DarkModeColors {
    // Background Colors
    static let darkBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 1.0)
            : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
    })
    
    static let darkCardBackground = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 1.0)
            : UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    })
    
    // Text Colors with proper contrast
    static let primaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0) // WCAG AAA
            : UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1.0)
    })
    
    static let secondaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.70, green: 0.70, blue: 0.75, alpha: 1.0) // WCAG AA
            : UIColor(red: 0.40, green: 0.40, blue: 0.45, alpha: 1.0)
    })
    
    static let tertiaryText = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.55, green: 0.55, blue: 0.60, alpha: 1.0)
            : UIColor(red: 0.55, green: 0.55, blue: 0.60, alpha: 1.0)
    })
    
    // Accent Colors (high contrast)
    static let accentBlue = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.80, blue: 1.0, alpha: 1.0) // Lighter for dark mode
            : UIColor(red: 0.00, green: 0.48, blue: 1.0, alpha: 1.0)
    })
    
    static let accentGreen = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.90, blue: 0.50, alpha: 1.0)
            : UIColor(red: 0.20, green: 0.80, blue: 0.30, alpha: 1.0)
    })
    
    // Map Colors
    static let mapPin = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.40, blue: 0.40, alpha: 1.0)
            : UIColor(red: 1.0, green: 0.20, blue: 0.20, alpha: 1.0)
    })
}

// MARK: - Dark Mode Safe View Modifiers

extension View {
    func darkModeBackground() -> some View {
        self
            .background(DarkModeColors.darkBackground)
    }
    
    func darkModeCardBackground() -> some View {
        self
            .background(DarkModeColors.darkCardBackground)
            .cornerRadius(12)
    }
    
    func darkModePrimaryText() -> some View {
        self
            .foregroundStyle(DarkModeColors.primaryText)
    }
    
    func darkModeSecondaryText() -> some View {
        self
            .foregroundStyle(DarkModeColors.secondaryText)
    }
    
    func highContrastSupport() -> some View {
        // Placeholder for high-contrast tweaks; environment key unavailable on older SDKs
        self
    }
}

// MARK: - Map Visibility Helper

struct MapDarkModeHelper {
    @Environment(\.colorScheme) var colorScheme
    
    /// Adjust map overlay opacity for dark mode visibility
    static func mapOverlayOpacity(for colorScheme: ColorScheme) -> Double {
        colorScheme == .dark ? 0.7 : 0.5
    }
    
    /// Get readable text color for map labels
    static func mapLabelColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .white : .black
    }
    
    /// Get proper background for map buttons
    static func mapButtonBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(UIColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.9))
            : Color(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.95))
    }
}

// MARK: - Dark Mode Safe Text Fields & Inputs

struct DarkModeSafeTextField: View {
    let placeholder: String
    @Binding var text: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                colorScheme == .dark
                    ? Color(UIColor(red: 0.20, green: 0.20, blue: 0.23, alpha: 1.0))
                    : Color(UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0))
            )
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        colorScheme == .dark
                            ? Color.white.opacity(0.2)
                            : Color.black.opacity(0.1),
                        lineWidth: 1
                    )
            )
            .foregroundColor(DarkModeColors.primaryText)
    }
}

// MARK: - Accessible Color Contrast Checker

struct ColorContrastInfo {
    let foreground: UIColor
    let background: UIColor
    
    /// Calculate WCAG contrast ratio
    var contrastRatio: Double {
        let foregroundLuminance = luminance(foreground)
        let backgroundLuminance = luminance(background)
        
        let lighter = max(foregroundLuminance, backgroundLuminance)
        let darker = min(foregroundLuminance, backgroundLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Check if contrast meets WCAG AA standard (4.5:1 for text)
    var meetsWCAGAA: Bool {
        contrastRatio >= 4.5
    }
    
    /// Check if contrast meets WCAG AAA standard (7:1 for text)
    var meetsWCAGAAA: Bool {
        contrastRatio >= 7.0
    }
    
    private func luminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate relative luminance
        let r = red <= 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        let g = green <= 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        let b = blue <= 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
}

// MARK: - Dark Mode Audit Checklist

struct DarkModeAuditView: View {
    @State private var auditResults: [AuditItem] = [
        AuditItem(name: "Background Colors", status: .pass),
        AuditItem(name: "Text Contrast", status: .pass),
        AuditItem(name: "Accent Colors", status: .pass),
        AuditItem(name: "Map Readability", status: .pending),
        AuditItem(name: "Form Inputs", status: .pass),
        AuditItem(name: "Buttons", status: .pass),
        AuditItem(name: "Images", status: .pending),
        AuditItem(name: "Shadows", status: .pass),
        AuditItem(name: "Borders", status: .pass),
        AuditItem(name: "Icons", status: .pass),
    ]
    
    struct AuditItem: Identifiable {
        let id = UUID()
        let name: String
        var status: Status
        
        enum Status {
            case pass
            case warning
            case fail
            case pending
            
            var icon: String {
                switch self {
                case .pass: return "checkmark.circle.fill"
                case .warning: return "exclamationmark.circle.fill"
                case .fail: return "xmark.circle.fill"
                case .pending: return "questionmark.circle.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .pass: return .green
                case .warning: return .orange
                case .fail: return .red
                case .pending: return .gray
                }
            }
        }
    }
    
    var body: some View {
        List {
            Section("Dark Mode Compatibility") {
                ForEach($auditResults) { $item in
                    HStack {
                        Image(systemName: item.status.icon)
                            .foregroundStyle(item.status.color)
                        
                        Text(item.name)
                        
                        Spacer()
                        
                        Picker("Status", selection: $item.status) {
                            Text("Pass").tag(AuditItem.Status.pass)
                            Text("Warning").tag(AuditItem.Status.warning)
                            Text("Fail").tag(AuditItem.Status.fail)
                            Text("Pending").tag(AuditItem.Status.pending)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }
                }
            }
            
            Section("Summary") {
                let passCount = auditResults.filter { $0.status == .pass }.count
                let totalCount = auditResults.count
                
                HStack {
                    Text("Audit Progress")
                    Spacer()
                    ProgressView(value: Double(passCount), total: Double(totalCount))
                        .frame(width: 80)
                }
                
                Text("\(passCount)/\(totalCount) items passing")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Dark Mode Audit")
    }
}

// MARK: - Dark Mode Preview Wrapper

#if DEBUG
struct DarkModePreview<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Group {
            content()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            content()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
#endif
