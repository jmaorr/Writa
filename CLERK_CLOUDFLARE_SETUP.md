# Clerk + Cloudflare Integration Guide

The recommended production stack for Writa using **Clerk** for authentication and **Cloudflare** for backend services.

## Why This Stack?

### Clerk
- 🎨 Beautiful pre-built UI components
- 🔐 Enterprise-grade security
- 👥 Built-in user management dashboard
- 🚀 Social logins (Google, Apple, GitHub, etc.)
- 📱 Multi-device session management
- 🆓 Generous free tier (10,000 MAU)

### Cloudflare
- ⚡️ Edge computing - serve from 300+ locations worldwide
- 💰 Extremely cost-effective (generous free tier)
- 📦 D1 (SQLite), KV (key-value), R2 (object storage)
- 🔒 Built-in DDoS protection
- 🌐 No cold starts unlike Lambda

## Architecture Overview

```
┌─────────────┐
│  Writa App  │
│   (macOS)   │
└──────┬──────┘
       │
       ├─────────────────────────┐
       │                         │
       ▼                         ▼
┌──────────────┐         ┌──────────────┐
│   Clerk JS   │         │  Cloudflare  │
│   (Auth UI)  │         │   Workers    │
└──────┬───────┘         └──────┬───────┘
       │                         │
       │                         ├─────► D1 (Documents DB)
       │                         ├─────► R2 (Image Storage)
       │                         └─────► KV (Cache/Sessions)
       │
       └─────────► Clerk API (JWT Tokens)
```

---

## Part 1: Clerk Setup

### 1. Create Clerk Account

1. Go to https://clerk.com
2. Sign up and create a new application
3. Choose "Native Application" as the type
4. Enable providers:
   - ✅ Email/Password
   - ✅ Google OAuth
   - ✅ Apple OAuth

### 2. Get API Keys

From your Clerk dashboard:
```
CLERK_PUBLISHABLE_KEY=pk_test_...
CLERK_SECRET_KEY=sk_test_...
CLERK_JWT_KEY=...  (from JWT Templates)
```

### 3. Install Clerk SDK

Since macOS native doesn't have an official Clerk SDK, we'll use their REST API:

```swift
// Add to your project
struct ClerkConfig {
    static let publishableKey = "pk_test_YOUR_KEY"
    static let apiURL = "https://api.clerk.com/v1"
}
```

### 4. Update AuthManager for Clerk

