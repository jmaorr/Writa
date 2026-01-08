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
    let sidebarSelection: SidebarItemType?
    @Binding var documentSelection: Document?
    
    @Query private var allDocuments: [Document]
    @Query private var folders: [Folder]
    
    @State private var searchText = ""
    @State private var sortOrder: DocumentSortOrder = .dateModified
    
    // MARK: - Computed Properties
    
    private var documents: [Document] {
        let filtered = filteredDocuments
        return sortedDocuments(filtered)
    }
    
    private var filteredDocuments: [Document] {
        var docs = allDocuments
        
        // Filter by sidebar selection
        switch sidebarSelection {
        case .allDocuments:
            break // Show all
        case .inbox:
            docs = docs.filter { $0.folder == nil }
        case .favorites:
            docs = docs.filter { $0.isFavorite }
        case .recent:
            docs = docs.filter { $0.lastOpenedAt != nil }
                .sorted { ($0.lastOpenedAt ?? .distantPast) > ($1.lastOpenedAt ?? .distantPast) }
        case .folder(let id):
            if let folder = folders.first(where: { $0.id == id }) {
                docs = folder.documents
            }
        case .tag(let name):
            docs = docs.filter { $0.tags.contains(name) }
        case .smartFilter(let type):
            docs = applySmartFilter(type, to: docs)
        case .openCommunity, .none:
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
                List(documents, selection: $documentSelection) { document in
                    DocumentRowView(document: document)
                        .tag(document)
                        .contextMenu {
                            documentContextMenu(for: document)
                        }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search documents")
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItemGroup {
                sortMenu
                
                Button(action: createNewDocument) {
                    Label("New Document", systemImage: "square.and.pencil")
                }
            }
        }
    }
    
    // MARK: - Navigation Title
    
    private var navigationTitle: String {
        switch sidebarSelection {
        case .allDocuments: return "All Documents"
        case .inbox: return "Inbox"
        case .favorites: return "Favorites"
        case .recent: return "Recent"
        case .folder(let id):
            return folders.first { $0.id == id }?.name ?? "Folder"
        case .tag(let name): return "#\(name)"
        case .smartFilter(let type): return type.rawValue
        case .openCommunity, .none: return "Documents"
        }
    }
    
    // MARK: - Sort Menu
    
    private var sortMenu: some View {
        Menu {
            Picker("Sort By", selection: $sortOrder) {
                ForEach(DocumentSortOrder.allCases) { order in
                    Text(order.rawValue).tag(order)
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func documentContextMenu(for document: Document) -> some View {
        Button {
            document.isFavorite.toggle()
        } label: {
            Label(
                document.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                systemImage: document.isFavorite ? "star.slash" : "star"
            )
        }
        
        Button {
            document.isPinned.toggle()
        } label: {
            Label(
                document.isPinned ? "Unpin" : "Pin",
                systemImage: document.isPinned ? "pin.slash" : "pin"
            )
        }
        
        Divider()
        
        Button(role: .destructive) {
            modelContext.delete(document)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    // MARK: - Actions
    
    private func createNewDocument() {
        let document = Document(title: "Untitled")
        
        // Set folder if a folder is selected
        if case .folder(let id) = sidebarSelection,
           let folder = folders.first(where: { $0.id == id }) {
            document.folder = folder
        }
        
        modelContext.insert(document)
        documentSelection = document
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
