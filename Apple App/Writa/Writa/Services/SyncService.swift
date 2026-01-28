//
//  SyncService.swift
//  Writa
//
//  Handles document synchronization with cloud backend.
//  Integrates with Clerk authentication and Cloudflare Workers API.
//

import SwiftUI
import SwiftData
import Combine

// MARK: - Sync Status

enum SyncStatus: Equatable {
    case idle
    case syncing
    case success(Date)
    case error(String)
    
    static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle):
            return true
        case (.syncing, .syncing):
            return true
        case (.success(let lhsDate), .success(let rhsDate)):
            return lhsDate == rhsDate
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

// MARK: - Sync Service

@Observable
class SyncService {
    var syncStatus: SyncStatus = .idle
    var lastSyncDate: Date?
    var isSyncing: Bool {
        if case .syncing = syncStatus { return true }
        return false
    }
    
    private var authManager: AuthManager
    private var documentManager: DocumentManager?
    private let apiClient = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    /// Key for storing last sync timestamp
    private let lastSyncKey = "lastSyncTimestamp"
    
    /// Debounce timer for auto-sync after saves
    private var saveDebounceTimer: Timer?
    private let saveDebounceInterval: TimeInterval = 3.0 // Wait 3 seconds after last save
    
    init(authManager: AuthManager) {
        self.authManager = authManager
        self.apiClient.configure(with: authManager)
        loadLastSyncDate()
        setupAutoSync()
        setupNotificationObservers()
    }
    
    deinit {
        saveDebounceTimer?.invalidate()
    }
    
    /// Configure with document manager for sync queries
    func configure(with documentManager: DocumentManager) {
        self.documentManager = documentManager
        
        // Perform initial sync on configure
        Task {
            await initialSync()
        }
    }
    
    private func loadLastSyncDate() {
        let timestamp = UserDefaults.standard.double(forKey: lastSyncKey)
        if timestamp > 0 {
            lastSyncDate = Date(timeIntervalSince1970: timestamp / 1000)
        }
    }
    
    private func saveLastSyncDate(_ date: Date) {
        UserDefaults.standard.set(date.timeIntervalSince1970 * 1000, forKey: lastSyncKey)
    }
    
    // MARK: - Auto Sync
    
    private func setupAutoSync() {
        // Auto-sync every 5 minutes when authenticated (background periodic sync)
        Timer.publish(every: 300, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.syncIfNeeded()
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Sync when app enters foreground
        NotificationCenter.default.publisher(for: NSApplication.willBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.syncIfNeeded()
                }
            }
            .store(in: &cancellables)
        
        // Sync after document/workspace saves (debounced)
        NotificationCenter.default.publisher(for: Notification.Name("DocumentDidSave"))
            .sink { [weak self] _ in
                self?.scheduleDebouncedSync()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: Notification.Name("WorkspaceDidChange"))
            .sink { [weak self] _ in
                self?.scheduleDebouncedSync()
            }
            .store(in: &cancellables)
    }
    
    /// Initial sync on app launch/configure
    private func initialSync() async {
        guard authManager.isAuthenticated else {
            print("⏭️ Skipping initial sync - not authenticated")
            return
        }
        print("🚀 Starting initial sync...")
        await sync()
    }
    
