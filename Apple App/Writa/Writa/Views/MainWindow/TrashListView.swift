//
//  TrashListView.swift
//  Writa
//
//  Shows documents in the trash with restore and permanent delete options.
//  Documents are automatically deleted after 30 days.
//

import SwiftUI
import SwiftData

struct TrashListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeManager) private var themeManager
    @Environment(\.documentManager) private var documentManager
    
    @Query(filter: #Predicate<Document> { $0.isDeleted == true },
           sort: \Document.deletedAt, order: .reverse) 
    private var trashedDocuments: [Document]
    
    @Binding var documentSelection: Document?
    @State private var showEmptyTrashConfirmation = false
    
    var body: some View {
        Group {
            if trashedDocuments.isEmpty {
                emptyTrashView
            } else {
                trashList
            }
        }
        .navigationTitle("Trash")
        .toolbar {
            ToolbarItemGroup {
                if !trashedDocuments.isEmpty {
                    Button(action: { showEmptyTrashConfirmation = true }) {
                        Label("Empty Trash", systemImage: "trash.slash")
                    }
                }
            }
        }
        .confirmationDialog(
            "Empty Trash",
            isPresented: $showEmptyTrashConfirmation,
            titleVisibility: .visible
        ) {
            Button("Empty Trash", role: .destructive) {
                emptyTrash()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to permanently delete \(trashedDocuments.count) document\(trashedDocuments.count == 1 ? "" : "s")? This cannot be undone.")
        }
    }
    
    // MARK: - Empty State
    
    private var emptyTrashView: some View {
        ContentUnavailableView {
            Label("Trash is Empty", systemImage: "trash")
        } description: {
            Text("Deleted documents will appear here for 30 days before being permanently removed.")
        }
    }
    
    // MARK: - Trash List
    
    private var trashList: some View {
        List(trashedDocuments, selection: $documentSelection) { document in
            TrashRowView(document: document)
                .tag(document)
                .listRowBackground(rowBackground(for: document))
                .contextMenu {
                    trashContextMenu(for: document)
                }
        }
    }
    
    private func rowBackground(for document: Document) -> Color {
        if documentSelection?.id == document.id {
            return themeManager.tokens.colors.surfaceSelected.opacity(0.3)
        }
        return Color.clear
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func trashContextMenu(for document: Document) -> some View {
        Button {
            restoreDocument(document)
        } label: {
            Label("Restore", systemImage: "arrow.uturn.backward")
        }
        
        Divider()
        
        Button(role: .destructive) {
            permanentlyDeleteDocument(document)
        } label: {
            Label("Delete Permanently", systemImage: "trash.slash")
        }
    }
    
    // MARK: - Actions
    
    private func restoreDocument(_ document: Document) {
        // Clear selection if restoring the selected document
        if documentSelection?.id == document.id {
            documentSelection = nil
        }
        
        documentManager.restore(document)
    }
    
    private func permanentlyDeleteDocument(_ document: Document) {
        // Clear selection if deleting the selected document
        if documentSelection?.id == document.id {
            documentSelection = nil
        }
        
        documentManager.permanentlyDelete(document)
    }
    
    private func emptyTrash() {
        documentSelection = nil
        documentManager.emptyTrash()
    }
}

// MARK: - Trash Row View

struct TrashRowView: View {
    let document: Document
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title
            Text(document.displayTitle)
                .font(themeManager.tokens.typography.headline.font)
                .foregroundStyle(themeManager.tokens.colors.textPrimary)
                .lineLimit(1)
            
            // Preview
            Text(document.previewText)
                .font(.system(size: 12))
                .foregroundStyle(themeManager.tokens.colors.textSecondary)
                .lineLimit(2)
            
            // Deletion info
            HStack(spacing: 8) {
                if let deletedDate = document.formattedDeletionDate {
                    Text("Deleted \(deletedDate)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                if let daysRemaining = document.daysUntilPermanentDeletion {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(daysRemaining == 0 ? "Expires today" : "\(daysRemaining) day\(daysRemaining == 1 ? "" : "s") left")
                        .font(.caption2)
                        .foregroundStyle(daysRemaining <= 7 ? .orange : .secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Trash Detail View

struct TrashDetailView: View {
    let document: Document
    @Environment(\.themeManager) private var themeManager
    @Environment(\.documentManager) private var documentManager
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "trash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            // Title
            Text(document.displayTitle)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Info
            VStack(spacing: 8) {
                if let deletedDate = document.formattedDeletionDate {
                    Text("Deleted \(deletedDate)")
                        .foregroundStyle(.secondary)
                }
                
                if let daysRemaining = document.daysUntilPermanentDeletion {
                    Text("Will be permanently deleted in \(daysRemaining) day\(daysRemaining == 1 ? "" : "s")")
                        .foregroundStyle(.orange)
                }
            }
            .font(.subheadline)
            
            // Actions
            HStack(spacing: 16) {
                Button {
                    documentManager.restore(document)
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward")
                }
                .buttonStyle(.borderedProminent)
                
                Button(role: .destructive) {
                    documentManager.permanentlyDelete(document)
                } label: {
                    Label("Delete Permanently", systemImage: "trash.slash")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.tokens.colors.backgroundPrimary)
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        Text("Sidebar")
    } content: {
        TrashListView(documentSelection: .constant(nil))
            .modelContainer(for: Document.self, inMemory: true)
    } detail: {
        Text("Detail")
    }
}
