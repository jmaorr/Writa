//
//  MultiSelectDetailView.swift
//  Writa
//
//  Shows bulk actions when multiple documents are selected.
//

import SwiftUI
import SwiftData

struct MultiSelectDetailView: View {
    @Environment(\.documentManager) private var documentManager
    
    let selectedIDs: Set<Document.ID>
    let documents: [Document]
    let onClearSelection: () -> Void
    
    @Query private var workspaces: [Workspace]
    @State private var showMoveSheet = false
    @State private var showDeleteConfirmation = false
    
    private var selectedDocuments: [Document] {
        documents.filter { selectedIDs.contains($0.id) }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Selection count
            Image(systemName: "doc.on.doc")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("\(selectedIDs.count) Documents Selected")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Action buttons
            VStack(spacing: 12) {
                // Move to workspace
                Button {
                    showMoveSheet = true
                } label: {
                    Label("Move to Workspace...", systemImage: "folder")
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.bordered)
                
                // Move to trash
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Move to Trash", systemImage: "trash")
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.bordered)
                
                // Clear selection
                Button {
                    onClearSelection()
                } label: {
                    Text("Clear Selection")
                        .frame(maxWidth: 200)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showMoveSheet) {
            moveToWorkspaceSheet
        }
        .confirmationDialog(
            "Move to Trash",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Move to Trash", role: .destructive) {
                moveToTrash()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to move \(selectedIDs.count) document\(selectedIDs.count == 1 ? "" : "s") to trash?")
        }
    }
    
    // MARK: - Move to Workspace Sheet
    
    /// Flattened list of workspaces with depth for indentation
    private var flattenedWorkspaces: [(workspace: Workspace, depth: Int)] {
        var result: [(Workspace, Int)] = []
        func flatten(_ ws: Workspace, depth: Int) {
            result.append((ws, depth))
            for child in ws.sortedChildren {
                flatten(child, depth: depth + 1)
            }
        }
        for ws in workspaces.filter({ $0.parent == nil }) {
            flatten(ws, depth: 0)
        }
        return result
    }
    
    private var moveToWorkspaceSheet: some View {
        NavigationStack {
            List {
                // No workspace option
                Button {
                    moveToWorkspace(nil)
                    showMoveSheet = false
                } label: {
                    Label("No Workspace", systemImage: "tray")
                }
                
                // Workspace options (flattened with indentation)
                ForEach(flattenedWorkspaces, id: \.workspace.id) { item in
                    Button {
                        moveToWorkspace(item.workspace)
                        showMoveSheet = false
                    } label: {
                        HStack {
                            if item.depth > 0 {
                                Spacer().frame(width: CGFloat(item.depth) * 16)
                            }
                            Label(item.workspace.name, systemImage: item.workspace.icon)
                        }
                    }
                }
            }
            .navigationTitle("Move to Workspace")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showMoveSheet = false
                    }
                }
            }
        }
        .frame(minWidth: 300, minHeight: 400)
    }
    
    // MARK: - Actions
    
    private func moveToWorkspace(_ workspace: Workspace?) {
        for document in selectedDocuments {
            document.workspace = workspace
            document.isDirty = true
        }
        onClearSelection()
    }
    
    private func moveToTrash() {
        for document in selectedDocuments {
            documentManager.moveToTrash(document)
        }
        onClearSelection()
    }
}

#Preview {
    MultiSelectDetailView(
        selectedIDs: [UUID(), UUID(), UUID()],
        documents: [],
        onClearSelection: {}
    )
}