    /// Schedule a debounced sync after saves (waits for quiet period)
    private func scheduleDebouncedSync() {
        saveDebounceTimer?.invalidate()
        saveDebounceTimer = Timer.scheduledTimer(withTimeInterval: saveDebounceInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.syncIfNeeded()
            }
        }
    }
    
    private func syncIfNeeded() async {
        guard authManager.isAuthenticated else { return }
        guard !isSyncing else { return }
        
        // Smart optimization: Skip sync if no local changes and recently synced
        let hasLocalChanges = await MainActor.run {
            let dirtyDocs = documentManager?.documentsNeedingSync().count ?? 0
            let dirtyWorkspaces = documentManager?.workspacesNeedingSync().count ?? 0
            return dirtyDocs > 0 || dirtyWorkspaces > 0
        }
        
        // Only skip if: no local changes AND synced in last 30 seconds
        let recentlySynced = lastSyncDate.map { Date().timeIntervalSince($0) < 30 } ?? false
        
        if !hasLocalChanges && recentlySynced {
            print("⏭️ Skipping sync - no local changes and recently synced")
            return
        }
        
        await sync()
    }
    
    // MARK: - Full Sync
    
    /// Sync all local changes to cloud
    func sync() async {
        print("🔄 Sync started...")
        print("   Auth state: \(authManager.isAuthenticated ? "authenticated" : "NOT authenticated")")
        
        guard authManager.isAuthenticated else {
            print("❌ Sync aborted: User not authenticated")
            return
        }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        do {
            // Step 1: Pull changes from server since last sync
            // Use actual incremental sync for both documents and workspaces
            let since = lastSyncDate.map { Int($0.timeIntervalSince1970 * 1000) } ?? 0
            print("📥 Pulling changes since: \(since) (\(lastSyncDate?.formatted() ?? "never"))")
            
            let pullResponse: SyncPullResponse = try await apiClient.get(
                "/sync",
                queryItems: [
                    URLQueryItem(name: "since", value: String(since)),
                    URLQueryItem(name: "includeDeleted", value: "true")
                ]
            )
            
            // Step 2: Collect local changes FIRST (before applying server changes)
            // This prevents server data from overwriting uncommitted local changes
            let (documentsToPush, workspacesToPush) = await MainActor.run { () -> ([DocumentChange], [WorkspaceChange]) in
                // Collect local items that need to push to server
                let dirtyDocs = documentManager?.documentsNeedingSync() ?? []
                print("📤 Found \(dirtyDocs.count) dirty documents")
                
                // Filter out documents that would conflict (server version > local version)
                // For conflicts, update local version to match server so next edit can sync
                let docsToSync = dirtyDocs.filter { doc in
                    if let serverDoc = pullResponse.documents.first(where: { $0.id == doc.id.uuidString }) {
                        // Check if local is behind server
                        if doc.serverVersion < serverDoc.version {
                            // Update local version to match server (so next edit will have correct version)
                            doc.serverVersion = serverDoc.version
                            // Keep isDirty so it syncs on next attempt with updated version
                            return false // Skip this sync, will sync next time
                        }
                        return true // Versions match or local is newer - can sync
                    }
                    return true // New local document
                }
                
                print("📤 Documents needing sync: \(docsToSync.count)")
                
                // Workspaces: collect dirty workspaces + workspaces referenced by documents
                var workspaceDict: [UUID: Workspace] = [:]
                
                // Add explicitly dirty workspaces
                let dirtyWorkspaces = documentManager?.workspacesNeedingSync() ?? []
                for ws in dirtyWorkspaces {
                    workspaceDict[ws.id] = ws
                }
                
                // Add workspaces referenced by dirty documents (including parent chain if not on server)
                for doc in docsToSync {
                    if let workspace = doc.workspace {
                        // Walk up the workspace hierarchy and include any that don't exist on server
                        var current: Workspace? = workspace
                        while let ws = current {
                            let existsOnServer = pullResponse.workspaces.contains { $0.id == ws.id.uuidString }
                            if !existsOnServer && workspaceDict[ws.id] == nil {
                                print("   📎 Including workspace '\(ws.name)' (FK dependency)")
                                workspaceDict[ws.id] = ws
                            }
                            current = ws.parent
                        }
                    }
                }
                
                // Filter out workspaces that would conflict (server version > local version)
                let workspacesToSync = workspaceDict.values.filter { ws in
                    if let serverWs = pullResponse.workspaces.first(where: { $0.id == ws.id.uuidString }) {
                        // Check if local is behind server
                        if ws.serverVersion < serverWs.version {
                            // Update local version to match server
                            ws.serverVersion = serverWs.version
                            return false // Skip this sync
                        }
                        return true // Versions match or local is newer
                    }
                    return true // New local workspace
                }
                
                print("📤 Workspaces to push: \(workspacesToSync.count)")
                
                // Map to DTOs - server handles ordering (topological sort)
                let docChanges = docsToSync.map { createDocumentChange(from: $0) }
                let wsChanges = workspacesToSync.map { createWorkspaceChange(from: $0) }
                
                return (docChanges, wsChanges)
            }
            
            // Step 3: Apply server changes (after collecting local changes to prevent overwrites)
            await MainActor.run {
                applyServerChanges(pullResponse)
            }
            
            // Step 4: Push local changes to server
            if !documentsToPush.isEmpty || !workspacesToPush.isEmpty {
                let pushRequest = SyncPushRequest(
                    documents: documentsToPush.isEmpty ? nil : documentsToPush,
                    workspaces: workspacesToPush.isEmpty ? nil : workspacesToPush,
                    settings: nil
                )
                
                let pushResponse: SyncPushResponse = try await apiClient.post("/sync", body: pushRequest)
                print("📥 Push response: \(pushResponse.results.documents.count) docs, \(pushResponse.results.workspaces.count) workspaces")
                
                // Step 5: Mark pushed items as synced
                await MainActor.run {
                    for result in pushResponse.results.documents {
                        if let doc = documentManager?.findDocument(byId: result.id) {
                            documentManager?.markDocumentSynced(doc, serverVersion: result.version)
                        }
                    }
                    for result in pushResponse.results.workspaces {
                        if let ws = documentManager?.findWorkspace(byId: result.id) {
                            documentManager?.markWorkspaceSynced(ws, serverVersion: result.version)
                        }
                    }
                    
                    // Log any conflicts
                    for conflict in pushResponse.results.conflicts {
                        print("⚠️ Conflict: \(conflict.type) \(conflict.id) - server version \(conflict.serverVersion)")
                    }
                }
            }
            
            // Update last sync date
            let now = Date()
            saveLastSyncDate(now)
            
            await MainActor.run {
                self.lastSyncDate = now
                self.syncStatus = .success(now)
            }
            
            print("✅ Sync completed successfully")
            
        } catch {
            print("❌ Sync failed: \(error)")
            await MainActor.run {
                self.syncStatus = .error(error.localizedDescription)
            }
        }
    }
    
    /// Apply changes received from server to local data
    @MainActor
    private func applyServerChanges(_ response: SyncPullResponse) {
        print("📥 Received \(response.documents.count) documents, \(response.workspaces.count) workspaces from server")
        
        guard let dm = documentManager else {
            print("❌ No document manager configured")
            return
        }
        
        // Apply workspace changes from server
        for serverWs in response.workspaces {
            if let localWs = dm.findWorkspace(byId: serverWs.id) {
                // Skip if local workspace has uncommitted changes (isDirty)
                if localWs.isDirty {
                    print("   ⏭️ Skipping workspace '\(serverWs.name)': has local uncommitted changes")
                    continue
                }
                
                // Apply server changes (local is clean, so server is source of truth)
                print("   📥 Updating workspace: \(serverWs.name)")
                dm.updateWorkspaceFromServer(localWs, with: serverWs)
            } else {
                // New workspace from server - create locally
                print("   📥 Creating workspace from server: \(serverWs.name)")
                dm.createWorkspaceFromServer(serverWs)
            }
        }
        
        // Apply document changes from server
        for serverDoc in response.documents {
            if let localDoc = dm.findDocument(byId: serverDoc.id) {
                print("   📄 Found local document '\(serverDoc.title)': isDirty=\(localDoc.isDirty), isTrashed=\(localDoc.isTrashed)")
                
                // Skip if local document has uncommitted changes (isDirty)
                // These will be pushed in the current sync cycle
                if localDoc.isDirty {
                    print("   ⏭️ Skipping '\(serverDoc.title)': has local uncommitted changes")
                    continue
                }
                
                // Apply server changes (local is clean, so server is source of truth)
                print("   📥 Updating document: \(serverDoc.title) -> isTrashed: \(localDoc.isTrashed) → \(serverDoc.isDeleted)")
                dm.updateDocumentFromServer(localDoc, with: serverDoc)
            } else {
                // New document from server - create locally
                print("   📥 Creating document from server: \(serverDoc.title) (isDeleted: \(serverDoc.isDeleted))")
                dm.createDocumentFromServer(serverDoc)
            }
        }
        
        // No longer needed - deletedDocumentIds is redundant when includeDeleted=true
        // Deleted documents come through the main documents array with isDeleted flag
    }
    
    // MARK: - Document Sync
    
    /// Sync a specific document to server
    func syncDocument(_ document: Document) async throws {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        let dto = createDocumentChange(from: document)
        let _: DocumentUpdateResponse = try await apiClient.put("/documents/\(document.id)", body: dto)
        
        await MainActor.run {
            documentManager?.markDocumentSynced(document)
        }
    }
    
    /// Fetch document from server
    func fetchDocument(id: String) async throws -> DocumentDTO {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        let response: DocumentGetResponse = try await apiClient.get("/documents/\(id)")
        return response.document
    }
    
    /// Delete document from server
    func deleteDocument(id: String) async throws {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        try await apiClient.delete("/documents/\(id)")
    }
    
    // MARK: - Workspace Sync
    
    /// Sync a specific workspace to server
    func syncWorkspace(_ workspace: Workspace) async throws {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        let dto = createWorkspaceChange(from: workspace)
        let _: WorkspaceUpdateResponse = try await apiClient.put("/workspaces/\(workspace.id)", body: dto)
        
        await MainActor.run {
            documentManager?.markWorkspaceSynced(workspace)
        }
    }
    
    /// Fetch workspace from server
    func fetchWorkspace(id: String) async throws -> WorkspaceDTO {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        let response: WorkspaceGetResponse = try await apiClient.get("/workspaces/\(id)")
        return response.workspace
    }
    
    /// Delete workspace from server
    func deleteWorkspace(id: String) async throws {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        try await apiClient.delete("/workspaces/\(id)")
    }
    
    // MARK: - Settings Sync
    
    /// Sync user settings to server
    func syncSettings() async throws {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        // Get settings from SettingsManager
        let settings = SettingsManager.shared.exportToJSON()
        let request = SettingsUpdateRequest(settings: settings)
        let _: SettingsUpdateResponse = try await apiClient.put("/settings", body: request)
    }
    
    /// Fetch user settings from server
    func fetchSettings() async throws -> UserSettingsDTO {
        guard authManager.isAuthenticated else {
            throw SyncError.notAuthenticated
        }
        
        return try await apiClient.get("/settings")
    }
    
    // MARK: - Helper Methods
    
    private func createDocumentChange(from document: Document) -> DocumentChange {
        return DocumentChange(
            id: document.id.uuidString,
            title: document.title,
            summary: document.summary,
            content: document.content.map { String(data: $0, encoding: .utf8) } ?? nil,
            plainText: document.plainText,
            wordCount: document.wordCount,
            workspaceId: document.workspace?.id.uuidString,
            tags: document.tags,
            isFavorite: document.isFavorite,
            isPinned: document.isPinned,
            isDeleted: document.isTrashed,  // Map local isTrashed to API isDeleted
            deletedAt: document.trashedAt.map { Int($0.timeIntervalSince1970 * 1000) },
            version: document.serverVersion,
            createdAt: Int(document.createdAt.timeIntervalSince1970 * 1000),
            updatedAt: Int(document.updatedAt.timeIntervalSince1970 * 1000)
        )
    }
    
    private func createWorkspaceChange(from workspace: Workspace) -> WorkspaceChange {
        return WorkspaceChange(
            id: workspace.id.uuidString,
            name: workspace.name,
            icon: workspace.icon,
            color: workspace.color,
            sortOrder: workspace.sortOrder,
            parentId: workspace.parent?.id.uuidString,
            isExpanded: workspace.isExpanded,
            version: workspace.serverVersion,
            createdAt: Int(workspace.createdAt.timeIntervalSince1970 * 1000),
            updatedAt: Int(workspace.updatedAt.timeIntervalSince1970 * 1000)
        )
    }
    
    // MARK: - Conflict Resolution
    
    private func resolveDocumentConflict(
        local: Document,
        remote: DocumentDTO
    ) -> ConflictResolution {
        // Simple last-write-wins strategy
        if local.updatedAt > remote.updatedAt {
            return .keepLocal
        } else {
            return .useRemote
        }
    }
    
    private func resolveWorkspaceConflict(
        local: Workspace,
        remote: WorkspaceDTO
    ) -> ConflictResolution {
        // Simple last-write-wins strategy
        if local.updatedAt > remote.updatedAt {
            return .keepLocal
        } else {
            return .useRemote
        }
    }
}

