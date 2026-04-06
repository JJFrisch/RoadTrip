// Views/Shared/Components/ConfirmationSheet.swift
import SwiftUI

/// A polished confirmation dialog presented as a sheet instead of a generic alert.
/// Better UX for important actions (delete, discard, etc.) with clear visual hierarchy.
///
/// Usage:
/// ```
/// ConfirmationSheet(
///     isPresented: $showDeleteConfirm,
///     title: "Delete Trip?",
///     message: "This action cannot be undone.",
///     actionTitle: "Delete",
///     actionStyle: .destructive,
///     onConfirm: { deleteTrip() }
/// )
/// ```
struct ConfirmationSheet: View {
    @Binding var isPresented: Bool
    let title: String
    let message: String?
    let actionTitle: String
    let cancelTitle: String = "Cancel"
    let actionStyle: ActionStyle
    let onConfirm: () -> Void
    let onCancel: (() -> Void)? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    enum ActionStyle {
        case primary
        case destructive
        case secondary
    }
    
    var body: some View {
        if isPresented {
            ZStack(alignment: .bottom) {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismiss()
                    }
                
                // Sheet content
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text(title)
                            .font(AppTheme.Typography.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                        
                        if let message = message {
                            Text(message)
                                .font(AppTheme.Typography.body)
                                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                .lineLimit(3)
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        Button(action: {
                            onConfirm()
                            dismiss()
                        }) {
                            Text(actionTitle)
                        }
                        .buttonStyle(actionButtonStyle)
                        
                        Button(action: {
                            onCancel?()
                            dismiss()
                        }) {
                            Text(cancelTitle)
                        }
                        .secondaryButton()
                    }
                }
                .padding(AppTheme.Spacing.lg)
                .background(AppTheme.Colors.secondaryBackground)
                .cornerRadius(AppTheme.CornerRadius.extraLarge)
                .padding(AppTheme.Spacing.md)
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
    
    private var actionButtonStyle: some ButtonStyle {
        switch actionStyle {
        case .primary:
            return AnyButtonStyle(PrimaryButtonStyle())
        case .destructive:
            return AnyButtonStyle(DestructiveButtonStyle())
        case .secondary:
            return AnyButtonStyle(SecondaryButtonStyle())
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut(duration: AppTheme.Animation.fast)) {
            isPresented = false
        }
    }
}

// Type-erased button style wrapper
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
    struct PreviewContainer: View {
        @State var showConfirm = true
        
        var body: some View {
            ZStack {
                AppTheme.Colors.background.ignoresSafeArea()
                
                VStack {
                    Button("Trigger Delete Confirmation") {
                        showConfirm = true
                    }
                    .primaryButton()
                    .padding()
                    
                    Spacer()
                }
                
                ConfirmationSheet(
                    isPresented: $showConfirm,
                    title: "Delete Trip?",
                    message: "Deleting 'Summer Vacation' will remove all associated days and activities. This action cannot be undone.",
                    actionTitle: "Delete Trip",
                    actionStyle: .destructive,
                    onConfirm: {
                        print("Trip deleted")
                    }
                )
            }
        }
    }
    
    return PreviewContainer()
}
