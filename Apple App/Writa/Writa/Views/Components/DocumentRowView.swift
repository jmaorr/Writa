//
//  DocumentRowView.swift
//  Writa
//
//  Document row for the document list.
//

import SwiftUI

struct DocumentRowView: View {
    let document: Document
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title row
            HStack(spacing: 6) {
                if document.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                
                Text(document.displayTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                if document.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            
            // Preview text (only show if there's content)
            if !document.previewText.isEmpty {
                Text(document.previewText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            // Metadata row
            HStack(spacing: 6) {
                Text(document.formattedDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                // Only show dirty indicator for non-trashed documents
                // (Trashed documents are marked dirty for sync, but shouldn't show the dot in trash)
                if document.isDirty && !document.isTrashed {
                    Circle()
                        .fill(.orange)
                        .frame(width: 5, height: 5)
                }
                
                Spacer()
                
                // Tags (compact)
                if !document.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(document.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        if document.tags.count > 2 {
                            Text("+\(document.tags.count - 2)")
                                .font(.caption2)
                                .foregroundStyle(.quaternary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Document Row Button (for List without native selection)

struct DocumentRowButton: View {
    let document: Document
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        DocumentRowView(document: document)
            .contentShape(Rectangle())
            .draggable(SidebarDragItem.document(document.id))
            .onTapGesture {
                onSelect()
            }
    }
}

// MARK: - Preview

#Preview {
    let sampleDoc = Document(
        title: "",
        summary: "",
        plainText: "Meeting Notes for Q1 Planning\n\nDiscussed roadmap priorities and team allocation for the upcoming quarter."
    )
    sampleDoc.isFavorite = true
    sampleDoc.tags = ["meetings", "planning"]
    
    let emptyDoc = Document(title: "", plainText: "")
    
    return List {
        DocumentRowView(document: sampleDoc)
        DocumentRowView(document: emptyDoc)
    }
    .frame(width: 350, height: 200)
}