// MARK: - Conflict Resolution

enum ConflictResolution {
    case keepLocal
    case useRemote
    case merge
}

// MARK: - API Request/Response Types

struct SyncPullResponse: Codable {
    let documents: [DocumentDTO]
    let workspaces: [WorkspaceDTO]
    let settings: UserSettingsDTO?
    let deletedDocumentIds: [String]
    let serverTime: Int
}

struct SyncPushRequest: Codable {
    let documents: [DocumentChange]?
    let workspaces: [WorkspaceChange]?
    let settings: SettingsChange?
}

struct SyncPushResponse: Codable {
    let success: Bool
    let results: SyncResults
    let serverTime: Int
}

struct SyncResults: Codable {
    let documents: [SyncItemResult]
    let workspaces: [SyncItemResult]
    let settings: SyncSettingsResult?
    let conflicts: [SyncConflict]
}

struct SyncItemResult: Codable {
    let id: String
    let version: Int
    let status: String
}

struct SyncSettingsResult: Codable {
    let version: Int
    let status: String
}

struct SyncConflict: Codable {
    let type: String
    let id: String
    let serverVersion: Int
}

struct DocumentChange: Codable {
    let id: String
    let title: String
    let summary: String?
    let content: String?
    let plainText: String?
    let wordCount: Int?
    let workspaceId: String?
    let tags: [String]?
    let isFavorite: Bool?
    let isPinned: Bool?
    let isDeleted: Bool?
    let deletedAt: Int?
    let version: Int
    let createdAt: Int
    let updatedAt: Int
}

