// Theme/AppTheme.swift
import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        static let primary = Color.blue
        static let secondary = Color.gray
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let info = Color.cyan
        
        // Category colors
        static let foodColor = Color.orange
        static let attractionColor = Color.blue
        static let hotelColor = Color.purple
        static let defaultColor = Color.gray
        
        // Semantic colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let divider = Color(.separator)
        
        // MARK: - Dark Mode Optimized Colors
        
        // Map marker colors - adaptive for dark mode
        static let mapMarkerStart = AdaptiveColor(light: .green, dark: Color(red: 0.4, green: 0.9, blue: 0.5))
        static let mapMarkerEnd = AdaptiveColor(light: .red, dark: Color(red: 1.0, green: 0.4, blue: 0.4))
        static let mapMarkerHotel = AdaptiveColor(light: .purple, dark: Color(red: 0.7, green: 0.5, blue: 1.0))
        static let mapRoute = AdaptiveColor(light: Color.blue, dark: Color(red: 0.4, green: 0.7, blue: 1.0))
        
        // Gradient colors - adaptive
        static let gradientStart = AdaptiveColor(light: Color.blue.opacity(0.6), dark: Color.blue.opacity(0.4))
        static let gradientEnd = AdaptiveColor(light: Color.purple.opacity(0.4), dark: Color.purple.opacity(0.3))
        
        // Card background
        static let cardBackground = AdaptiveColor(light: Color.white, dark: Color(.secondarySystemBackground))
        
        // Text colors
        static let primaryText = AdaptiveColor(light: Color.primary, dark: Color.white)
        static let secondaryText = AdaptiveColor(light: Color.secondary, dark: Color(.systemGray))
    }
    
    // Helper for adaptive colors
    struct AdaptiveColor {
        let light: Color
        let dark: Color
        
        func color(for scheme: ColorScheme) -> Color {
            scheme == .dark ? dark : light
        }
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle: Font = .system(size: 32, weight: .bold)
        static let title1: Font = .system(size: 28, weight: .bold)
        static let title2: Font = .system(size: 22, weight: .bold)
        static let title3: Font = .system(size: 20, weight: .semibold)
        static let headline: Font = .system(size: 17, weight: .semibold)
        static let body: Font = .system(size: 17, weight: .regular)
        static let callout: Font = .system(size: 16, weight: .regular)
        static let subheadline: Font = .system(size: 15, weight: .semibold)
        static let footnote: Font = .system(size: 13, weight: .regular)
        static let caption1: Font = .system(size: 12, weight: .regular)
        static let caption2: Font = .system(size: 11, weight: .regular)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
    
    // MARK: - Corners
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let fast: Double = 0.2
        static let normal: Double = 0.3
        static let slow: Double = 0.5
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Reusable View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.secondaryBackground)
            .cornerRadius(AppTheme.CornerRadius.large)
            .shadow(color: AppTheme.Shadows.small.color, radius: AppTheme.Shadows.small.radius, x: AppTheme.Shadows.small.x, y: AppTheme.Shadows.small.y)
    }
}

struct FormSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .listRowBackground(AppTheme.Colors.secondaryBackground)
            .listRowSeparator(.hidden)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.primary)
            .cornerRadius(AppTheme.CornerRadius.large)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.headline)
            .foregroundStyle(AppTheme.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.Colors.primary.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.large)
            .border(AppTheme.Colors.primary.opacity(0.3), width: 1)
            .opacity(configuration.isPressed ? 0.7 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func formSectionStyle() -> some View {
        modifier(FormSectionStyle())
    }
    
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
}
