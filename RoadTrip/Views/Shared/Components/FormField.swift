// Views/Shared/Components/FormField.swift
import SwiftUI

/// A polished text input field with integrated label, placeholder, optional helper text, and error state.
/// Standardizes form input appearance across the app.
///
/// Usage:
/// ```
/// FormField(label: "Trip Name", placeholder: "e.g., Summer Road Trip", text: $tripName, errorMessage: tripNameError)
/// ```
struct FormField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let errorMessage: String?
    let isValid: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    @FocusState private var isFocused: Bool
    
    init(
        label: String,
        placeholder: String = "",
        text: Binding<String>,
        errorMessage: String? = nil,
        isValid: Bool = true
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.errorMessage = errorMessage
        self.isValid = isValid
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(label)
                .font(AppTheme.Typography.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
            
            TextField(placeholder, text: $text)
                .font(AppTheme.Typography.body)
                .padding(AppTheme.Spacing.sm)
                .background(AppTheme.Colors.background)
                .cornerRadius(AppTheme.CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            borderColor,
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
    
    private var borderColor: Color {
        if !isValid && !text.isEmpty {
            return AppTheme.Colors.danger.opacity(0.5)
        }
        return isFocused ? AppTheme.Colors.primary : AppTheme.Colors.divider
    }
}

#Preview {
    ZStack {
        AppTheme.Colors.background.ignoresSafeArea()
        
        VStack(spacing: AppTheme.Spacing.lg) {
            FormSection("Trip Details") {
                VStack(spacing: AppTheme.Spacing.md) {
                    FormField(
                        label: "Trip Name",
                        placeholder: "e.g., Summer Road Trip",
                        text: .constant("My Amazing Trip")
                    )
                    
                    FormField(
                        label: "Invalid Field",
                        placeholder: "This shows error state",
                        text: .constant("Bad input"),
                        errorMessage: "This field is required",
                        isValid: false
                    )
                }
            }
            
            Spacer()
        }
        .padding(.vertical, AppTheme.Spacing.lg)
    }
}
