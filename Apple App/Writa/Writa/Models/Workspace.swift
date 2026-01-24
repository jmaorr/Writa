//
//  Workspace.swift
//  Writa
//
//  Workspace model for organizing documents.
//  Workspaces can be nested infinitely (workspaces within workspaces).
//

import Foundation
import SwiftData

@Model
final class Workspace {
    var id: UUID
    var name: String
    var icon: String  // SF Symbol name
    var color: String  // Hex color or system color name
    var sortOrder: Int
    
    // Hierarchy (for nested workspaces)
    var parent: Workspace?
    @Relationship(deleteRule: .cascade, inverse: \Workspace.parent)
    var children: [Workspace]
    
    // Documents in this workspace
    @Relationship(deleteRule: .nullify, inverse: \Document.workspace)
    var documents: [Document]
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var isExpanded: Bool  // UI state for sidebar
    
    // Sync status (defaults required for migration)
    var serverVersion: Int = 0
    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var serverId: String?  // Remote ID for cloud sync
    
    init(
        name: String,
        icon: String = "folder",
        color: String = "systemBlue",
        parent: Workspace? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = 0
        self.parent = parent
        self.children = []
        self.documents = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isExpanded = true
        self.serverVersion = 0
        self.isDirty = false
        self.lastSyncedAt = nil
        self.serverId = nil
    }
}

// MARK: - Convenience Extensions

extension Workspace {
    var documentCount: Int {
        documents.filter { !$0.isDeleted }.count
    }
    
    var totalDocumentCount: Int {
        documentCount + children.reduce(0) { $0 + $1.totalDocumentCount }
    }
    
    /// Whether this is a root workspace (top-level)
    var isRoot: Bool {
        parent == nil
    }
    
    /// Whether this is a nested workspace
    var isNested: Bool {
        parent != nil
    }
    
    /// Nesting depth (0 for root, 1 for first-level nested, etc.)
    var nestingDepth: Int {
        var count = 0
        var current = parent
        while current != nil {
            count += 1
            current = current?.parent
        }
        return count
    }
    
    /// Sorted children for display
    var sortedChildren: [Workspace] {
        children.sorted { $0.sortOrder < $1.sortOrder }
    }
    
    /// Whether the workspace needs to be synced to the server
    var needsSync: Bool {
        isDirty || lastSyncedAt == nil
    }
}
