//
//  ErrorDialogView.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/4/26.
//

import SwiftUI

// MARK: - Error Dialog Manager
class ErrorDialogManager: ObservableObject {
    static let shared = ErrorDialogManager()
    
    @Published var currentDialog: ErrorDialog?
    @Published var isShowingDialog = false
    
    private init() {}
    
    struct ErrorDialog: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let severity: Severity
        let primaryAction: Action?
        let secondaryAction: Action?
        
        enum Severity {
            case info
            case warning
            case error
            case critical
            
            var icon: String {
                switch self {
                case .info: return "info.circle.fill"
                case .warning: return "exclamationmark.triangle.fill"
                case .error: return "xmark.circle.fill"
                case .critical: return "exclamationmark.octagon.fill"
                }
            }
            
            var color: Color {
                switch self {
                case .info: return .blue
                case .warning: return .orange
                case .error: return .red
                case .critical: return .purple
                }
            }
        }
        
        struct Action {
            let title: String
            let role: ActionRole
            let handler: () -> Void
            
            enum ActionRole {
                case normal
                case destructive
                case cancel
            }
        }
    }
    
    func show(
        title: String,
        message: String,
        severity: ErrorDialog.Severity = .error,
        primaryAction: ErrorDialog.Action? = nil,
        secondaryAction: ErrorDialog.Action? = nil
    ) {
        DispatchQueue.main.async {
            self.currentDialog = ErrorDialog(
                title: title,
                message: message,
                severity: severity,
                primaryAction: primaryAction,
                secondaryAction: secondaryAction
            )
            self.isShowingDialog = true
        }
    }
    
    func showCriticalError(
        title: String,
        message: String,
        onRetry: (() -> Void)? = nil
    ) {
        let retryAction = onRetry != nil ? ErrorDialog.Action(
            title: "Retry",
            role: .normal,
            handler: onRetry!
        ) : nil
        
        let dismissAction = ErrorDialog.Action(
            title: "Dismiss",
            role: .cancel,
            handler: { [weak self] in
                self?.dismiss()
            }
        )
        
        show(
            title: title,
            message: message,
            severity: .critical,
            primaryAction: retryAction,
            secondaryAction: dismissAction
        )
    }
    
    func dismiss() {
        DispatchQueue.main.async {
            self.isShowingDialog = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.currentDialog = nil
            }
        }
    }
}

// MARK: - Error Dialog View
struct ErrorDialogView: View {
    let dialog: ErrorDialogManager.ErrorDialog
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: dialog.severity.icon)
                .font(.system(size: 60))
                .foregroundStyle(dialog.severity.color)
            
            // Title & Message
            VStack(spacing: 8) {
                Text(dialog.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(dialog.message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Actions
            VStack(spacing: 12) {
                if let primary = dialog.primaryAction {
                    Button(action: {
                        primary.handler()
                        onDismiss()
                    }) {
                        Text(primary.title)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonBackground(for: primary.role))
                            .foregroundStyle(buttonForeground(for: primary.role))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                if let secondary = dialog.secondaryAction {
                    Button(action: {
                        secondary.handler()
                        onDismiss()
                    }) {
                        Text(secondary.title)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(buttonBackground(for: secondary.role))
                            .foregroundStyle(buttonForeground(for: secondary.role))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Always show dismiss if no actions
                if dialog.primaryAction == nil && dialog.secondaryAction == nil {
                    Button("Dismiss") {
                        onDismiss()
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue.opacity(0.1))
                    .foregroundStyle(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(24)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(40)
    }
    
    private func buttonBackground(for role: ErrorDialogManager.ErrorDialog.Action.ActionRole) -> some ShapeStyle {
        switch role {
        case .normal:
            return AnyShapeStyle(.blue.gradient)
        case .destructive:
            return AnyShapeStyle(.red.gradient)
        case .cancel:
            return AnyShapeStyle(.gray.opacity(0.2))
        }
    }
    
    private func buttonForeground(for role: ErrorDialogManager.ErrorDialog.Action.ActionRole) -> Color {
        switch role {
        case .normal, .destructive:
            return .white
        case .cancel:
            return .primary
        }
    }
}

// MARK: - Error Dialog Modifier
struct ErrorDialogModifier: ViewModifier {
    @ObservedObject var manager = ErrorDialogManager.shared
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if manager.isShowingDialog, let dialog = manager.currentDialog {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent dismissal on tap for critical errors
                        if dialog.severity != .critical {
                            manager.dismiss()
                        }
                    }
                    .transition(.opacity)
                
                ErrorDialogView(dialog: dialog, onDismiss: manager.dismiss)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: manager.isShowingDialog)
    }
}

extension View {
    func withErrorDialog() -> some View {
        modifier(ErrorDialogModifier())
    }
}

// MARK: - Error Log Viewer (for Settings/Debug)
struct ErrorLogListView: View {
    @ObservedObject private var errorManager = ErrorRecoveryManager.shared
    @State private var showingClearConfirmation = false
    
    var body: some View {
        List {
            if errorManager.errors.isEmpty {
                EmptyStateView(
                    icon: "checkmark.circle.fill",
                    title: "No Errors",
                    message: "All systems operating normally"
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(errorManager.errors) { error in
                    ErrorLogListRow(error: error)
                }
            }
        }
        .navigationTitle("Error Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !errorManager.errors.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
        }
        .alert("Clear Error Log", isPresented: $showingClearConfirmation) {
            Button("Clear", role: .destructive) {
                errorManager.clearErrors()
                ToastManager.shared.show("Error log cleared", type: .success)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all \(errorManager.errors.count) error entries.")
        }
    }
}

struct ErrorLogListRow: View {
    let error: ErrorRecoveryManager.RecoveryError
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: severityIcon)
                    .foregroundStyle(severityColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(error.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(error.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            
            Text(error.timestamp.formatted(date: .abbreviated, time: .standard))
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            if let action = error.action {
                Button("Retry") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var severityIcon: String {
        switch error.severity {
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
    
    private var severityColor: Color {
        switch error.severity {
        case .warning: return .orange
        case .error: return .red
        case .critical: return .purple
        }
    }
}
