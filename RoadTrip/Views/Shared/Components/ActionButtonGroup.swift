// Views/Shared/Components/ActionButtonGroup.swift
import SwiftUI

/// A polished button group for consistent action layouts (e.g., Save/Cancel, Confirm/Reject).
/// Handles proper spacing, alignment, and style consistency.
///
/// Usage:
/// ```
/// ActionButtonGroup(
///     primaryTitle: "Save",
///     primaryAction: { saveTrip() },
///     secondaryTitle: "Cancel",
///     secondaryAction: { dismiss() }
/// )
/// ```
struct ActionButtonGroup: View {
    let primaryTitle: String
    let primaryAction: () -> Void
    let primaryStyle: ActionStyle
    
    let secondaryTitle: String?
    let secondaryAction: (() -> Void)?
    let secondaryStyle: ActionStyle
    
    let tertiaryTitle: String?
    let tertiaryAction: (() -> Void)?
    
    enum ActionStyle {
        case primary
        case secondary
        case destructive
    }
    
    init(
        primaryTitle: String,
        primaryAction: @escaping () -> Void,
        primaryStyle: ActionStyle = .primary,
        secondaryTitle: String? = "Cancel",
        secondaryAction: (() -> Void)? = nil,
        secondaryStyle: ActionStyle = .secondary,
        tertiaryTitle: String? = nil,
        tertiaryAction: (() -> Void)? = nil
    ) {
        self.primaryTitle = primaryTitle
        self.primaryAction = primaryAction
        self.primaryStyle = primaryStyle
        self.secondaryTitle = secondaryTitle
        self.secondaryAction = secondaryAction
        self.secondaryStyle = secondaryStyle
        self.tertiaryTitle = tertiaryTitle
        self.tertiaryAction = tertiaryAction
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Primary action
            Button(action: primaryAction) {
                Text(primaryTitle)
            }
            .buttonStyle(styleForAction(primaryStyle))
            
            // Secondary action (if provided)
            if let secondaryTitle = secondaryTitle, let secondaryAction = secondaryAction {
                Button(action: secondaryAction) {
                    Text(secondaryTitle)
                }
                .buttonStyle(styleForAction(secondaryStyle))
            }
            
            // Tertiary action (if provided) - text-only, subtle
            if let tertiaryTitle = tertiaryTitle, let tertiaryAction = tertiaryAction {
                Button(action: tertiaryAction) {
                    Text(tertiaryTitle)
                }
                .tertiaryButton()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.lg)
    }
    
    private func styleForAction(_ style: ActionStyle) -> some ButtonStyle {
        switch style {
        case .primary:
            return AnyButtonStyle(PrimaryButtonStyle())
        case .secondary:
            return AnyButtonStyle(SecondaryButtonStyle())
        case .destructive:
            return AnyButtonStyle(DestructiveButtonStyle())
        }
    }
}

// Type-erased button style wrapper (same as in ConfirmationSheet)
private struct AnyButtonStyle: ButtonStyle {
    private let _makeBody: (Configuration) -> AnyView
    
    init<S: ButtonStyle>(_ style: S) {
        _makeBody = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }
    
    func makeBody(configuration: Configuration) -> some View {
        _makeBody(configuration)
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        
        VStack {
            Text("Example: Save/Cancel Actions")
                .font(.headline)
            
            Spacer()
            
            ActionButtonGroup(
                primaryTitle: "Save Trip",
                primaryAction: { print("Saved") },
                secondaryTitle: "Cancel",
                secondaryAction: { print("Cancelled") }
            )
            
            Divider()
                .padding(.vertical, AppTheme.Spacing.lg)
            
            Text("Example: Delete with Tertiary")
                .font(.headline)
            
            ActionButtonGroup(
                primaryTitle: "Delete Trip",
                primaryAction: { print("Deleted") },
                primaryStyle: .destructive,
                tertiaryTitle: "Never mind",
                tertiaryAction: { print("Cancelled") }
            )
            
            Spacer()
        }
        .padding()
    }
}
