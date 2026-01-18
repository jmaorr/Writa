//
//  AuthManager.swift
//  Writa
//
//  Handles user authentication and session management.
//  Prepared for integration with Firebase Auth, Auth0, or custom backend.
//

import SwiftUI
import Combine

// MARK: - User Model

struct User: Identifiable, Codable {
    let id: String
    var email: String
    var displayName: String?
    var photoURL: URL?
    var createdAt: Date
    var subscription: SubscriptionTier
    
    init(id: String, email: String, displayName: String? = nil, photoURL: URL? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = Date()
        self.subscription = .free
    }
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable {
    case free
    case pro
    case team
    case enterprise
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .team: return "Team"
        case .enterprise: return "Enterprise"
        }
    }
    
    var maxDocuments: Int? {
        switch self {
        case .free: return 50
        case .pro: return nil // Unlimited
        case .team: return nil
        case .enterprise: return nil
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return ["50 documents", "Basic editor", "Local storage"]
        case .pro:
            return ["Unlimited documents", "Cloud sync", "Advanced formatting", "Export to PDF/Word"]
        case .team:
            return ["Everything in Pro", "Team collaboration", "Shared workspaces", "Priority support"]
        case .enterprise:
            return ["Everything in Team", "SSO", "Advanced security", "Dedicated support", "Custom integrations"]
        }
    }
}

// MARK: - Auth State

enum AuthState {
    case loading
    case authenticated(User)
    case unauthenticated
    case error(Error)
}

// MARK: - Auth Manager

@Observable
class AuthManager {
    var currentUser: User?
    var authState: AuthState = .loading
    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Check for cached session
        checkCachedSession()
    }
    
    // MARK: - Session Management
    
    private func checkCachedSession() {
        // TODO: Check for cached auth token/session
        // For now, assume unauthenticated (offline mode)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.authState = .unauthenticated
        }
    }
    
    // MARK: - Authentication Methods
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        authState = .loading
        
        // TODO: Implement actual authentication
        // Example: Firebase Auth, custom API, etc.
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Create mock user for testing
        let user = User(
            id: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first
        )
        
        await MainActor.run {
            self.currentUser = user
            self.authState = .authenticated(user)
            self.cacheSession(user)
        }
    }
    
    /// Sign up with email and password
    func signUp(email: String, password: String, displayName: String) async throws {
        authState = .loading
        
        // TODO: Implement actual signup
        
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let user = User(
            id: UUID().uuidString,
            email: email,
            displayName: displayName
        )
        
        await MainActor.run {
            self.currentUser = user
            self.authState = .authenticated(user)
            self.cacheSession(user)
        }
    }
    
    /// Sign in with Google
    func signInWithGoogle() async throws {
        authState = .loading
        
        // TODO: Implement Google OAuth
        throw AuthError.notImplemented
    }
    
    /// Sign in with Apple
    func signInWithApple() async throws {
        authState = .loading
        
        // TODO: Implement Sign in with Apple
        throw AuthError.notImplemented
    }
    
    /// Sign out
    func signOut() async throws {
        authState = .loading
        
        // TODO: Clear server session
        
        await MainActor.run {
            self.currentUser = nil
            self.authState = .unauthenticated
            self.clearCachedSession()
        }
    }
    
    /// Delete account
    func deleteAccount() async throws {
        guard let user = currentUser else { return }
        
        // TODO: Delete user data from server
        
        try await signOut()
    }
    
    // MARK: - Session Persistence
    
    private func cacheSession(_ user: User) {
        // TODO: Save auth token securely in Keychain
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "cached_user")
        }
    }
    
    private func clearCachedSession() {
        // TODO: Clear auth token from Keychain
        UserDefaults.standard.removeObject(forKey: "cached_user")
    }
    
    // MARK: - Token Management
    
    func getAuthToken() async throws -> String {
        // TODO: Get valid auth token (refresh if needed)
        throw AuthError.notAuthenticated
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    case notImplemented
    case invalidCredentials
    case networkError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .notImplemented:
            return "This feature is not yet implemented"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network connection error"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Environment Key

private struct AuthManagerKey: EnvironmentKey {
    static let defaultValue = AuthManager()
}

extension EnvironmentValues {
    var authManager: AuthManager {
        get { self[AuthManagerKey.self] }
        set { self[AuthManagerKey.self] = newValue }
    }
}
