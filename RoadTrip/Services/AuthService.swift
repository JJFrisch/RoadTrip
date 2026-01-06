// Services/AuthService.swift
#if false
import Foundation
import SwiftData
import Combine

/// Manages user authentication and account state
/// Authentication is optional - the app works fully offline without an account
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: UserAccount?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let savedUserIdKey = "savedUserId"
    private let savedUserEmailKey = "savedUserEmail"
    private let savedUserNameKey = "savedUserName"
    
    private init() {
        loadSavedUser()
    }
    
    // MARK: - Public Methods
    
    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // Validate input
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard password.count >= 8 else {
            throw AuthError.weakPassword
        }
        
        // In a real app, this would call a cloud auth service (Firebase, AWS Cognito, etc.)
        // For now, we'll simulate local account creation
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = UserAccount(email: email.lowercased(), displayName: displayName)
        user.cloudUserId = UUID().uuidString
        user.isLoggedIn = true
        user.lastLoginAt = Date()
        
        currentUser = user
        isLoggedIn = true
        saveUser(user)
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In a real app, verify credentials with server
        // For demo, we'll accept any valid email/password combo
        
        let _ = userDefaults.string(forKey: savedUserNameKey)
        
        let user = UserAccount(
            email: email.lowercased(),
            displayName: userDefaults.string(forKey: savedUserNameKey) ?? email.components(separatedBy: "@").first ?? "User"
        )
        user.cloudUserId = userDefaults.string(forKey: savedUserIdKey) ?? UUID().uuidString
        user.isLoggedIn = true
        user.lastLoginAt = Date()
        
        currentUser = user
        isLoggedIn = true
        saveUser(user)
    }
    
    /// Sign out the current user
    func signOut() {
        currentUser = nil
        isLoggedIn = false
        clearSavedUser()
    }
    
    /// Continue without signing in (guest mode)
    func continueAsGuest() {
        isLoggedIn = false
        currentUser = nil
    }
    
    /// Update user profile
    func updateProfile(displayName: String) async throws {
        guard let user = currentUser else {
            throw AuthError.notLoggedIn
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        user.displayName = displayName
        saveUser(user)
    }
    
    /// Delete user account
    func deleteAccount() async throws {
        guard currentUser != nil else {
            throw AuthError.notLoggedIn
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In real app, delete from cloud service
        signOut()
    }
    
    // MARK: - Private Methods
    
    private func loadSavedUser() {
        guard let userId = userDefaults.string(forKey: savedUserIdKey),
              let email = userDefaults.string(forKey: savedUserEmailKey),
              let name = userDefaults.string(forKey: savedUserNameKey) else {
            return
        }
        
        let user = UserAccount(email: email, displayName: name)
        user.cloudUserId = userId
        user.isLoggedIn = true
        
        currentUser = user
        isLoggedIn = true
    }
    
    private func saveUser(_ user: UserAccount) {
        userDefaults.set(user.cloudUserId, forKey: savedUserIdKey)
        userDefaults.set(user.email, forKey: savedUserEmailKey)
        userDefaults.set(user.displayName, forKey: savedUserNameKey)
    }
    
    private func clearSavedUser() {
        userDefaults.removeObject(forKey: savedUserIdKey)
        userDefaults.removeObject(forKey: savedUserEmailKey)
        userDefaults.removeObject(forKey: savedUserNameKey)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Error Types
    
    enum AuthError: LocalizedError {
        case invalidEmail
        case weakPassword
        case invalidCredentials
        case notLoggedIn
        case networkError
        case accountExists
        case unknown
        
        var errorDescription: String? {
            switch self {
            case .invalidEmail:
                return "Please enter a valid email address"
            case .weakPassword:
                return "Password must be at least 8 characters"
            case .invalidCredentials:
                return "Invalid email or password"
            case .notLoggedIn:
                return "You must be logged in to perform this action"
            case .networkError:
                return "Network error. Please check your connection."
            case .accountExists:
                return "An account with this email already exists"
            case .unknown:
                return "An unknown error occurred"
            }
        }
    }
}
#endif
