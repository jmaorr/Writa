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
            HStack {
                if document.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                
                Text(document.displayTitle)
                    .font(themeManager.tokens.typography.headline.font)
                    .foregroundStyle(themeManager.tokens.colors.textPrimary)
                    .lineLimit(1)
                
                Spacer()
                
                if document.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            
            // Preview text
            Text(document.previewText)
                .font(themeManager.tokens.typography.caption1.font)
                .foregroundStyle(themeManager.tokens.colors.textSecondary)
                .lineLimit(2)
            
            // Metadata row
            HStack(spacing: 8) {
                Text(document.formattedDate)
                    .font(themeManager.tokens.typography.caption1.font)
                    .foregroundStyle(themeManager.tokens.colors.textTertiary)
                
                if document.wordCount > 0 {
                    Text("·")
                        .foregroundStyle(themeManager.tokens.colors.textTertiary)
                    
                    Text("\(document.wordCount) words")
                        .font(themeManager.tokens.typography.caption1.font)
                        .foregroundStyle(themeManager.tokens.colors.textTertiary)
                }
                
                if document.isDirty {
                    Text("·")
                        .foregroundStyle(themeManager.tokens.colors.textTertiary)
                    
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(.orange)
                }
                
                Spacer()
                
                // Tags
                if !document.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(document.tags.prefix(2), id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.quaternary)
                                .clipShape(Capsule())
                        }
                        
                        if document.tags.count > 2 {
                            Text("+\(document.tags.count - 2)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Preview

#Preview {
    let sampleDoc = Document(
        title: "Product Strategy 2025",
        summary: "Q1 objectives and key results for the product team.",
        plainText: "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
    )
    sampleDoc.isFavorite = true
    sampleDoc.tags = ["strategy", "product", "okr"]
    sampleDoc.wordCount = 1234
    
    return List {
        DocumentRowView(document: sampleDoc)
        DocumentRowView(document: Document(title: "Untitled Note"))
    }
    .frame(width: 350, height: 200)
}
