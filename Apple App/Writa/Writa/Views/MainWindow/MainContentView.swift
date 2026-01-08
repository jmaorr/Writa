//
//  MainContentView.swift
//  Writa
//
//  Main three-column layout for the personal library window.
//

import SwiftUI
import SwiftData

struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.themeManager) private var themeManager
    
    @State private var sidebarSelection: SidebarItemType? = .allDocuments
    @State private var documentSelection: Document?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // MARK: - Sidebar (Column 1)
            SidebarView(selection: $sidebarSelection)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 300)
        } content: {
            // MARK: - Document List (Column 2)
            DocumentListView(
                sidebarSelection: sidebarSelection,
                documentSelection: $documentSelection
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // MARK: - Document Detail (Column 3)
            if let document = documentSelection {
                DocumentDetailView(document: document)
            } else {
                EmptyDetailView()
            }
        }
        .navigationSplitViewStyle(.balanced)
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
        .modelContainer(for: [Document.self, Folder.self], inMemory: true)
        .environment(\.themeManager, ThemeManager())
        .frame(width: 1200, height: 800)
}