```swift
import SwiftUI
import Combine

class AuthManager {
    var currentUser: User?
    var authState: AuthState = .loading
    
    private let clerkAPI = ClerkAPIClient()
    
    // MARK: - Sign In with Email
    
    func signIn(email: String, password: String) async throws {
        authState = .loading
        
        do {
            // Step 1: Create sign-in attempt
            let signInResponse = try await clerkAPI.request(
                endpoint: "/client/sign_ins",
                method: "POST",
                body: ["identifier": email]
            )
            
            let signInId = signInResponse["id"] as? String ?? ""
            
            // Step 2: Attempt password
            let attemptResponse = try await clerkAPI.request(
                endpoint: "/client/sign_ins/\(signInId)/attempt_first_factor",
                method: "POST",
                body: [
                    "strategy": "password",
                    "password": password
                ]
            )
            
            guard let sessionData = attemptResponse["created_session_id"] as? String else {
                throw AuthError.invalidCredentials
            }
            
            // Step 3: Get session token
            let token = try await getSessionToken(sessionId: sessionData)
            
            // Step 4: Decode JWT to get user info
            let user = try decodeClerkToken(token)
            
            await MainActor.run {
                self.currentUser = user
                self.authState = .authenticated(user)
                try? saveTokenToKeychain(token)
            }
            
        } catch {
            await MainActor.run {
                self.authState = .error(error)
            }
            throw error
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, displayName: String) async throws {
        authState = .loading
        
        do {
            // Step 1: Create sign-up attempt
            let signUpResponse = try await clerkAPI.request(
                endpoint: "/client/sign_ups",
                method: "POST",
                body: [
                    "email_address": email,
                    "password": password,
                    "first_name": displayName
                ]
            )
            
            let signUpId = signUpResponse["id"] as? String ?? ""
            
            // Step 2: Prepare verification (email)
            _ = try await clerkAPI.request(
                endpoint: "/client/sign_ups/\(signUpId)/prepare_verification",
                method: "POST",
                body: ["strategy": "email_code"]
            )
            
            // In a real app, user would enter verification code here
            // For now, auto-complete if in development
            
            await MainActor.run {
                self.authState = .unauthenticated
            }
            
        } catch {
            await MainActor.run {
                self.authState = .error(error)
            }
            throw error
        }
    }
    
    // MARK: - OAuth (Google/Apple)
    
    func signInWithOAuth(provider: OAuthProvider) async throws {
        authState = .loading
        
        // Step 1: Get OAuth URL from Clerk
        let response = try await clerkAPI.request(
            endpoint: "/client/sign_ins",
            method: "POST",
            body: [
                "strategy": "oauth_\(provider.rawValue)",
                "redirect_url": "writa://oauth-callback"
            ]
        )
        
        guard let authURL = response["external_account_verification_url"] as? String,
              let url = URL(string: authURL) else {
            throw AuthError.serverError("Invalid OAuth URL")
        }
        
        // Step 2: Open OAuth flow in browser
        NSWorkspace.shared.open(url)
        
        // Step 3: Handle callback (implement URL scheme handler)
        // The token will come via deep link to writa://oauth-callback
    }
    
    // MARK: - Token Management
    
    func getAuthToken() async throws -> String {
        if let token = getTokenFromKeychain() {
            // Verify token is still valid
            if !isTokenExpired(token) {
                return token
            }
        }
        
        // Token expired or doesn't exist
        throw AuthError.notAuthenticated
    }
    
    private func decodeClerkToken(_ token: String) throws -> User {
        // JWT structure: header.payload.signature
        let parts = token.split(separator: ".")
        guard parts.count == 3 else {
            throw AuthError.invalidCredentials
        }
        
        // Decode base64 payload
        var base64 = String(parts[1])
        // Add padding if needed
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.serverError("Invalid token")
        }
        
        let userId = json["sub"] as? String ?? ""
        let email = json["email"] as? String ?? ""
        let name = json["name"] as? String
        
        return User(
            id: userId,
            email: email,
            displayName: name
        )
    }
    
    private func isTokenExpired(_ token: String) -> Bool {
        // Decode and check exp claim
        guard let payload = decodeJWTPayload(token),
              let exp = payload["exp"] as? TimeInterval else {
            return true
        }
        return Date() > Date(timeIntervalSince1970: exp)
    }
}

enum OAuthProvider: String {
    case google
    case apple
    case github
}
```

### 5. Clerk API Client

```swift
class ClerkAPIClient {
    private let publishableKey = ClerkConfig.publishableKey
    private let baseURL = URL(string: ClerkConfig.apiURL)!
    
    func request(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> [String: Any] {
        
        var request = URLRequest(url: baseURL.appendingPathComponent(endpoint))
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(publishableKey, forHTTPHeaderField: "Authorization")
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AuthError.serverError("Request failed")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.serverError("Invalid response")
        }
        
        return json
    }
}
```

---

## Part 2: Cloudflare Workers Setup

### 1. Install Wrangler CLI

```bash
npm install -g wrangler
wrangler login
```

### 2. Create Worker Project

```bash
# Create new project
npm create cloudflare@latest writa-api

# Choose options:
# - Template: Hello World Worker
# - TypeScript: Yes
# - Git: Yes
# - Deploy: No (we'll configure first)
```

### 3. Project Structure

```
writa-api/
├── src/
│   ├── index.ts          # Main worker entry
│   ├── documents.ts      # Document CRUD
│   ├── auth.ts           # Auth middleware
│   └── types.ts          # TypeScript types
├── wrangler.toml         # Configuration
└── schema.sql            # D1 database schema
```

### 4. Configure wrangler.toml

```toml
name = "writa-api"
main = "src/index.ts"
compatibility_date = "2024-01-01"

# D1 Database (SQLite at edge)
[[d1_databases]]
binding = "DB"
database_name = "writa-production"
database_id = "your-database-id"

# KV Namespace (for caching)
[[kv_namespaces]]
binding = "CACHE"
id = "your-kv-id"

# R2 Bucket (for images)
[[r2_buckets]]
binding = "IMAGES"
bucket_name = "writa-images"

# Environment Variables
[vars]
CLERK_PUBLISHABLE_KEY = "pk_live_..."
ENVIRONMENT = "production"

# Secrets (set via: wrangler secret put CLERK_SECRET_KEY)
# CLERK_SECRET_KEY
```

### 5. Create D1 Database

```bash
# Create database
wrangler d1 create writa-production

# Run migrations
wrangler d1 execute writa-production --file=./schema.sql
```

### 6. Database Schema (schema.sql)

