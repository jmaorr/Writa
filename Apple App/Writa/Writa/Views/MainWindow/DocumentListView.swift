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
    @Binding var documentSelection: Document?
    
    // Query only non-deleted documents
    @Query(filter: #Predicate<Document> { $0.isDeleted == false }) 
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
        case .inbox:
            docs = docs.filter { $0.workspace == nil }
        case .favorites:
            docs = docs.filter { $0.isFavorite }
        case .recent:
            docs = docs.filter { $0.lastOpenedAt != nil }
                .sorted { ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast) }
        case .workspace(let id):
            if let workspace = workspaces.first(where: { $0.id == id }) {
                // Workspace documents also need to be filtered for non-deleted
                docs = workspace.documents.filter { !$0.isDeleted }
            }
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
                    DocumentRowView(document: document)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(documentSelection?.id == document.id
                                      ? Color.accentColor.opacity(0.12)
                                      : Color.clear)
                        )
                        .padding(.horizontal, 8)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            documentSelection = document
                        }
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
    
    
    // MARK: - Navigation Title
    
    private var navigationTitle: String {
        switch sidebarSelection {
        case .allDocuments: return "All Documents"
        case .inbox: return "Inbox"
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
        
        Button(role: .destructive) {
            deleteDocument(document)
        } label: {
            Label("Move to Trash", systemImage: "trash")
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
            documentSelection = newDocument
        }
    }
    
    private func deleteDocument(_ document: Document) {
        // Clear selection if deleting the selected document
        if documentSelection?.id == document.id {
            documentSelection = nil
        }
        
        // Move to trash (soft delete)
        documentManager.moveToTrash(document)
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
            documentSelection: .constant(nil)
        )
        .modelContainer(for: Document.self, inMemory: true)
    } detail: {
        Text("Detail")
    }
}
