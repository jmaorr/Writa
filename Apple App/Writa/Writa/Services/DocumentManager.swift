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
    func save(_ document: Document) {
        guard let context = modelContext else { 
            print("❌ DocumentManager.save: No model context configured!")
            return 
        }
        
        document.updatedAt = Date()
        document.isDirty = false
        
        do {
            try context.save()
            print("✅ Saved document: \(document.displayTitle) (isDeleted: \(document.isDeleted))")
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
        print("🗑️ Moving to trash: \(document.displayTitle)")
        print("   Document ID: \(document.id)")
        print("   isDeleted before: \(document.isDeleted)")
        
        document.isDeleted = true
        document.deletedAt = Date()
        document.isDirty = true
        
        print("   isDeleted after: \(document.isDeleted)")
        
        save(document)
        print("🗑️ Saved to trash: \(document.displayTitle)")
    }
    
    /// Restore a document from trash
    func restore(_ document: Document) {
        document.isDeleted = false
        document.deletedAt = nil
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
            predicate: #Predicate { $0.isDeleted == true }
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
                document.isDeleted == true && document.deletedAt != nil
            }
        )
        
        do {
            let trashedDocuments = try context.fetch(descriptor)
            var deletedCount = 0
            
            for document in trashedDocuments {
                if let deletedAt = document.deletedAt, deletedAt < thirtyDaysAgo {
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
            predicate: #Predicate { $0.isDeleted == true }
        )
        
        do {
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }
    
    /// Get all documents that need syncing
    func documentsNeedingSync() -> [Document] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<Document>(
            predicate: #Predicate { $0.isDirty == true && $0.isDeleted == false }
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            return []
        }
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
