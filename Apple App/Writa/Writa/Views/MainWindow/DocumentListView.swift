//
//  DocumentListView.swift
//  Writa
//
//  Middle column showing documents based on sidebar selection.
//

import SwiftUI
import SwiftData

struct DocumentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeManager) private var themeManager
    @Environment(\.documentManager) private var documentManager
    let sidebarSelection: SidebarItemType?
    @Binding var selectedDocumentIDs: Set<Document.ID>
    
    // Query only non-deleted documents
    @Query(filter: #Predicate<Document> { $0.isTrashed == false }) 
    private var allDocuments: [Document]
    @Query private var workspaces: [Workspace]
    
    @State private var searchText = ""
    @State private var sortOrder: DocumentSortOrder = .dateModified
    
    // MARK: - Computed Properties
    
    private var documents: [Document] {
        let filtered = filteredDocuments
        return sortedDocuments(filtered)
    }
    
    private var filteredDocuments: [Document] {
        // allDocuments is already filtered for non-deleted via @Query predicate
        var docs = Array(allDocuments)
        
        // Filter by sidebar selection
        switch sidebarSelection {
        case .allDocuments:
            break // Show all
        case .tasks:
            // Tasks are handled by TasksView, not here
            docs = []
        case .favorites:
            docs = docs.filter { $0.isFavorite }
        case .recent:
            docs = docs.filter { $0.lastOpenedAt != nil }
                .sorted { ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast) }
        case .workspace(let id):
            // Filter from allDocuments (which has fresh @Query data) instead of workspace.documents relationship
            // This ensures immediate refresh when isTrashed changes
            docs = docs.filter { $0.workspace?.id == id }
        case .tag(let name):
            docs = docs.filter { $0.tags.contains(name) }
        case .smartFilter(let type):
            docs = applySmartFilter(type, to: docs)
        case .openCommunity, .trash, .none:
            break
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            docs = docs.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.plainText.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return docs
    }
    
    private func sortedDocuments(_ docs: [Document]) -> [Document] {
        switch sortOrder {
        case .dateModified:
            return docs.sorted { $0.updatedAt > $1.updatedAt }
        case .dateCreated:
            return docs.sorted { $0.createdAt > $1.createdAt }
        case .title:
            return docs.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        }
    }
    
    private func applySmartFilter(_ type: SmartFilterType, to docs: [Document]) -> [Document] {
        switch type {
        case .recentlyEdited:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return docs.filter { $0.updatedAt > oneWeekAgo }
        case .recentlyCreated:
            let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            return docs.filter { $0.createdAt > oneWeekAgo }
        case .longDocuments:
            return docs.filter { $0.wordCount > 1000 }
        case .hasImages:
            // Placeholder - would check content for images
            return docs
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if documents.isEmpty {
                EmptyDocumentListView(sidebarSelection: sidebarSelection)
            } else {
                documentList
            }
        }
        .searchable(text: $searchText, prompt: "Search documents")
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItemGroup {
                sortMenu
            }
            ToolbarItemGroup {
                Button {
                    createNewDocument()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Document")
            }
        }
    }
    
    // MARK: - Document List
    
    private var documentList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(documents) { document in
                    let isSelected = selectedDocumentIDs.contains(document.id)
                    
                    DocumentRowView(document: document)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(isSelected
                                      ? Color.accentColor.opacity(0.12)
                                      : Color.clear)
                        )
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                        .simultaneousGesture(
                            TapGesture().onEnded {
                                handleDocumentTap(document)
                            }
                        )
                        .draggable(SidebarDragItem.document(document.id))
                        .contextMenu {
                            documentContextMenu(for: document)
                        }
                }
            }
            .padding(.vertical, 4)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func handleDocumentTap(_ document: Document) {
        let modifiers = NSEvent.modifierFlags
        
        if modifiers.contains(.command) {
            // Cmd-click: toggle selection
            if selectedDocumentIDs.contains(document.id) {
                selectedDocumentIDs.remove(document.id)
            } else {
                selectedDocumentIDs.insert(document.id)
            }
        } else if modifiers.contains(.shift) && !selectedDocumentIDs.isEmpty {
            // Shift-click: select range from last selected to this document
            handleShiftClick(document: document)
        } else {
            // Regular click: select only this document
            selectedDocumentIDs = [document.id]
        }
    }
    
    private func handleShiftClick(document: Document) {
        // Find the anchor (first selected item in current order)
        guard let anchorID = documents.first(where: { selectedDocumentIDs.contains($0.id) })?.id,
              let anchorIndex = documents.firstIndex(where: { $0.id == anchorID }),
              let currentIndex = documents.firstIndex(where: { $0.id == document.id }) else {
            selectedDocumentIDs = [document.id]
            return
        }
        
        let range = min(anchorIndex, currentIndex)...max(anchorIndex, currentIndex)
        for i in range {
            selectedDocumentIDs.insert(documents[i].id)
        }
    }
    
    
    // MARK: - Navigation Title
    
    private var navigationTitle: String {
        switch sidebarSelection {
        case .allDocuments: return "All Documents"
        case .tasks: return "Tasks"
        case .favorites: return "Favorites"
        case .recent: return "Recent"
        case .trash: return "Trash"
        case .workspace(let id):
            return workspaces.first { $0.id == id }?.name ?? "Workspace"
        case .tag(let name): return "#\(name)"
        case .smartFilter(let type): return type.rawValue
        case .openCommunity, .none: return "Documents"
        }
    }
    
    // MARK: - Sort Menu
    
    private var sortMenu: some View {
        Menu {
            ForEach(DocumentSortOrder.allCases) { order in
                Button {
                    sortOrder = order
                } label: {
                    HStack {
                        Text(order.rawValue)
                        if sortOrder == order {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
        .menuIndicator(.hidden)
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func documentContextMenu(for document: Document) -> some View {
        // Check if this document is part of a multi-selection
        let isMultiSelect = selectedDocumentIDs.count > 1 && selectedDocumentIDs.contains(document.id)
        
        if !isMultiSelect {
            // Single document actions
            Button {
                document.isFavorite.toggle()
                documentManager.save(document)
            } label: {
                Label(
                    document.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: document.isFavorite ? "star.slash" : "star"
                )
            }
            
            Button {
                document.isPinned.toggle()
                documentManager.save(document)
            } label: {
                Label(
                    document.isPinned ? "Unpin" : "Pin",
                    systemImage: document.isPinned ? "pin.slash" : "pin"
                )
            }
            
            Divider()
        }
        
        Button(role: .destructive) {
            if isMultiSelect {
                deleteSelectedDocuments()
            } else {
                deleteDocument(document)
            }
        } label: {
            if isMultiSelect {
                Label("Move \(selectedDocumentIDs.count) to Trash", systemImage: "trash")
            } else {
                Label("Move to Trash", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Actions
    
    private func createNewDocument() {
        // Get workspace if one is selected
        var workspace: Workspace? = nil
        if case .workspace(let id) = sidebarSelection {
            workspace = workspaces.first(where: { $0.id == id })
        }
        
        // Create using document manager
        if let newDocument = documentManager.create(title: "Untitled", in: workspace) {
            selectedDocumentIDs = [newDocument.id]
        }
    }
    
    private func deleteDocument(_ document: Document) {
        // Clear selection if deleting the selected document
        selectedDocumentIDs.remove(document.id)
        
        // Move to trash (soft delete)
        documentManager.moveToTrash(document)
    }
    
    private func deleteSelectedDocuments() {
        // Get all selected documents
        let docsToDelete = allDocuments.filter { selectedDocumentIDs.contains($0.id) }
        
        // Clear selection first
        selectedDocumentIDs.removeAll()
        
        // Move all to trash
        for document in docsToDelete {
            documentManager.moveToTrash(document)
        }
    }
}

// MARK: - Sort Order

enum DocumentSortOrder: String, CaseIterable, Identifiable {
    case dateModified = "Date Modified"
    case dateCreated = "Date Created"
    case title = "Title"
    
    var id: String { rawValue }
}

// MARK: - Empty State

struct EmptyDocumentListView: View {
    let sidebarSelection: SidebarItemType?
    
    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(description)
        } actions: {
            Button("Create Document") {
                // Action handled by toolbar
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var title: String {
        switch sidebarSelection {
        case .favorites:
            return "No Favorites"
        case .recent:
            return "No Recent Documents"
        default:
            return "No Documents"
        }
    }
    
    private var icon: String {
        switch sidebarSelection {
        case .favorites:
            return "star"
        case .recent:
            return "clock"
        default:
            return "doc.text"
        }
    }
    
    private var description: String {
        switch sidebarSelection {
        case .favorites:
            return "Star documents to add them to your favorites."
        case .recent:
            return "Documents you've recently opened will appear here."
        default:
            return "Create a new document to get started."
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        Text("Sidebar")
    } content: {
        DocumentListView(
            sidebarSelection: .allDocuments,
            selectedDocumentIDs: .constant([])
        )
        .modelContainer(for: Document.self, inMemory: true)
    } detail: {
        Text("Detail")
    }
}
