//
//  Folder.swift
//  Writa
//
//  Folder model for organizing documents hierarchically.
//

import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var icon: String  // SF Symbol name
    var color: String  // Hex color or system color name
    var sortOrder: Int
    
    // Hierarchy
    var parent: Folder?
    @Relationship(deleteRule: .cascade, inverse: \Folder.parent)
    var children: [Folder]
    
    // Documents in this folder
    @Relationship(deleteRule: .nullify, inverse: \Document.folder)
    var documents: [Document]
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var isExpanded: Bool  // UI state for sidebar
    
    init(
        name: String,
        icon: String = "folder",
        color: String = "systemBlue",
        parent: Folder? = nil
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
    }
}

// MARK: - Convenience Extensions

extension Folder {
    var documentCount: Int {
        documents.count
    }
    
    var totalDocumentCount: Int {
        documents.count + children.reduce(0) { $0 + $1.totalDocumentCount }
    }
    
    var isRoot: Bool {
        parent == nil
    }
    
    var depth: Int {
        var count = 0
        var current = parent
        while current != nil {
            count += 1
            current = current?.parent
        }
        return count
    }
}