```sql
-- Documents table
CREATE TABLE documents (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    content TEXT,  -- TipTap JSON as string
    plain_text TEXT,
    word_count INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,  -- Unix timestamp
    updated_at INTEGER NOT NULL,
    is_favorite INTEGER DEFAULT 0,
    is_pinned INTEGER DEFAULT 0,
    is_deleted INTEGER DEFAULT 0,
    deleted_at INTEGER
);

-- Indexes for performance
CREATE INDEX idx_documents_user_id ON documents(user_id);
CREATE INDEX idx_documents_updated_at ON documents(updated_at DESC);
CREATE INDEX idx_documents_user_created ON documents(user_id, created_at DESC);

-- Folders table
CREATE TABLE folders (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    parent_id TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE INDEX idx_folders_user_id ON folders(user_id);
CREATE INDEX idx_folders_parent ON folders(parent_id);

-- Document shares (for collaboration)
CREATE TABLE shares (
    id TEXT PRIMARY KEY,
    document_id TEXT NOT NULL,
    shared_by TEXT NOT NULL,
    shared_with TEXT NOT NULL,
    permission TEXT NOT NULL,  -- 'view' or 'edit'
    created_at INTEGER NOT NULL,
    FOREIGN KEY (document_id) REFERENCES documents(id)
);

CREATE INDEX idx_shares_document ON shares(document_id);
CREATE INDEX idx_shares_user ON shares(shared_with);
```

### 7. Worker Code (src/index.ts)

```typescript
import { Router } from 'itty-router';
import { verifyClerkToken, requireAuth } from './auth';
import { 
  listDocuments, 
  getDocument, 
  createDocument, 
  updateDocument, 
  deleteDocument,
  syncDocument 
} from './documents';

export interface Env {
  DB: D1Database;
  CACHE: KVNamespace;
  IMAGES: R2Bucket;
  CLERK_PUBLISHABLE_KEY: string;
  CLERK_SECRET_KEY: string;
}

const router = Router();

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

// Handle CORS preflight
router.options('*', () => new Response(null, { headers: corsHeaders }));

// Health check
router.get('/health', () => {
  return new Response(JSON.stringify({ status: 'ok' }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' }
  });
});

// Documents endpoints (all require auth)
router.get('/documents', requireAuth, listDocuments);
router.post('/documents', requireAuth, createDocument);
router.get('/documents/:id', requireAuth, getDocument);
router.put('/documents/:id', requireAuth, updateDocument);
router.delete('/documents/:id', requireAuth, deleteDocument);
router.post('/documents/:id/sync', requireAuth, syncDocument);

// 404 handler
router.all('*', () => new Response('Not Found', { status: 404 }));

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    return router.handle(request, env, ctx).catch((err) => {
      console.error('Worker error:', err);
      return new Response(
        JSON.stringify({ error: 'Internal Server Error' }), 
        { 
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      );
    });
  },
};
```

### 8. Auth Middleware (src/auth.ts)

```typescript
import { Env } from './index';

export interface ClerkUser {
  userId: string;
  email: string;
}

export async function verifyClerkToken(
  token: string, 
  env: Env
): Promise<ClerkUser | null> {
  try {
    // Verify JWT with Clerk
    const response = await fetch('https://api.clerk.com/v1/tokens/verify', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${env.CLERK_SECRET_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ token }),
    });

    if (!response.ok) {
      return null;
    }

    const data = await response.json();
    
    return {
      userId: data.sub,
      email: data.email,
    };
  } catch (error) {
    console.error('Token verification failed:', error);
    return null;
  }
}

export async function requireAuth(request: Request, env: Env) {
  const authHeader = request.headers.get('Authorization');
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized' }), 
      { status: 401, headers: { 'Content-Type': 'application/json' } }
    );
  }

  const token = authHeader.substring(7);
  const user = await verifyClerkToken(token, env);

  if (!user) {
    return new Response(
      JSON.stringify({ error: 'Invalid token' }), 
      { status: 401, headers: { 'Content-Type': 'application/json' } }
    );
  }

  // Attach user to request for use in handlers
  (request as any).user = user;
}
```

### 9. Document Handlers (src/documents.ts)

