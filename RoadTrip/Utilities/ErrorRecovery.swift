//
//  ErrorRecovery.swift
//  RoadTrip
//
//  Created by Jake Frischmann on 1/3/26.
//

import Foundation
import SwiftUI

// MARK: - Error Recovery System
class ErrorRecoveryManager: ObservableObject {
    static let shared = ErrorRecoveryManager()
    
    @Published var errors: [RecoveryError] = []
    @Published var isShowingErrors = false
    
    private init() {}
    
    struct RecoveryError: Identifiable {
        let id = UUID()
        let title: String
        let message: String
        let severity: Severity
        let timestamp: Date = Date()
        let action: (() -> Void)?
        
        enum Severity {
            case warning   // Non-critical, continue
            case error     // Feature disabled, app continues
            case critical  // App crash imminent
        }
    }
    
    func record(
        title: String,
        message: String,
        severity: RecoveryError.Severity,
        action: (() -> Void)? = nil
    ) {
        let error = RecoveryError(
            title: title,
            message: message,
            severity: severity,
            action: action
        )
        
        DispatchQueue.main.async {
            self.errors.append(error)
            
            // Log to console
            let severityText = String(describing: severity).uppercased()
            print("[\(severityText)] \(title): \(message)")
            
            // Keep only last 50 errors
            if self.errors.count > 50 {
                self.errors.removeFirst()
            }
        }
    }
    
    func clearErrors() {
        errors.removeAll()
    }
    
    func removeError(_ error: RecoveryError) {
        errors.removeAll { $0.id == error.id }
    }
}

// MARK: - Resilient Wrapper for Optional Features
struct SafeFeature<Content: View>: View {
    let feature: () -> Content
    let fallback: () -> Content
    let errorTitle: String
    let errorMessage: String
    
    @State private var hasError = false
    
    var body: some View {
        if hasError {
            fallback()
        } else {
            feature()
        }
    }
}

// MARK: - Error Display Views
struct ErrorBanner: View {
    let error: ErrorRecoveryManager.RecoveryError
    let onDismiss: () -> Void
    
    var backgroundColor: Color {
        switch error.severity {
        case .warning:
            return Color.orange
        case .error:
            return Color.red
        case .critical:
            return Color.red.opacity(0.9)
        }
    }
    
    var iconName: String {
        switch error.severity {
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .critical:
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(error.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    Text(error.message)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                }
                
                Spacer()
                
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(8)
                }
            }
            
            if let action = error.action {
                Button(action: action) {
                    Text("Retry")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

struct FallbackView: View {
    let title: String
    let message: String
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let action = action {
                Button(action: action) {
                    Text("Try Again")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
    }
}

// MARK: - Error Log View for Debugging
struct ErrorLogView: View {
    @ObservedObject var manager = ErrorRecoveryManager.shared
    
    var body: some View {
        NavigationStack {
            List {
                if manager.errors.isEmpty {
                    Text("No errors recorded")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manager.errors) { error in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Circle()
                                    .fill(severityColor(error.severity))
                                    .frame(width: 8)
                                
                                Text(error.title)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(error.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(error.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption2)
                                .foregroundStyle(.secondary.opacity(0.7))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Error Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        manager.clearErrors()
                    } label: {
                        Text("Clear")
                    }
                }
            }
        }
    }
    
    private func severityColor(_ severity: ErrorRecoveryManager.RecoveryError.Severity) -> Color {
        switch severity {
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .red
        }
    }
}

// MARK: - Try-Catch Helper
func safeExecute(
    title: String = "Operation Failed",
    message: String? = nil,
    severity: ErrorRecoveryManager.RecoveryError.Severity = .warning,
    _ operation: () throws -> Void
) {
    do {
        try operation()
    } catch {
        let errorMsg = message ?? error.localizedDescription
        ErrorRecoveryManager.shared.record(
            title: title,
            message: errorMsg,
            severity: severity
        )
    }
}

// MARK: - Async Safe Execute
func safeExecuteAsync(
    title: String = "Operation Failed",
    message: String? = nil,
    severity: ErrorRecoveryManager.RecoveryError.Severity = .warning,
    _ operation: () async throws -> Void
) async {
    do {
        try await operation()
    } catch {
        let errorMsg = message ?? error.localizedDescription
        ErrorRecoveryManager.shared.record(
            title: title,
            message: errorMsg,
            severity: severity
        )
    }
}
