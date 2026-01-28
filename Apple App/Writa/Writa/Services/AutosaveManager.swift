//
//  AutosaveManager.swift
//  Writa
//
//  Handles autosaving of documents with debouncing.
//  
//  Strategy:
//  - Update document model immediately on content change (SwiftData tracks changes)
//  - Debounce the actual disk save to batch I/O operations
//  - Synchronous save on document switch to prevent data loss
//

import SwiftUI
import SwiftData

// MARK: - Autosave Manager

@Observable
class AutosaveManager {
    /// Debounce delay before persisting to disk (1 second)
    private let debounceDelay: TimeInterval = 1.0
    
    /// Current document being edited
    private(set) var currentDocument: Document?
    
    /// Whether autosave is currently enabled
    var isEnabled: Bool = true
    
    /// Debounce task for disk persistence
    private var debounceTask: Task<Void, Never>?
    
    /// Document manager for persistence
    private var documentManager: DocumentManager?
    
    // MARK: - Configuration
    
    func configure(documentManager: DocumentManager) {
        self.documentManager = documentManager
    }
    
    // MARK: - Document Lifecycle
    
    /// Start editing a document
    func startEditing(_ document: Document) {
        // If switching documents, save the previous one first (synchronously)
        if let current = currentDocument, current.id != document.id {
            flushPendingSave(for: current)
        }
        
        currentDocument = document
        // Update lastOpenedAt without marking as dirty (it's just tracking metadata, not content change)
        document.lastOpenedAt = Date()
        
        // Save the lastOpenedAt change without updating timestamp or marking dirty
        documentManager?.save(document, updateTimestamp: false)
    }
    
    /// Stop editing current document (synchronous save)
    func stopEditing() {
        if let document = currentDocument {
            flushPendingSave(for: document)
            print("📝 Stopped editing: \(document.displayTitle)")
        }
        currentDocument = nil
    }
    
    // MARK: - Content Updates
    
    /// Called when editor content changes
    /// Updates document model immediately, debounces disk persistence
    func contentDidChange(
        content: Data?,
        plainText: String,
        wordCount: Int
    ) {
        guard isEnabled, let document = currentDocument else { return }
        
        // Update document model immediately (SwiftData tracks these changes)
        document.content = content
        document.plainText = plainText
        document.wordCount = wordCount
        
        // Extract and update title from content
        let firstLine = plainText
            .components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .trimmingCharacters(in: .whitespaces)
        document.title = firstLine.map { String($0.prefix(100)) } ?? "Untitled"
        
        document.updatedAt = Date()
        document.isDirty = true
        
        // Cancel previous debounce task
        debounceTask?.cancel()
        
        // Schedule debounced disk save
        debounceTask = Task { @MainActor [weak self, documentId = document.id] in
            do {
                try await Task.sleep(for: .seconds(self?.debounceDelay ?? 1.0))
                
                // Verify we're still editing the same document
                guard let self = self,
                      let doc = self.currentDocument,
                      doc.id == documentId else { return }
                
                self.persistToDisk(doc)
            } catch {
                // Task cancelled - that's fine, content is already in the model
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Synchronously flush any pending save for a document
    private func flushPendingSave(for document: Document) {
        // Cancel any pending debounce
        debounceTask?.cancel()
        debounceTask = nil
        
        // If document has unsaved changes, persist now
        if document.isDirty {
            persistToDisk(document)
        }
    }
    
    /// Persist document to disk (keeps isDirty for cloud sync)
    private func persistToDisk(_ document: Document) {
        // Just save to local disk - keep isDirty = true for cloud sync
        // Don't update timestamp (already set in contentDidChange)
        documentManager?.save(document, updateTimestamp: false)
        print("💾 Saved: \(document.displayTitle) (\(document.content?.count ?? 0) bytes)")
    }
}

// MARK: - Environment Key

private struct AutosaveManagerKey: EnvironmentKey {
    static let defaultValue = AutosaveManager()
}

extension EnvironmentValues {
    var autosaveManager: AutosaveManager {
        get { self[AutosaveManagerKey.self] }
        set { self[AutosaveManagerKey.self] = newValue }
    }
}
