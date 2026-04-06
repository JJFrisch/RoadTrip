// Views/Account/AccountView.swift
import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    // AuthService is disabled in this build; keep a flag for UI flow
    @State private var accountsEnabled = false

    @State private var showingSignIn = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScreenHeader(
                    "Account",
                    subtitle: "Manage sign in and support",
                    icon: "person.crop.circle"
                )

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        if accountsEnabled {
                            FormSection("Status") {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("Signed In")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
                                    Text("Account features are disabled in this build.")
                                        .font(AppTheme.Typography.caption1)
                                        .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            FormSection("Support") {
                                VStack(spacing: AppTheme.Spacing.sm) {
                                    NavigationLink {
                                        ErrorLogView()
                                    } label: {
                                        accountRow("Error Log", systemImage: "exclamationmark.triangle")
                                    }
                                    .buttonStyle(.plain)

                                    Divider()
                                        .overlay(AppTheme.Colors.divider)

                                    NavigationLink {
                                        QuickTutorialView()
                                    } label: {
                                        accountRow("Tutorial", systemImage: "book.fill")
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            FormSection {
                                Button(role: .destructive) {
                                    // No-op: sign out not available
                                } label: {
                                    Text("Sign Out")
                                }
                                .buttonStyle(DestructiveButtonStyle())
                            }
                        } else {
                            FormSection("Accounts") {
                                VStack(spacing: AppTheme.Spacing.md) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 56, weight: .semibold))
                                        .foregroundStyle(AppTheme.Colors.primary)

                                    Text("Sign in to RoadTrip")
                                        .font(AppTheme.Typography.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))

                                    Text("Sync your trips across devices and collaborate with friends and family.")
                                        .font(AppTheme.Typography.subheadline)
                                        .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                                        .multilineTextAlignment(.center)

                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                        FeatureBullet(icon: "icloud", text: "Sync itineraries")
                                        FeatureBullet(icon: "person.2.fill", text: "Share trip plans")
                                        FeatureBullet(icon: "lock.shield.fill", text: "Secure account recovery")
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, AppTheme.Spacing.xs)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.xs)
                            }

                            ActionButtonGroup(
                                primaryTitle: "Sign In",
                                primaryAction: { showingSignIn = true },
                                secondaryTitle: "Create Account",
                                secondaryAction: { showingSignUp = true }
                            )
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.lg)
                }
            }
            .background(AppTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingSignIn) {
                SignInView()
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }

    private func accountRow(_ title: String, systemImage: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(width: 20)

            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))

            Spacer()

            Image(systemName: "chevron.right")
                .font(AppTheme.Typography.caption1)
                .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
        }
        .contentShape(Rectangle())
        .padding(.vertical, AppTheme.Spacing.xxs)
    }
}

struct FeatureBullet: View {
    let icon: String
    let text: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.Colors.primary)
                .frame(width: 24)
            Text(text)
                .font(AppTheme.Typography.subheadline)
                .foregroundStyle(AppTheme.Colors.primaryText.color(for: colorScheme))
        }
    }
}

// MARK: - Sign In View (disabled)
struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if showingError {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(AppTheme.Colors.warning)
                        Text(errorMessage)
                            .font(AppTheme.Typography.caption1)
                            .foregroundStyle(AppTheme.Colors.primaryText)
                            .lineLimit(2)
                        Spacer()
                        Button("Dismiss") {
                            withAnimation(.easeInOut(duration: AppTheme.Animation.fast)) {
                                showingError = false
                                errorMessage = ""
                            }
                        }
                        .font(AppTheme.Typography.caption1)
                        .foregroundStyle(AppTheme.Colors.primary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Colors.warning.opacity(0.12))
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.Colors.warning)

                Text("Accounts Disabled")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("This build has account features disabled. All core app features work offline without signing in.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding()

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Sign Up View (disabled)
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppTheme.Colors.primary)

                Text("Accounts Disabled")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Account creation is disabled in this build. Use the app offline without an account.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.Colors.secondaryText.color(for: colorScheme))
                    .multilineTextAlignment(.center)
                    .padding()

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Edit Profile View (disabled)
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Profile editing is disabled in this build.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Edit Profile")
        }
    }
}

#Preview {
    AccountView()
}
