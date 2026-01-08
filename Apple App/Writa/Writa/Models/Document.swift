//
//  Document.swift
//  Writa
//
//  Core document model representing a note/document in the library.
//  Stores ProseMirror JSON as the canonical content format.
//

import Foundation
import SwiftData

@Model
final class Document {
    var id: UUID
    var title: String
    var summary: String
    var content: Data?  // ProseMirror JSON stored as Data
    var plainText: String  // For search and preview
    var wordCount: Int
    
    // Organization
    var folder: Folder?
    var tags: [String]
    var isFavorite: Bool
    var isPinned: Bool
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
    
    // Sync status
    var serverVersion: Int
    var isDirty: Bool
    
    init(
        title: String = "Untitled",
        summary: String = "",
        content: Data? = nil,
        plainText: String = "",
        folder: Folder? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.content = content
        self.plainText = plainText
        self.wordCount = 0
        self.folder = folder
        self.tags = []
        self.isFavorite = false
        self.isPinned = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastOpenedAt = nil
        self.serverVersion = 0
        self.isDirty = false
    }
}

// MARK: - Convenience Extensions

extension Document {
    var displayTitle: String {
        title.isEmpty ? "Untitled" : title
    }
    
    var previewText: String {
        if !summary.isEmpty {
            return summary
        }
        let preview = plainText.prefix(150)
        return preview.isEmpty ? "No content" : String(preview)
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
}