struct WorkspaceChange: Codable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let sortOrder: Int
    let parentId: String?
    let isExpanded: Bool
    let version: Int
    let createdAt: Int
    let updatedAt: Int
}

struct SettingsChange: Codable {
    let settings: [String: AnyCodableValue]
    let version: Int
    let updatedAt: Int
}

struct DocumentGetResponse: Codable {
    let document: DocumentDTO
}

struct DocumentUpdateResponse: Codable {
    let success: Bool
    let document: DocumentVersionInfo
}

struct DocumentVersionInfo: Codable {
    let id: String
    let version: Int
    let updatedAt: Int
}

struct WorkspaceGetResponse: Codable {
    let workspace: WorkspaceDTO
}

struct WorkspaceUpdateResponse: Codable {
    let success: Bool
    let workspace: DocumentVersionInfo
}

struct SettingsUpdateRequest: Codable {
    let settings: [String: Any]
    
    init(settings: [String: Any]) {
        self.settings = settings
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let codableSettings = settings.mapValues { AnyCodableValue($0) }
        try container.encode(codableSettings, forKey: .settings)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let codableSettings = try container.decode([String: AnyCodableValue].self, forKey: .settings)
        settings = codableSettings.mapValues { $0.value }
    }
    
    enum CodingKeys: String, CodingKey {
        case settings
    }
}

