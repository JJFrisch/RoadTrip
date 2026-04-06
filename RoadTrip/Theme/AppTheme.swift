// Theme/AppTheme.swift
import SwiftUI

struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // New color palette: Light blue, yellow, off-white
        static let primary = Color(red: 0.29, green: 0.62, blue: 0.85)  // Light blue
        static let primaryDark = Color(red: 0.20, green: 0.52, blue: 0.75)  // Darker blue for hover
        static let accent = Color(red: 1.0, green: 0.78, blue: 0.0)  // Warm yellow
        static let accentLight = Color(red: 1.0, green: 0.90, blue: 0.4)  // Light yellow
        
        static let secondary = Color.gray
        static let success = Color.green
        static let warning = Color.orange
        static let danger = Color.red
        static let info = Color.cyan
        
        // Category colors
        static let foodColor = Color(red: 1.0, green: 0.78, blue: 0.0)  // Yellow for food
        static let attractionColor = Color(red: 0.29, green: 0.62, blue: 0.85)  // Light blue for attractions
        static let hotelColor = Color(red: 0.29, green: 0.62, blue: 0.85)  // Light blue for hotels
        static let defaultColor = Color.gray
        
        // Semantic colors - Off-white backgrounds
        static let background = Color(red: 0.98, green: 0.97, blue: 0.96)  // Off-white
        static let secondaryBackground = Color.white  // White for cards
        static let divider = Color.gray.opacity(0.2)
        
        // MARK: - Dark Mode Optimized Colors
        
        // Map marker colors - adaptive for dark mode
        static let mapMarkerStart = AdaptiveColor(
            light: Color.green,
            dark: Color(red: 0.4, green: 0.9, blue: 0.5)
        )
        static let mapMarkerEnd = AdaptiveColor(
            light: Color.red,
            dark: Color(red: 1.0, green: 0.4, blue: 0.4)
        )
        static let mapMarkerHotel = AdaptiveColor(
            light: Color(red: 0.29, green: 0.62, blue: 0.85),
            dark: Color(red: 0.4, green: 0.7, blue: 1.0)
        )
        static let mapRoute = AdaptiveColor(
            light: Color(red: 0.29, green: 0.62, blue: 0.85),
            dark: Color(red: 0.4, green: 0.7, blue: 1.0)
        )
        
        // Gradient colors - light blue to yellow
        static let gradientStart = AdaptiveColor(
            light: Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.8),
            dark: Color(red: 0.29, green: 0.62, blue: 0.85).opacity(0.6)
        )
        static let gradientEnd = AdaptiveColor(
            light: Color(red: 1.0, green: 0.78, blue: 0.0).opacity(0.6),
            dark: Color(red: 1.0, green: 0.78, blue: 0.0).opacity(0.4)
        )
        
        // Card background
        static let cardBackground = AdaptiveColor(
            light: Color.white,
            dark: Color(red: 0.15, green: 0.15, blue: 0.15)
        )
        
        // Text colors
        static let primaryText = AdaptiveColor(
            light: Color(red: 0.2, green: 0.2, blue: 0.2),
            dark: Color.white
        )
        static let secondaryText = AdaptiveColor(
            light: Color.gray,
            dark: Color(.systemGray)
        )
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
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppTheme.Colors.primary,
                        AppTheme.Colors.primaryDark
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(AppTheme.CornerRadius.large)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .brightness(configuration.isPressed ? -0.1 : 0)
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
            .brightness(configuration.isPressed ? -0.05 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

    // MARK: - Destructive Button (Red, for delete/cancel actions)
    struct DestructiveButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(AppTheme.Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.danger.opacity(0.9))
                .cornerRadius(AppTheme.CornerRadius.large)
                .opacity(configuration.isPressed ? 0.8 : 1)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
        }
    }

    // MARK: - Tertiary Button (Text-only, for less important actions)
    struct TertiaryButtonStyle: ButtonStyle {
        var foregroundColor: Color = AppTheme.Colors.primary
    
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(AppTheme.Typography.body)
                .foregroundStyle(foregroundColor)
                .padding(AppTheme.Spacing.sm)
                .opacity(configuration.isPressed ? 0.6 : 1)
        }
    }

    // MARK: - Enhanced Form Section (for custom form-like layouts)
    struct EnhancedFormSection: ViewModifier {
        let title: String?
        let subtitle: String?
        @Environment(\.colorScheme) private var colorScheme
    
        func body(content: Content) -> some View {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                if let title = title {
                    Text(title)
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                        .textCase(.none)
                }
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                }
                content
                    .padding(AppTheme.Spacing.md)
                    .background(AppTheme.Colors.secondaryBackground)
                    .cornerRadius(AppTheme.CornerRadius.large)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(AppTheme.Colors.divider, lineWidth: 1)
                    )
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
    }

    // MARK: - Styled Text Field (with label and helper text)
    struct StyledTextFieldStyle: ViewModifier {
        let label: String
        let isValid: Bool
        let errorMessage: String?
        @Environment(\.colorScheme) private var colorScheme
    
        @FocusState private var isFocused: Bool
    
        func body(content: Content) -> some View {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(label)
                    .font(AppTheme.Typography.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
            
                content
                    .font(AppTheme.Typography.body)
                    .padding(AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.background)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(
                                isValid || !isFocused ? AppTheme.Colors.divider : AppTheme.Colors.danger.opacity(0.5),
                                lineWidth: isFocused ? 2 : 1
                            )
                    )
                    .focused($isFocused)
            
                if let errorMessage = errorMessage, !isValid {
                    Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                        .font(AppTheme.Typography.caption2)
                        .foregroundStyle(AppTheme.Colors.danger)
                }
            }
        }
    }

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func formSectionStyle() -> some View {
        modifier(FormSectionStyle())
    }
    
        func enhancedFormSection(title: String? = nil, subtitle: String? = nil) -> some View {
            modifier(EnhancedFormSection(title: title, subtitle: subtitle))
        }
    
        func styledTextField(label: String, isValid: Bool = true, errorMessage: String? = nil) -> some View {
            modifier(StyledTextFieldStyle(label: label, isValid: isValid, errorMessage: errorMessage))
        }
    
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
    
        func destructiveButton() -> some View {
            buttonStyle(DestructiveButtonStyle())
        }
    
        func tertiaryButton(foregroundColor: Color = AppTheme.Colors.primary) -> some View {
            buttonStyle(TertiaryButtonStyle(foregroundColor: foregroundColor))
        }
}
