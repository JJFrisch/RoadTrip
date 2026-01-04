// Views/Account/AccountView.swift
import SwiftUI

struct AccountView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var showingSignIn = false
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationStack {
            List {
                if authService.isLoggedIn, let user = authService.currentUser {
                    // Logged in state
                    Section {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(width: 60, height: 60)
                                
                                Text(user.displayName.prefix(1).uppercased())
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.displayName)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("Sync") {
                        HStack {
                            Label("Cloud Sync", systemImage: "arrow.triangle.2.circlepath.icloud")
                            Spacer()
                            Text("Active")
                                .foregroundStyle(.green)
                        }
                        
                        HStack {
                            Label("Last Synced", systemImage: "clock")
                            Spacer()
                            Text("Just now")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Section("Account") {
                        NavigationLink {
                            EditProfileView()
                        } label: {
                            Label("Edit Profile", systemImage: "person.crop.circle")
                        }
                        
                        NavigationLink {
                            // Shared trips view
                            Text("Shared Trips")
                        } label: {
                            Label("Shared Trips", systemImage: "person.2")
                        }
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
                            authService.signOut()
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
                            HStack {
                                Spacer()
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                        
                        Button {
                            showingSignUp = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Create Account")
                                Spacer()
                            }
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

// MARK: - Sign In View
struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var email = ""
    @State private var password = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                }
                
                Section {
                    Button {
                        signIn()
                    } label: {
                        if authService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Sign In")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(!isFormValid || authService.isLoading)
                }
                
                Section {
                    Button {
                        // Forgot password flow
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Sign In Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signIn() {
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Sign Up View
struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var isFormValid: Bool {
        !displayName.isEmpty &&
        !email.isEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display Name", text: $displayName)
                        .textContentType(.name)
                    
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section {
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                    
                    if !password.isEmpty && password.count < 8 {
                        Text("Password must be at least 8 characters")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if !confirmPassword.isEmpty && password != confirmPassword {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                
                Section {
                    Button {
                        signUp()
                    } label: {
                        if authService.isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Create Account")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                        }
                    }
                    .disabled(!isFormValid || authService.isLoading)
                }
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Sign Up Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func signUp() {
        Task {
            do {
                try await authService.signUp(email: email, password: password, displayName: displayName)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    
    @State private var displayName = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Form {
            Section {
                TextField("Display Name", text: $displayName)
            }
            
            Section {
                Button {
                    updateProfile()
                } label: {
                    HStack {
                        Spacer()
                        Text("Save Changes")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(displayName.isEmpty || authService.isLoading)
            }
        }
        .navigationTitle("Edit Profile")
        .onAppear {
            displayName = authService.currentUser?.displayName ?? ""
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func updateProfile() {
        Task {
            do {
                try await authService.updateProfile(displayName: displayName)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

#Preview {
    AccountView()
}
