# API Integration Guide

This guide shows how to connect Writa to your backend API for authentication and document sync.

## Table of Contents
1. [Choose Your Stack](#choose-your-stack)
2. [Firebase Setup](#option-1-firebase-recommended-for-mvp)
3. [Supabase Setup](#option-2-supabase-open-source-postgresql)
4. [Custom API Setup](#option-3-custom-api-full-control)
5. [Testing](#testing)

---

## Choose Your Stack

### Option 1: Firebase (Recommended for MVP)
**Pros**: Easy setup, real-time, generous free tier, managed infrastructure  
**Cons**: Vendor lock-in, can get expensive at scale  
**Best for**: Fast MVP, startups, indie developers

### Option 2: Supabase (Open Source PostgreSQL)
**Pros**: Open source, PostgreSQL, real-time, self-hostable  
**Cons**: Smaller ecosystem, newer platform  
**Best for**: Developers who want open source + modern DX

### Option 3: Custom API (Full Control)
**Pros**: Complete control, any tech stack, no vendor lock-in  
**Cons**: More work, you manage infrastructure  
**Best for**: Specific requirements, existing backend

---

## Option 1: Firebase (Recommended for MVP)

### 1. Setup Firebase Project

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Initialize project
firebase init
```

### 2. Add Firebase to Xcode

```swift
// 1. Add Firebase SDK via SPM
// File > Add Package Dependencies
// https://github.com/firebase/firebase-ios-sdk

// 2. Add to WritaApp.swift
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct WritaApp: App {
    init() {
        FirebaseApp.configure()
    }
    // ... rest of code
}
```

### 3. Update AuthManager

```swift
import FirebaseAuth

class AuthManager {
    func signIn(email: String, password: String) async throws {
        authState = .loading
        
        do {
            let result = try await Auth.auth().signIn(
                withEmail: email,
                password: password
            )
            
            let user = User(
                id: result.user.uid,
                email: result.user.email ?? email,
                displayName: result.user.displayName
            )
            
            await MainActor.run {
                self.currentUser = user
                self.authState = .authenticated(user)
                self.cacheSession(user)
            }
        } catch {
            await MainActor.run {
                self.authState = .error(error)
            }
            throw error
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        authState = .loading
        
        do {
            let result = try await Auth.auth().createUser(
                withEmail: email,
                password: password
            )
            
            // Update profile
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            let user = User(
                id: result.user.uid,
                email: email,
                displayName: displayName
            )
            
            await MainActor.run {
                self.currentUser = user
                self.authState = .authenticated(user)
                self.cacheSession(user)
            }
        } catch {
            await MainActor.run {
                self.authState = .error(error)
            }
            throw error
        }
    }
    
    func getAuthToken() async throws -> String {
        guard let currentUser = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }
        return try await currentUser.getIDToken()
    }
}
```

### 4. Update SyncService

```swift
import FirebaseFirestore

class SyncService {
    private let db = Firestore.firestore()
    
    func syncDocument(_ document: Document) async throws {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        let userId = authManager.currentUser?.id ?? ""
        let docRef = db.collection("users")
            .document(userId)
            .collection("documents")
            .document(document.id.uuidString)
        
        let data: [String: Any] = [
            "title": document.title,
            "content": document.content?.base64EncodedString() ?? "",
            "plainText": document.plainText,
            "wordCount": document.wordCount,
            "createdAt": Timestamp(date: document.createdAt),
            "updatedAt": Timestamp(date: document.updatedAt),
            "isFavorite": document.isFavorite,
            "isPinned": document.isPinned
        ]
        
        try await docRef.setData(data, merge: true)
    }
    
    func sync() async {
        guard authManager.isAuthenticated else { return }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            let userId = authManager.currentUser?.id ?? ""
            let snapshot = try await db.collection("users")
                .document(userId)
                .collection("documents")
                .getDocuments()
            
            // TODO: Merge with local SwiftData documents
            
            await MainActor.run {
                let now = Date()
                self.lastSyncDate = now
                self.syncStatus = .success(now)
            }
        } catch {
            await MainActor.run {
                self.syncStatus = .error(error)
            }
        }
    }
}
```

### 5. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User documents
    match /users/{userId}/documents/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Shared documents (for collaboration)
    match /shared/{documentId} {
      allow read: if request.auth != null && 
                     request.auth.uid in resource.data.collaborators;
      allow write: if request.auth != null && 
                      request.auth.uid == resource.data.owner;
    }
  }
}
```

---

## Option 2: Supabase (Open Source PostgreSQL)

### 1. Create Supabase Project

1. Go to https://supabase.com
2. Create new project
3. Get your API URL and anon key

### 2. Add Supabase Client

```swift
// Add Supabase Swift SDK
// https://github.com/supabase/supabase-swift

import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
    supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```

### 3. Update AuthManager

```swift
class AuthManager {
    func signIn(email: String, password: String) async throws {
        authState = .loading
        
        do {
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let user = User(
                id: session.user.id.uuidString,
                email: session.user.email ?? email
            )
            
            await MainActor.run {
                self.currentUser = user
                self.authState = .authenticated(user)
                self.cacheSession(user)
            }
        } catch {
            await MainActor.run {
                self.authState = .error(error)
            }
            throw error
        }
    }
}
```

### 4. Database Schema (SQL)

```sql
-- Create documents table
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users NOT NULL,
    title TEXT NOT NULL,
    content JSONB,  -- TipTap JSON content
    plain_text TEXT,
    word_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_favorite BOOLEAN DEFAULT FALSE,
    is_pinned BOOLEAN DEFAULT FALSE
);

-- Enable Row Level Security
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

-- Users can only access their own documents
CREATE POLICY "Users can CRUD own documents"
ON documents
FOR ALL
USING (auth.uid() = user_id);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER documents_updated_at
    BEFORE UPDATE ON documents
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();
```

### 5. Real-time Subscriptions

```swift
class SyncService {
    func setupRealtimeSync() {
        supabase.database
            .from("documents")
            .on(.all) { event in
                // Handle real-time updates
                Task {
                    await self.handleRealtimeUpdate(event)
                }
            }
            .subscribe()
    }
}
```

---

## Option 3: Custom API (Full Control)

### 1. API Endpoints Needed

```
POST   /auth/signup
POST   /auth/signin
POST   /auth/signout
POST   /auth/refresh
GET    /auth/me

GET    /documents
POST   /documents
GET    /documents/:id
PUT    /documents/:id
DELETE /documents/:id
POST   /documents/:id/sync
```

### 2. API Client

```swift
class APIClient {
    let baseURL = URL(string: "https://api.yourapp.com")!
    
    func request<T: Codable>(
        _ endpoint: String,
        method: String = "GET",
        body: Data? = nil,
        token: String? = nil
    ) async throws -> T {
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
```

### 3. Update AuthManager

```swift
class AuthManager {
    private let api = APIClient()
    
    struct SignInResponse: Codable {
        let user: User
        let token: String
        let refreshToken: String
    }
    
    func signIn(email: String, password: String) async throws {
        authState = .loading
        
        let body = try JSONEncoder().encode([
            "email": email,
            "password": password
        ])
        
        do {
            let response: SignInResponse = try await api.request(
                "/auth/signin",
                method: "POST",
                body: body
            )
            
            // Store token securely
            try saveTokenToKeychain(response.token)
            
            await MainActor.run {
                self.currentUser = response.user
                self.authState = .authenticated(response.user)
            }
        } catch {
            await MainActor.run {
                self.authState = .error(error)
            }
            throw error
        }
    }
}
```

### 4. Keychain for Token Storage

```swift
import Security

extension AuthManager {
    func saveTokenToKeychain(_ token: String) throws {
        let data = Data(token.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.serverError("Failed to save token")
        }
    }
    
    func getTokenFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "auth_token",
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return token
    }
}
```

---

## Testing

### 1. Test Authentication

```swift
// In a test or preview
Task {
    do {
        try await authManager.signUp(
            email: "test@example.com",
            password: "securepassword",
            displayName: "Test User"
        )
        print("✅ Sign up successful")
        
        try await authManager.signOut()
        print("✅ Sign out successful")
        
        try await authManager.signIn(
            email: "test@example.com",
            password: "securepassword"
        )
        print("✅ Sign in successful")
    } catch {
        print("❌ Error: \(error)")
    }
}
```

### 2. Test Sync

```swift
// Create a document
let document = Document(title: "Test Document")

// Sync it
Task {
    do {
        try await syncService.syncDocument(document)
        print("✅ Document synced")
    } catch {
        print("❌ Sync error: \(error)")
    }
}
```

### 3. Monitor Network Calls

```bash
# Use Charles Proxy or Proxyman to inspect API calls
# https://www.charlesproxy.com/
# https://proxyman.io/
```

---

## Environment Configuration

### Development vs Production

```swift
#if DEBUG
let apiBaseURL = "http://localhost:3000"
let useEmulator = true
#else
let apiBaseURL = "https://api.yourapp.com"
let useEmulator = false
#endif

// For Firebase
if useEmulator {
    Auth.auth().useEmulator(withHost: "localhost", port: 9099)
    let settings = Firestore.firestore().settings
    settings.host = "localhost:8080"
    settings.isSSLEnabled = false
    Firestore.firestore().settings = settings
}
```

---

## Error Handling

### Network Errors

```swift
enum APIError: LocalizedError {
    case networkError
    case unauthorized
    case serverError
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect. Check your internet connection."
        case .unauthorized:
            return "Your session has expired. Please sign in again."
        case .serverError:
            return "Server error. Please try again later."
        case .decodingError:
            return "Invalid response from server."
        }
    }
}
```

### Show Errors to User

```swift
struct ContentView: View {
    @Environment(\.authManager) private var authManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            // ... content
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: authManager.authState) { oldValue, newValue in
            if case .error(let error) = newValue {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}
```

---

## Next Steps

1. ✅ Choose your backend (Firebase, Supabase, or Custom)
2. ✅ Implement authentication
3. ✅ Implement document sync
4. ✅ Test with real users
5. ✅ Add error handling and retry logic
6. ✅ Implement offline queue for failed syncs
7. ✅ Add conflict resolution UI
8. ✅ Monitor performance and errors

---

**Resources**:
- [Firebase iOS SDK](https://firebase.google.com/docs/ios/setup)
- [Supabase Swift](https://github.com/supabase/supabase-swift)
- [URLSession Guide](https://developer.apple.com/documentation/foundation/urlsession)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
