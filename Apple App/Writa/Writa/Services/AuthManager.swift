//
//  AuthManager.swift
//  Writa
//
//  Handles user authentication and session management.
//  Integrates with Clerk for authentication.
//

import SwiftUI
import Combine
import Clerk

// MARK: - User Model

struct WritaUser: Identifiable, Codable {
    let id: String
    var email: String
    var displayName: String?
    var photoURL: URL?
    var createdAt: Date
    var subscription: SubscriptionTier
    
    init(id: String, email: String, displayName: String? = nil, photoURL: URL? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.subscription = .free
    }
    
    /// Create a WritaUser from a Clerk User
    init(from clerkUser: User) {
        self.id = clerkUser.id
        self.email = clerkUser.primaryEmailAddress?.emailAddress ?? ""
        self.displayName = clerkUser.firstName ?? clerkUser.username
        self.photoURL = clerkUser.imageUrl.isEmpty ? nil : URL(string: clerkUser.imageUrl)
        self.createdAt = clerkUser.createdAt
        self.subscription = .free  // Will be set from server metadata
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

enum AuthState: Equatable {
    case loading
    case authenticated(WritaUser)
    case unauthenticated
    case error(String)
    
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.authenticated(let lhsUser), .authenticated(let rhsUser)):
            return lhsUser.id == rhsUser.id
        case (.unauthenticated, .unauthenticated):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Auth Manager

@Observable
class AuthManager {
    var currentUser: WritaUser?
    var authState: AuthState = .loading
    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }
    
    /// Reference to shared Clerk instance
    private let clerk = Clerk.shared
    
    /// Whether Clerk has been configured and loaded
    private(set) var isClerkReady = false
    
    init() {
        // Initial state - will be updated when Clerk loads
        authState = .loading
    }
    
    // MARK: - Clerk Configuration
    
    /// Configure Clerk with publishable key
    /// Call this in your app's init or onAppear
    func configure(publishableKey: String) async {
        clerk.configure(publishableKey: publishableKey)
        
        do {
            try await clerk.load()
            isClerkReady = true
            
            // Update auth state based on Clerk's state
            await MainActor.run {
                updateAuthState()
            }
            
            print("✅ Clerk loaded successfully")
        } catch {
            print("❌ Failed to load Clerk: \(error)")
            await MainActor.run {
                self.authState = .error("Failed to initialize authentication")
            }
        }
    }
    
    /// Update auth state from Clerk's current state
    @MainActor
    func updateAuthState() {
        if let clerkUser = clerk.user {
            let user = WritaUser(from: clerkUser)
            self.currentUser = user
            self.authState = .authenticated(user)
        } else {
            self.currentUser = nil
            self.authState = .unauthenticated
        }
    }
    
    // MARK: - Sign Out
    
    /// Sign out the current user
    func signOut() async throws {
        await MainActor.run {
            authState = .loading
        }
        
        do {
            try await clerk.signOut()
            
            await MainActor.run {
                self.currentUser = nil
                self.authState = .unauthenticated
            }
        } catch {
            await MainActor.run {
                self.authState = .error(error.localizedDescription)
            }
            throw AuthError.serverError(error.localizedDescription)
        }
    }
    
    /// Delete account
    func deleteAccount() async throws {
        guard clerk.user != nil else {
            throw AuthError.notAuthenticated
        }
        
        do {
            try await clerk.user?.delete()
            try await signOut()
        } catch {
            throw AuthError.serverError(error.localizedDescription)
        }
    }
    
    // MARK: - Token Management
    
    /// Get a valid JWT token for API calls
    func getAuthToken() async throws -> String {
        guard let session = clerk.session else {
            throw AuthError.notAuthenticated
        }
        
        do {
            // Get a fresh token from the session
            let tokenResource = try await session.getToken()
            guard let jwt = tokenResource?.jwt else {
                throw AuthError.notAuthenticated
            }
            return jwt
        } catch {
            throw AuthError.serverError("Failed to get auth token: \(error.localizedDescription)")
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    case notImplemented
    case invalidCredentials
    case networkError
    case verificationRequired
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
        case .verificationRequired:
            return "Please verify your email address"
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
