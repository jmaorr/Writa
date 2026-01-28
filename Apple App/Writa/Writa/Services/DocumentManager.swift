//
//  DocumentManager.swift
//  Writa
//
//  Centralized service for document CRUD operations.
//  Handles creation, saving, soft delete (trash), and restoration.
//

import SwiftUI
import SwiftData

// MARK: - Document Manager

@Observable
class DocumentManager {
    private var modelContext: ModelContext?
    
    /// Initialize with a model context
    func configure(with context: ModelContext) {
        self.modelContext = context
        print("✅ DocumentManager configured with model context")
    }
    
    // MARK: - Create
    
    /// Create a new document
    @discardableResult
    func create(
        title: String = "Untitled",
        in workspace: Workspace? = nil
    ) -> Document? {
        guard let context = modelContext else {
            print("❌ DocumentManager: No model context configured")
            return nil
        }
        
        let document = Document(title: title, workspace: workspace)
        context.insert(document)
        
        // Save immediately to persist the new document
        do {
            try context.save()
            print("✅ Created document: \(document.id)")
            return document
        } catch {
            print("❌ Failed to create document: \(error)")
            return nil
        }
    }
    
    // MARK: - Save
    
    /// Save a document (explicit save)
    func save(_ document: Document, updateTimestamp: Bool = true) {
        guard let context = modelContext else { 
            print("❌ DocumentManager.save: No model context configured!")
            return 
        }
        
        // Only update timestamp and mark dirty if this is a real content change
        if updateTimestamp {
            document.updatedAt = Date()
            document.isDirty = true  // Mark as needing sync (will be set to false after successful sync)
        }
        
        do {
            try context.save()
            print("✅ Saved document: \(document.displayTitle) (isDirty: \(document.isDirty))")
            
            // Trigger auto-sync only if this was a real change
            if updateTimestamp {
                NotificationCenter.default.post(name: Notification.Name("DocumentDidSave"), object: nil)
            }
        } catch {
            print("❌ Failed to save document: \(error)")
        }
    }
    
    /// Save all pending changes
    func saveAll() {
        guard let context = modelContext else { return }
        
        do {
            try context.save()
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
    
    // MARK: - Soft Delete (Trash)
    
    /// Move a document to trash (soft delete)
    func moveToTrash(_ document: Document) {
        guard let context = modelContext else { return }
        
        document.isTrashed = true
        document.trashedAt = Date()
        document.updatedAt = Date()
        document.isDirty = true
        
        do {
            try context.save()
            NotificationCenter.default.post(name: Notification.Name("DocumentDidSave"), object: nil)
        } catch {
            print("❌ Failed to move to trash: \(error)")
        }
    }
    
    /// Restore a document from trash
    func restore(_ document: Document) {
        document.isTrashed = false
        document.trashedAt = nil
        document.isDirty = true
        
        save(document)
        print("♻️ Restored from trash: \(document.displayTitle)")
    }
    
    // MARK: - Permanent Delete
    
    /// Permanently delete a document (cannot be undone)
    func permanentlyDelete(_ document: Document) {
        guard let context = modelContext else { return }
        
        let title = document.displayTitle
        context.delete(document)
        
        do {
            try context.save()
            print("🔥 Permanently deleted: \(title)")
        } catch {
            print("❌ Failed to permanently delete: \(error)")
        }
    }
    
    /// Empty the trash (permanently delete all trashed documents)
    func emptyTrash() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.isTrashed == true }
        )
        
