//
//  AuthContainerView.swift
//  Writa
//
//  Passwordless authentication using Clerk's email OTP flow.
//  No passwords - just enter email, receive code, sign in.
//

import SwiftUI
import Clerk

// MARK: - Auth Container View

struct AuthContainerView: View {
    @Environment(\.clerk) private var clerk
    @Environment(\.dismiss) private var dismiss
    @Environment(\.authManager) private var authManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Sign In")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // Auth form
            ScrollView {
                VStack(spacing: 24) {
                    // App branding
                    VStack(spacing: 8) {
                        Image(systemName: "text.book.closed.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.accentColor)
                        
                        Text("Writa")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Sign in with your email")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Email OTP Form
                    EmailOTPAuthView(onSuccess: handleAuthSuccess)
                }
                .padding(24)
            }
        }
        .frame(width: 400, height: 480)
        .onChange(of: clerk.user) { oldValue, newValue in
            if newValue != nil {
                handleAuthSuccess()
            }
        }
    }
    
    private func handleAuthSuccess() {
        authManager.updateAuthState()
        dismiss()
    }
}

// MARK: - Email OTP Auth View

struct EmailOTPAuthView: View {
    @Environment(\.clerk) private var clerk
    
    @State private var email = ""
    @State private var code = ""
    @State private var isLoading = false
    @State private var error: String?
    @State private var isVerifying = false
    @State private var isNewUser = false
    
    var onSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if isVerifying {
                // Verification code form
                VStack(alignment: .leading, spacing: 8) {
                    Text("Check your email")
                        .font(.headline)
                    Text("We sent a code to \(email)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                TextField("Enter 6-digit code", text: $code)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.oneTimeCode)  // Enables OTP auto-fill from email
                    .font(.title3.monospacedDigit())
                    .multilineTextAlignment(.center)
                
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    Task { await verifyCode() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Verify")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(code.count < 6 || isLoading)
                
                Button("Use a different email") {
                    isVerifying = false
                    code = ""
                    error = nil
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .font(.callout)
                
            } else {
                // Email entry form
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email address")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("you@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                }
                
                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
                
                Button {
                    Task { await sendCode() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Continue")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(email.isEmpty || !email.contains("@") || isLoading)
                
                Text("We'll send you a one-time code")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: 300)
    }
    
    // MARK: - Send Code
    
    private func sendCode() async {
        isLoading = true
        error = nil
        
        // First try to sign in (existing user)
        do {
            let signIn = try await SignIn.create(strategy: .identifier(email))
            try await signIn.prepareFirstFactor(strategy: .emailCode())
            
            await MainActor.run {
                isNewUser = false
                isVerifying = true
                isLoading = false
            }
            return
        } catch {
            // User might not exist, try sign up
            print("Sign-in failed, trying sign-up: \(error)")
        }
        
        // Try to sign up (new user)
        do {
            let signUp = try await SignUp.create(strategy: .standard(emailAddress: email))
            try await signUp.prepareVerification(strategy: .emailCode)
            
            await MainActor.run {
                isNewUser = true
                isVerifying = true
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = parseClerkError(error)
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Verify Code
    
    private func verifyCode() async {
        isLoading = true
        error = nil
        
        do {
            if isNewUser {
                // Complete sign-up verification
                guard let inProgressSignUp = clerk.client?.signUp else {
                    await MainActor.run {
                        error = "No sign-up in progress. Please start again."
                        isLoading = false
                    }
                    return
                }
                
                let signUp = try await inProgressSignUp.attemptVerification(
                    strategy: .emailCode(code: code)
                )
                
                if signUp.status == .complete {
                    await MainActor.run { onSuccess() }
                } else {
                    await MainActor.run {
                        error = "Verification incomplete. Please try again."
                        isLoading = false
                    }
                }
            } else {
                // Complete sign-in verification
                guard let inProgressSignIn = clerk.client?.signIn else {
                    await MainActor.run {
                        error = "No sign-in in progress. Please start again."
                        isLoading = false
                    }
                    return
                }
                
                let signIn = try await inProgressSignIn.attemptFirstFactor(
                    strategy: .emailCode(code: code)
                )
                
                if signIn.status == .complete {
                    await MainActor.run { onSuccess() }
                } else {
                    await MainActor.run {
                        error = "Verification incomplete. Please try again."
                        isLoading = false
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = parseClerkError(error)
                self.isLoading = false
            }
        }
    }
}

// MARK: - Error Parsing

private func parseClerkError(_ error: Error) -> String {
    let description = String(describing: error).lowercased()
    
    if description.contains("email") && description.contains("invalid") {
        return "Please enter a valid email address"
    } else if description.contains("code") {
        return "Invalid code. Please check and try again."
    } else if description.contains("expired") {
        return "Code expired. Please request a new one."
    } else if description.contains("rate") || description.contains("limit") {
        return "Too many attempts. Please wait and try again."
    }
    
    return "Something went wrong. Please try again."
}

// MARK: - User Profile Button

struct UserProfileButton: View {
    @Environment(\.clerk) private var clerk
    @State private var showingProfile = false
    
    var body: some View {
        if let user = clerk.user {
            Button {
                showingProfile = true
            } label: {
                if !user.imageUrl.isEmpty, let url = URL(string: user.imageUrl) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        userInitials
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } else {
                    userInitials
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingProfile) {
                UserProfilePopover()
            }
        }
    }
    
    private var userInitials: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.2))
            
            Text(initials)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: 32, height: 32)
    }
    
    private var initials: String {
        guard let user = clerk.user else { return "?" }
        let first = user.firstName?.prefix(1) ?? ""
        let last = user.lastName?.prefix(1) ?? ""
        if first.isEmpty && last.isEmpty {
            return String(user.primaryEmailAddress?.emailAddress.prefix(1) ?? "?").uppercased()
        }
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - User Profile Popover

struct UserProfilePopover: View {
    @Environment(\.clerk) private var clerk
    @Environment(\.authManager) private var authManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            if let user = clerk.user {
                VStack(spacing: 8) {
                    if !user.imageUrl.isEmpty, let url = URL(string: user.imageUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.accentColor.opacity(0.2))
                        }
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                    }
                    
                    Text(userDisplayName(for: user))
                        .font(.headline)
                    
                    if let email = user.primaryEmailAddress?.emailAddress {
                        Text(email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Divider()
                
                Button("Sign Out") {
                    Task {
                        do {
                            try await authManager.signOut()
                            dismiss()
                        } catch {
                            print("Sign out error: \(error)")
                        }
                    }
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(width: 250)
    }
    
    private func userDisplayName(for user: User) -> String {
        let parts = [user.firstName, user.lastName].compactMap { $0 }
        if parts.isEmpty {
            return user.primaryEmailAddress?.emailAddress ?? "User"
        }
        return parts.joined(separator: " ")
    }
}

// MARK: - Preview

#Preview("Auth Container") {
    AuthContainerView()
}
