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
    
    @Query(filter: #Predicate<Document> { $0.isTrashed == true },
           sort: \Document.trashedAt, order: .reverse) 
    private var trashedDocuments: [Document]
    
    @Binding var selectedDocumentIDs: Set<Document.ID>
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
        List(trashedDocuments, selection: $selectedDocumentIDs) { document in
            VStack(alignment: .leading, spacing: 4) {
                // Use same DocumentRowView as document list
                DocumentRowView(document: document)
                
                // Add trash-specific info below
                HStack(spacing: 8) {
                    if let deletedDate = document.formattedTrashedDate {
                        Text("Deleted \(deletedDate)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let daysRemaining = document.daysUntilPermanentDeletion {
                        Text("•")
                            .foregroundStyle(.secondary)
                            .font(.caption2)
                        Text(daysRemaining == 0 ? "Expires today" : "\(daysRemaining) day\(daysRemaining == 1 ? "" : "s") left")
                            .font(.caption2)
                            .foregroundStyle(daysRemaining <= 7 ? .orange : .secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .tag(document)
            .listRowBackground(rowBackground(for: document))
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
            .contextMenu {
                trashContextMenu(for: document)
            }
        }
        .listStyle(.plain)
    }
    
    private func rowBackground(for document: Document) -> Color {
        if selectedDocumentIDs.contains(document.id) {
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
        selectedDocumentIDs.remove(document.id)
        documentManager.restore(document)
    }
    
    private func permanentlyDeleteDocument(_ document: Document) {
        // Clear selection if deleting the selected document
        selectedDocumentIDs.remove(document.id)
        documentManager.permanentlyDelete(document)
    }
    
    private func emptyTrash() {
        selectedDocumentIDs.removeAll()
        documentManager.emptyTrash()
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
                if let deletedDate = document.formattedTrashedDate {
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
        TrashListView(selectedDocumentIDs: .constant([]))
            .modelContainer(for: Document.self, inMemory: true)
    } detail: {
        Text("Detail")
    }
}
