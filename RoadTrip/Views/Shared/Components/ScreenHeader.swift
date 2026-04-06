// Views/Shared/Components/ScreenHeader.swift
import SwiftUI

/// A polished screen header with gradient background, title, and optional subtitle.
/// Provides visual hierarchy and brand consistency across screens.
///
/// Usage:
/// ```
/// ScreenHeader("My Trips", subtitle: "Plan your next adventure")
/// ```
struct ScreenHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let backgroundColor: LinearGradient?
    
    var defaultGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                AppTheme.Colors.primary,
                AppTheme.Colors.primaryDark
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        backgroundColor: LinearGradient? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(AppTheme.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.callout)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundStyle(AppTheme.Colors.accent)
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(backgroundColor ?? defaultGradient)
    }
}

#Preview {
    VStack(spacing: 0) {
        ScreenHeader(
            "My Trips",
            subtitle: "Plan your next adventure",
            icon: "airplane.departure"
        )
        
        ScreenHeader(
            "Trip Budget",
            subtitle: "Track your spending",
            icon: "dollarsign.circle.fill",
            backgroundColor: LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.4, green: 0.7, blue: 0.5),
                    Color(red: 0.3, green: 0.6, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        
        Spacer()
    }
}
