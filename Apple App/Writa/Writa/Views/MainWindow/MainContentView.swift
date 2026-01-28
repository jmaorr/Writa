//
//  MainContentView.swift
//  Writa
//
//  Main three-column layout for the personal library window.
//

import SwiftUI
import SwiftData
import WebKit

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeManager) private var themeManager
    @Environment(\.documentManager) private var documentManager
    
    @State private var sidebarSelection: SidebarItemType? = .allDocuments
    @State private var selectedDocumentIDs: Set<Document.ID> = []
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var shouldCreateWorkspace = false
    
    @Query(filter: #Predicate<Document> { $0.isTrashed == false })
    private var allDocuments: [Document]
    @Query private var workspaces: [Workspace]
    
    /// Returns the single selected document if exactly one is selected
    private var singleSelectedDocument: Document? {
        guard selectedDocumentIDs.count == 1,
              let id = selectedDocumentIDs.first else { return nil }
        return allDocuments.first { $0.id == id }
    }
    
    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - Sidebar (Column 1)
            SidebarView(
                selection: $sidebarSelection,
                shouldCreateWorkspace: $shouldCreateWorkspace
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } content: {
            // MARK: - Content (Column 2)
            Group {
                switch sidebarSelection {
                case .trash:
                    TrashListView(selectedDocumentIDs: $selectedDocumentIDs)
                case .tasks:
                    TasksView(selectedDocumentIDs: $selectedDocumentIDs)
                default:
                    DocumentListView(
                        sidebarSelection: sidebarSelection,
                        selectedDocumentIDs: $selectedDocumentIDs
                    )
                }
            }
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // MARK: - Document Detail (Column 3)
            if selectedDocumentIDs.count > 1 {
                // Multi-selection view
                MultiSelectDetailView(
                    selectedIDs: selectedDocumentIDs,
                    documents: allDocuments,
                    onClearSelection: { selectedDocumentIDs.removeAll() }
                )
            } else if let document = singleSelectedDocument {
                if document.isTrashed {
                    TrashDetailView(document: document)
                } else {
                    DocumentDetailView(document: document)
                }
            } else {
                EmptyDetailView()
            }
            }
            .navigationSplitViewStyle(.balanced)
            .onChange(of: sidebarSelection) { oldValue, newValue in
                // Clear document selection when switching sections
                if oldValue != newValue {
                    selectedDocumentIDs.removeAll()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .createNewDocument)) { _ in
                createNewDocument()
            }
            .onReceive(NotificationCenter.default.publisher(for: .createNewWorkspace)) { _ in
                shouldCreateWorkspace = true
            }
            
        }
    }
    
    private func createNewDocument() {
        // Get workspace if one is selected
        var workspace: Workspace? = nil
        if case .workspace(let id) = sidebarSelection {
            workspace = workspaces.first(where: { $0.id == id })
        }
        
        if let newDocument = documentManager.create(title: "Untitled", in: workspace) {
            selectedDocumentIDs = [newDocument.id]
        }
    }
}

// MARK: - Empty Detail View

struct EmptyDetailView: View {
    @Environment(\.themeManager) private var themeManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(.quaternary)
            
            Text("Select a Document")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("Choose a document from the list to view or edit it.")
                .font(.body)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.tokens.colors.backgroundPrimary)
    }
}

// MARK: - Preview

#Preview {
    MainContentView()
        .modelContainer(for: [Document.self, Workspace.self], inMemory: true)
        .environment(\.themeManager, ThemeManager())
        .frame(width: 1200, height: 800)
}
