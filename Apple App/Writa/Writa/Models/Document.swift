//
//  Document.swift
//  Writa
//
//  Core document model representing a note/document in the library.
//  Stores ProseMirror JSON as the canonical content format.
//  Prepared for Yjs-based real-time collaboration.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
import CoreTransferable

@Model
final class Document {
    var id: UUID
    var title: String
    var summary: String
    var content: Data?  // ProseMirror JSON stored as Data
    var plainText: String  // For search and preview
    var wordCount: Int
    
    // Organization
    var workspace: Workspace?
    var tags: [String]
    var isFavorite: Bool
    var isPinned: Bool
    
    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
    
    // Trash (Soft Delete)
    @Attribute(.preserveValueOnDeletion) var isDeleted: Bool = false
    var deletedAt: Date?
    
    // Sync status (defaults required for migration)
    var serverVersion: Int = 0
    var isDirty: Bool = false
    var lastSyncedAt: Date?
    var serverId: String?  // Remote ID for cloud sync
    
    // Collaboration (Yjs preparation)
    var yjsState: Data?  // Yjs document state for CRDT sync
    var isShared: Bool = false  // Whether this document is shared with others
    
    init(
        title: String = "Untitled",
        summary: String = "",
        content: Data? = nil,
        plainText: String = "",
        workspace: Workspace? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.content = content
        self.plainText = plainText
        self.wordCount = 0
        self.workspace = workspace
        self.tags = []
        self.isFavorite = false
        self.isPinned = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.lastOpenedAt = nil
        self.isDeleted = false
        self.deletedAt = nil
        self.serverVersion = 0
        self.isDirty = false
        self.lastSyncedAt = nil
        self.serverId = nil
        self.yjsState = nil
        self.isShared = false
    }
}

// MARK: - Convenience Extensions

extension Document {
    /// Display title derived from the first line of content, or "Untitled" if empty
    var displayTitle: String {
        // First try explicit title if set and not default
        if !title.isEmpty && title != "Untitled" {
            return title
        }
        
        // Otherwise use first line of plain text
        let firstLine = plainText
            .components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }?
            .trimmingCharacters(in: .whitespaces)
        
        if let firstLine = firstLine, !firstLine.isEmpty {
            // Limit to reasonable length for title
            return String(firstLine.prefix(100))
        }
        
        return "Untitled"
    }
    
    /// Preview text from content, excluding the first line (which is used as title)
    var previewText: String {
        // If there's an explicit summary, use it
        if !summary.isEmpty {
            return summary
        }
        
        // Get lines after the first non-empty line
        let lines = plainText.components(separatedBy: .newlines)
        var foundFirstLine = false
        var previewLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !foundFirstLine {
                if !trimmed.isEmpty {
                    foundFirstLine = true
                }
                continue
            }
            if !trimmed.isEmpty {
                previewLines.append(trimmed)
            }
            if previewLines.count >= 3 {
                break
            }
        }
        
        let preview = previewLines.joined(separator: " ")
        return preview.isEmpty ? "" : String(preview.prefix(200))
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: updatedAt, relativeTo: Date())
    }
    
    /// Days remaining before permanent deletion (30 day trash retention)
    var daysUntilPermanentDeletion: Int? {
        guard isDeleted, let deletedAt = deletedAt else { return nil }
        let deletionDate = Calendar.current.date(byAdding: .day, value: 30, to: deletedAt) ?? Date()
        let days = Calendar.current.dateComponents([.day], from: Date(), to: deletionDate).day ?? 0
        return max(0, days)
    }
    
    /// Whether this document should be permanently deleted (past 30 days)
    var shouldPermanentlyDelete: Bool {
        guard isDeleted, let deletedAt = deletedAt else { return false }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return deletedAt < thirtyDaysAgo
    }
    
    /// Formatted deletion date for display
    var formattedDeletionDate: String? {
        guard let deletedAt = deletedAt else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: deletedAt, relativeTo: Date())
    }
    
    /// Whether the document needs to be synced to the server
    var needsSync: Bool {
        isDirty || lastSyncedAt == nil
    }
}

// MARK: - Drag and Drop Support

/// Wrapper for dragging documents (SwiftData models can't directly conform to Transferable)
struct DocumentDragItem: Codable, Transferable {
    let documentID: UUID
    
    static var transferRepresentation: some TransferRepresentation {
        // Use built-in JSON type instead of custom UTType to avoid Info.plist registration
        CodableRepresentation(contentType: .json)
    }
}