struct SettingsUpdateResponse: Codable {
    let success: Bool
    let version: Int
    let updatedAt: Int
}

// MARK: - Sync DTOs (Data Transfer Objects)

/// Document data for API transfer
struct DocumentDTO: Codable {
    let id: String
    let title: String
    let summary: String?
    let content: String?
    let plainText: String?
    let wordCount: Int
    let workspaceId: String?
    let tags: [String]?
    let isFavorite: Bool
    let isPinned: Bool
    let isDeleted: Bool
    let deletedAt: Date?
    let version: Int
    let createdAt: Date
    let updatedAt: Date
}

/// Workspace data for API transfer
struct WorkspaceDTO: Codable {
    let id: String
    let name: String
    let icon: String
    let color: String
    let sortOrder: Int
    let parentId: String?
    let isExpanded: Bool
    let version: Int
    let createdAt: Date
    let updatedAt: Date
}

/// User settings data for API transfer
struct UserSettingsDTO: Codable {
    let userId: String
    let settings: [String: AnyCodableValue]
    let version: Int
    let updatedAt: Date
}

/// Helper for encoding arbitrary JSON values
struct AnyCodableValue: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodableValue].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            value = dict.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodableValue($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodableValue($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - Sync Errors

enum SyncError: LocalizedError {
    case notAuthenticated
    case notImplemented
    case networkError
    case conflictError
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to sync"
        case .notImplemented:
            return "Sync is not yet implemented"
        case .networkError:
            return "Network connection error"
        case .conflictError:
            return "Conflict detected - please resolve manually"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Environment Key

private struct SyncServiceKey: EnvironmentKey {
    static let defaultValue: SyncService? = nil
}

extension EnvironmentValues {
    var syncService: SyncService? {
        get { self[SyncServiceKey.self] }
        set { self[SyncServiceKey.self] = newValue }
    }
}