        do {
            let trashedDocuments = try context.fetch(descriptor)
            let count = trashedDocuments.count
            
            for document in trashedDocuments {
                context.delete(document)
            }
            
            try context.save()
            print("🔥 Emptied trash: \(count) documents permanently deleted")
        } catch {
            print("❌ Failed to empty trash: \(error)")
        }
    }
    
    /// Clean up documents that have been in trash for more than 30 days
    func cleanupExpiredTrash() {
        guard let context = modelContext else { return }
        
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { document in
                document.isTrashed == true && document.trashedAt != nil
            }
        )
        
        do {
            let trashedDocuments = try context.fetch(descriptor)
            var deletedCount = 0
            
            for document in trashedDocuments {
                if let trashedAt = document.trashedAt, trashedAt < thirtyDaysAgo {
                    context.delete(document)
                    deletedCount += 1
                }
            }
            
            if deletedCount > 0 {
                try context.save()
                print("🧹 Cleaned up \(deletedCount) expired documents from trash")
            }
        } catch {
            print("❌ Failed to cleanup expired trash: \(error)")
        }
    }
    
    // MARK: - Queries
    
    /// Get count of documents in trash
    func trashCount() -> Int {
        guard let context = modelContext else { return 0 }
        
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.isTrashed == true }
        )
        
        do {
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
    
    /// Get all documents that need syncing (includes trashed documents so deletions sync to server)
    func documentsNeedingSync() -> [Document] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.isDirty == true }
        )
        
        return (try? context.fetch(descriptor)) ?? []
    }
    
    // MARK: - Workspace Operations
    
    /// Create a new workspace
    @discardableResult
    func createWorkspace(
        name: String,
        icon: String = "folder",
        color: String = "systemBlue",
        parent: Workspace? = nil
    ) -> Workspace? {
        guard let context = modelContext else {
            print("❌ DocumentManager: No model context configured")
            return nil
        }
        
        let workspace = Workspace(name: name, icon: icon, color: color, parent: parent)
        workspace.isDirty = true
        context.insert(workspace)
        
        do {
            try context.save()
            print("✅ Created workspace: \(workspace.id)")
            return workspace
        } catch {
            print("❌ Failed to create workspace: \(error)")
            return nil
        }
    }
    
    /// Save a workspace (explicit save)
    func save(_ workspace: Workspace) {
        guard let context = modelContext else {
            print("❌ DocumentManager.save: No model context configured!")
            return
        }
        
        workspace.updatedAt = Date()
        workspace.isDirty = true
        
        do {
            try context.save()
            print("✅ Saved workspace: \(workspace.name)")
            
            // Trigger auto-sync
            NotificationCenter.default.post(name: Notification.Name("WorkspaceDidChange"), object: nil)
        } catch {
            print("❌ Failed to save workspace: \(error)")
        }
    }
    
    /// Delete a workspace (moves documents to no workspace)
    func deleteWorkspace(_ workspace: Workspace) {
        guard let context = modelContext else { return }
        
        let name = workspace.name
        
        // Move all documents out of this workspace before deletion
        for document in workspace.documents {
            document.workspace = nil
            document.isDirty = true
        }
        
        // Move children to parent (or make them root)
        for child in workspace.children {
            child.parent = workspace.parent
            child.isDirty = true
        }
        
        context.delete(workspace)
        
        do {
            try context.save()
            print("🗑️ Deleted workspace: \(name)")
        } catch {
            print("❌ Failed to delete workspace: \(error)")
        }
    }
    
    /// Get all workspaces
    func getAllWorkspaces() -> [Workspace] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Workspace>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Get all workspaces that need syncing (dirty flag for push)
    func workspacesNeedingSync() -> [Workspace] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.isDirty == true }
        )
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Find workspace by ID string
    func findWorkspace(byId id: String) -> Workspace? {
        guard let context = modelContext,
              let uuid = UUID(uuidString: id) else { return nil }
        let descriptor = FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? context.fetch(descriptor).first
    }
    
    /// Find document by ID string
    func findDocument(byId id: String) -> Document? {
        guard let context = modelContext,
              let uuid = UUID(uuidString: id) else { return nil }
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.id == uuid }
        )
        return try? context.fetch(descriptor).first
    }
    
    /// Mark workspace as synced
    func markWorkspaceSynced(_ workspace: Workspace, serverVersion: Int? = nil) {
        workspace.isDirty = false
        workspace.lastSyncedAt = Date()
        if let version = serverVersion {
            workspace.serverVersion = version
        }
        saveAll()
    }
    
    /// Mark document as synced
    func markDocumentSynced(_ document: Document, serverVersion: Int? = nil) {
        document.isDirty = false
        document.lastSyncedAt = Date()
        if let version = serverVersion {
            document.serverVersion = version
        }
        saveAll()
    }
    
    /// Mark all unsynced items as dirty (for initial sync)
    func markAllForSync() {
        guard let context = modelContext else { return }
        
        // Mark all documents that have never synced
        let docDescriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.lastSyncedAt == nil && $0.isTrashed == false }
        )
        if let docs = try? context.fetch(docDescriptor) {
            for doc in docs {
                doc.isDirty = true
            }
            print("📄 Marked \(docs.count) documents for sync")
        }
        
        // Mark all workspaces that have never synced
        let wsDescriptor = FetchDescriptor<Workspace>(
            predicate: #Predicate { $0.lastSyncedAt == nil }
        )
        if let workspaces = try? context.fetch(wsDescriptor) {
            for ws in workspaces {
                ws.isDirty = true
            }
            print("📂 Marked \(workspaces.count) workspaces for sync")
        }
        
        saveAll()
    }
    
    // MARK: - Server Sync Helpers
    
    /// Update local workspace from server data
    func updateWorkspaceFromServer(_ workspace: Workspace, with serverData: WorkspaceDTO) {
        workspace.name = serverData.name
        workspace.icon = serverData.icon
        workspace.color = serverData.color
        workspace.sortOrder = serverData.sortOrder
        workspace.isExpanded = serverData.isExpanded
        workspace.serverVersion = serverData.version
        workspace.updatedAt = serverData.updatedAt
        workspace.lastSyncedAt = Date()
        workspace.isDirty = false
        
        // Handle parent relationship
        if let parentId = serverData.parentId {
            workspace.parent = findWorkspace(byId: parentId)
        } else {
            workspace.parent = nil
        }
        
        saveAll()
    }
    
    /// Create local workspace from server data
    func createWorkspaceFromServer(_ serverData: WorkspaceDTO) {
        guard let context = modelContext,
              let uuid = UUID(uuidString: serverData.id) else { return }
        
        let workspace = Workspace(name: serverData.name, icon: serverData.icon, color: serverData.color)
        workspace.id = uuid
        workspace.sortOrder = serverData.sortOrder
        workspace.isExpanded = serverData.isExpanded
        workspace.serverVersion = serverData.version
        workspace.createdAt = serverData.createdAt
        workspace.updatedAt = serverData.updatedAt
        workspace.lastSyncedAt = Date()
        workspace.isDirty = false
        workspace.serverId = serverData.id
        
        // Handle parent relationship
        if let parentId = serverData.parentId {
            workspace.parent = findWorkspace(byId: parentId)
        }
        
        context.insert(workspace)
        saveAll()
    }
    
    /// Update local document from server data
    func updateDocumentFromServer(_ document: Document, with serverData: DocumentDTO) {
        // IMPORTANT: Never restore a locally-trashed document from server
        // This prevents the "bouncing back from trash" bug
        if document.isTrashed && !serverData.isDeleted {
            print("⚠️ Skipping restore of locally-trashed document: \(serverData.title)")
            print("   Local isTrashed=true, server isDeleted=false")
            print("   Keeping local trash state")
            return
        }
        
        document.title = serverData.title
        document.summary = serverData.summary ?? ""
        document.plainText = serverData.plainText ?? ""
        document.wordCount = serverData.wordCount
        document.tags = serverData.tags ?? []
        document.isFavorite = serverData.isFavorite
        document.isPinned = serverData.isPinned
        document.isTrashed = serverData.isDeleted  // API uses isDeleted, local uses isTrashed
        document.trashedAt = serverData.deletedAt
        document.serverVersion = serverData.version
        document.updatedAt = serverData.updatedAt
        document.lastSyncedAt = Date()
        document.isDirty = false
        
        // Update content if provided
        if let contentString = serverData.content {
            document.content = contentString.data(using: .utf8)
        }
        
        // Handle workspace relationship
        if let workspaceId = serverData.workspaceId {
            document.workspace = findWorkspace(byId: workspaceId)
        } else {
            document.workspace = nil
        }
        
        saveAll()
    }
    
    /// Create local document from server data
    func createDocumentFromServer(_ serverData: DocumentDTO) {
        guard let context = modelContext,
              let uuid = UUID(uuidString: serverData.id) else { return }
        
        let document = Document()
        document.id = uuid
        document.title = serverData.title
        document.summary = serverData.summary ?? ""
        document.plainText = serverData.plainText ?? ""
        document.wordCount = serverData.wordCount
        document.tags = serverData.tags ?? []
        document.isFavorite = serverData.isFavorite
        document.isPinned = serverData.isPinned
        document.isTrashed = serverData.isDeleted  // API uses isDeleted, local uses isTrashed
        document.trashedAt = serverData.deletedAt
        document.serverVersion = serverData.version
        document.createdAt = serverData.createdAt
        document.updatedAt = serverData.updatedAt
        document.lastSyncedAt = Date()
        document.isDirty = false
        document.serverId = serverData.id
        
        // Set content if provided
        if let contentString = serverData.content {
            document.content = contentString.data(using: .utf8)
        }
        
        // Handle workspace relationship
        if let workspaceId = serverData.workspaceId {
            document.workspace = findWorkspace(byId: workspaceId)
        }
        
        context.insert(document)
        saveAll()
    }
    
    /// Update workspace order (triggers sync)
    func updateWorkspaceOrder(_ workspaces: [Workspace]) {
        for (index, workspace) in workspaces.enumerated() {
            workspace.sortOrder = index
            workspace.updatedAt = Date()  // Important: update timestamp for sync comparison
        }
        saveAll()
    }
    
    /// Move document to workspace (marks both as dirty)
    func moveDocument(_ document: Document, to workspace: Workspace?) {
        let oldWorkspace = document.workspace
        document.workspace = workspace
        document.isDirty = true
        
        // Mark old workspace as dirty if it exists
        if let old = oldWorkspace {
            old.isDirty = true
        }
        
        // Mark new workspace as dirty if it exists
        if let new = workspace {
            new.isDirty = true
        }
        
        save(document)
    }
}

// MARK: - Environment Key

private struct DocumentManagerKey: EnvironmentKey {
    static let defaultValue = DocumentManager()
}

extension EnvironmentValues {
    var documentManager: DocumentManager {
        get { self[DocumentManagerKey.self] }
        set { self[DocumentManagerKey.self] = newValue }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let createNewDocument = Notification.Name("createNewDocument")
    static let createNewWorkspace = Notification.Name("createNewWorkspace")
    static let taskToggled = Notification.Name("taskToggled")
}

/// Info passed with taskToggled notification
struct TaskToggleInfo {
    let documentID: UUID
    let nodeIndex: Int
    let isCompleted: Bool
}
