// Utilities/LoadingView.swift
import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(AppTheme.Typography.callout)
                .foregroundStyle(AppTheme.Colors.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

struct ErrorView: View {
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String
    
    init(title: String, message: String, actionTitle: String = "Retry", action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.danger)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "arrow.clockwise")
                }
                .primaryButton()
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.Colors.secondary)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Text(title)
                    .font(AppTheme.Typography.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.Colors.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Label(actionTitle, systemImage: "plus.circle")
                }
                .primaryButton()
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.background)
    }
}

// Loading state container
struct LoadingStateContainer<Content: View>: View {
    let isLoading: Bool
    let hasError: Bool
    let errorTitle: String?
    let errorMessage: String?
    let retryAction: (() -> Void)?
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        if isLoading {
            LoadingView()
        } else if hasError {
            ErrorView(
                title: errorTitle ?? "Error",
                message: errorMessage ?? "Something went wrong",
                action: retryAction
            )
        } else {
            content()
        }
    }
}

// Placeholder shimmer effect
struct PlaceholderView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(AppTheme.Colors.secondaryBackground)
                .frame(height: 60)
            
            ForEach(0..<3, id: \.self) { _ in
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(AppTheme.Colors.secondaryBackground)
                    .frame(height: 20)
            }
        }
        .padding(AppTheme.Spacing.md)
        .cardStyle()
    }
}
