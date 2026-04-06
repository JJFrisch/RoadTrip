// Views/Shared/Components/FormSection.swift
import SwiftUI

/// A polished form section container with optional header, subtitle, and divider support.
/// Replaces generic VStack + manual styling for clear visual hierarchy and consistency.
///
/// Usage:
/// ```
/// FormSection("Trip Details") {
///     TextField("Trip Name", text: $tripName)
///     TextField("Description", text: $description)
/// }
/// ```
struct FormSection<Content: View>: View {
    let title: String?
    let subtitle: String?
    let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    init(_ title: String? = nil, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Header with title and optional subtitle
            if let title = title {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(AppTheme.Typography.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption2)
                            .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            
            // Content container with border and background
            VStack(spacing: 0) {
                content
                    .padding(AppTheme.Spacing.md)
            }
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

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        
        VStack(spacing: AppTheme.Spacing.lg) {
            FormSection("Personal Info", subtitle: "Enter your details") {
                VStack(spacing: AppTheme.Spacing.md) {
                    TextField("Name", text: .constant("John Doe"))
                    TextField("Email", text: .constant("john@example.com"))
                }
            }
            
            FormSection("Trip Details") {
                VStack(spacing: AppTheme.Spacing.md) {
                    TextField("Trip Name", text: .constant("Summer Vacation"))
                }
            }
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.lg)
    }
}