```typescript
import { Env } from './index';
import { ClerkUser } from './auth';

export async function listDocuments(request: Request, env: Env) {
  const user = (request as any).user as ClerkUser;
  
  try {
    const { results } = await env.DB.prepare(`
      SELECT * FROM documents 
      WHERE user_id = ? AND is_deleted = 0
      ORDER BY updated_at DESC
      LIMIT 100
    `).bind(user.userId).all();

    return new Response(JSON.stringify(results), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Failed to fetch documents' }), 
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

export async function createDocument(request: Request, env: Env) {
  const user = (request as any).user as ClerkUser;
  const body = await request.json() as any;

  const id = crypto.randomUUID();
  const now = Date.now();

  try {
    await env.DB.prepare(`
      INSERT INTO documents (
        id, user_id, title, content, plain_text, 
        word_count, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `).bind(
      id,
      user.userId,
      body.title || 'Untitled',
      JSON.stringify(body.content || {}),
      body.plainText || '',
      body.wordCount || 0,
      now,
      now
    ).run();

    return new Response(
      JSON.stringify({ id, created_at: now }), 
      { 
        status: 201,
        headers: { 'Content-Type': 'application/json' }
      }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Failed to create document' }), 
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

export async function updateDocument(request: Request, env: Env) {
  const user = (request as any).user as ClerkUser;
  const url = new URL(request.url);
  const id = url.pathname.split('/')[2];
  const body = await request.json() as any;

  try {
    await env.DB.prepare(`
      UPDATE documents 
      SET title = ?, content = ?, plain_text = ?, 
          word_count = ?, updated_at = ?
      WHERE id = ? AND user_id = ?
    `).bind(
      body.title,
      JSON.stringify(body.content),
      body.plainText,
      body.wordCount,
      Date.now(),
      id,
      user.userId
    ).run();

    return new Response(
      JSON.stringify({ success: true }), 
      { headers: { 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ error: 'Failed to update document' }), 
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
}

// ... implement getDocument, deleteDocument, syncDocument similarly
```

### 10. Deploy Worker

```bash
# Deploy to Cloudflare
wrangler deploy

# Set secrets
wrangler secret put CLERK_SECRET_KEY
```

---

## Part 3: Update Writa SyncService

```swift
class SyncService {
    private let apiURL = URL(string: "https://writa-api.YOUR_SUBDOMAIN.workers.dev")!
    private var authManager: AuthManager
    
    func syncDocument(_ document: Document) async throws {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        let token = try await authManager.getAuthToken()
        
        let body: [String: Any] = [
            "title": document.title,
            "content": String(data: document.content ?? Data(), encoding: .utf8) ?? "{}",
            "plainText": document.plainText,
            "wordCount": document.wordCount
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: apiURL.appendingPathComponent("/documents/\(document.id.uuidString)"))
        request.httpMethod = "PUT"
        request.httpBody = bodyData
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SyncError.serverError("Sync failed")
        }
    }
}
```

---

## Testing

### 1. Test Locally

```bash
# Start local dev server
wrangler dev

# API will be at http://localhost:8787
```

### 2. Test with cURL

```bash
# Health check
curl https://writa-api.YOUR_SUBDOMAIN.workers.dev/health

# Create document (with token)
curl -X POST https://writa-api.YOUR_SUBDOMAIN.workers.dev/documents \
  -H "Authorization: Bearer YOUR_CLERK_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Doc","content":{},"plainText":"Hello"}'
```

---

## Cost Estimate

### Free Tier (Perfect for MVP)
- **Clerk**: 10,000 MAU free
- **Cloudflare Workers**: 100,000 requests/day free
- **D1**: 100,000 reads/day, 100,000 writes/day free
- **R2**: 10GB storage, 1M reads, 1M writes/month free

### Paid (if you scale)
- **Clerk Pro**: $25/month (10,000 MAU, then $0.02/user)
- **Cloudflare Workers**: $5/10M requests
- **D1**: $5/month per 1M reads
- **R2**: $0.015/GB storage

**Estimated cost for 1,000 users**: ~$25-50/month

---

## Production Checklist

- [ ] Set up Clerk production app
- [ ] Deploy Cloudflare Worker
- [ ] Configure D1 database
- [ ] Set up R2 bucket for images
- [ ] Add custom domain
- [ ] Set up monitoring (Cloudflare Analytics)
- [ ] Configure rate limiting
- [ ] Add error tracking (Sentry)
- [ ] Test OAuth flows
- [ ] Test sync from multiple devices

---

## Resources

- [Clerk Documentation](https://clerk.com/docs)
- [Cloudflare Workers](https://developers.cloudflare.com/workers/)
- [D1 Database](https://developers.cloudflare.com/d1/)
- [R2 Storage](https://developers.cloudflare.com/r2/)

This stack gives you:
- ⚡️ Global edge deployment
- 🔐 Enterprise auth
- 💰 Extremely cost-effective
- 🚀 No cold starts
- 📈 Scales automatically
