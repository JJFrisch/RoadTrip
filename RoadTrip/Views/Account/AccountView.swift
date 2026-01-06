// Views/Account/AccountView.swift
import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    // AuthService is disabled in this build; keep a flag for UI flow
    @State private var accountsEnabled = false

    @State private var showingSignIn = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationStack {
            List {
                if accountsEnabled {
                    // Simplified logged-in placeholder (accounts disabled in this build)
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Signed In")
                                .font(.headline)
                            Text("Account features are disabled in this build.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    Section("Support") {
                        NavigationLink {
                            ErrorLogView()
                        } label: {
                            Label("Error Log", systemImage: "exclamationmark.triangle")
                        }

                        NavigationLink {
                            QuickTutorialView()
                        } label: {
                            Label("Tutorial", systemImage: "book.fill")
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            // No-op: sign out not available
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    }

                } else {
                    // Not logged in state
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)
                            
                            Text("Sign in to RoadTrip")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Sync your trips across devices and collaborate with friends and family.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    }
                    
                    Section {
                        Button {
                            showingSignIn = true
                        } label: {
                            HStack { Spacer(); Text("Sign In"); Spacer() }
                        }

                        Button {
                            showingSignUp = true
                        } label: {
                            HStack { Spacer(); Text("Create Account"); Spacer() }
                        }
                    }
                    
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            FeatureBullet(icon: "icloud", text: "Sync trips across all your devices")
                            FeatureBullet(icon: "person.2", text: "Share & collaborate on trips")
                            FeatureBullet(icon: "arrow.clockwise", text: "Automatic backup to cloud")
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Benefits of an Account")
                    } footer: {
                        Text("An account is optional. All features work offline without signing in.")
                    }
                }
            }
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
}

struct FeatureBullet: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Sign In View (disabled)
struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)

                Text("Accounts Disabled")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("This build has account features disabled. All core app features work offline without signing in.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

// MARK: - Sign Up View (disabled)
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "person.badge.plus.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)

                Text("Accounts Disabled")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Account creation is disabled in this build. Use the app offline without an account.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
