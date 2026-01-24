//
//  SidebarView.swift
//  Writa
//
//  Main sidebar navigation for the personal library.
//  Displays library items, workspaces, smart filters, and community access.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// MARK: - Unified Drag Item

/// A single transferable type for all sidebar drag operations
enum SidebarDragItem: Codable, Transferable, Equatable {
    case document(UUID)
    case workspace(UUID)
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

// MARK: - Main View

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Environment(\.documentManager) private var documentManager
    
    @Query(filter: #Predicate<Workspace> { $0.parent == nil }, sort: \Workspace.sortOrder)
    private var rootWorkspaces: [Workspace]
    
    @Query(filter: #Predicate<Document> { $0.isDeleted == true })
    private var trashedDocuments: [Document]
    
    @Query(filter: #Predicate<Document> { $0.isDeleted == false })
    private var activeDocuments: [Document]
    
    @Binding var selection: SidebarItemType?
    @Binding var shouldCreateWorkspace: Bool
    
    // Track newly created workspace for auto-rename
    @State private var newlyCreatedWorkspaceID: UUID?
    
    // MARK: - Computed Items
    
    private var totalIncompleteTaskCount: Int {
        activeDocuments.reduce(0) { $0 + $1.incompleteTaskCount }
    }
    
    private var tasksItem: SidebarItem {
        SidebarItem(
            type: .tasks,
            title: "Tasks",
            icon: "checkmark.circle",
            iconColor: .blue,
            badge: totalIncompleteTaskCount > 0 ? totalIncompleteTaskCount : nil
        )
    }
    
    private var trashItem: SidebarItem {
        .trash(count: trashedDocuments.count)
    }
    
    var body: some View {
        List(selection: $selection) {
            // MARK: - Library Section (Static)
            Section("Library") {
                SidebarItemRow(item: .allDocuments)
                    .tag(SidebarItemType.allDocuments)
                
                SidebarItemRow(item: tasksItem)
                    .tag(SidebarItemType.tasks)
                
                SidebarItemRow(item: .favorites)
                    .tag(SidebarItemType.favorites)
                
                SidebarItemRow(item: .recent)
                    .tag(SidebarItemType.recent)
                
                SidebarItemRow(item: trashItem)
                    .tag(SidebarItemType.trash)
            }
            
            // MARK: - Workspaces Section
            Section("Workspaces") {
                if rootWorkspaces.isEmpty {
                    Button {
                        createNewWorkspace()
                    } label: {
                        Label {
                            Text("New Workspace...")
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(rootWorkspaces) { workspace in
                        WorkspaceRow(
                            workspace: workspace,
                            selection: $selection,
                            newlyCreatedWorkspaceID: $newlyCreatedWorkspaceID
                        )
                    }
                    .onMove { source, destination in
                        moveRootWorkspaces(from: source, to: destination)
                    }
                }
            }
            
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            SidebarFooter()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    createNewWorkspace()
                } label: {
                    Image(systemName: "plus")
                }
                .help("New Workspace")
            }
        }
        .onChange(of: shouldCreateWorkspace) { _, newValue in
            if newValue {
                createNewWorkspace()
                shouldCreateWorkspace = false
            }
        }
    }
    
    // MARK: - Actions
    
    private func createNewWorkspace(parent: Workspace? = nil) {
        let workspace = Workspace(name: "", parent: parent)
        
        if let parent = parent {
            workspace.sortOrder = parent.children.count
            parent.isExpanded = true
        } else {
            workspace.sortOrder = rootWorkspaces.count
        }
        
        modelContext.insert(workspace)
        newlyCreatedWorkspaceID = workspace.id
    }
    
    private func moveRootWorkspaces(from source: IndexSet, to destination: Int) {
        // Create a mutable copy of the workspaces array
        var workspaces = Array(rootWorkspaces)
        workspaces.move(fromOffsets: source, toOffset: destination)
        
        // Update sortOrder for all workspaces
        for (index, workspace) in workspaces.enumerated() {
            workspace.sortOrder = index
            workspace.updatedAt = Date()
        }
        
        // Save changes
        try? modelContext.save()
        
        // Trigger auto-sync
        NotificationCenter.default.post(name: Notification.Name("WorkspaceDidChange"), object: nil)
    }
    
}

// MARK: - Workspace Row (Recursive)

struct WorkspaceRow: View {
    @Bindable var workspace: Workspace
    @Binding var selection: SidebarItemType?
    @Binding var newlyCreatedWorkspaceID: UUID?
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allDocuments: [Document]
    @Query private var allWorkspaces: [Workspace]
    
    @State private var isRenaming = false
    @State private var newName = ""
    @State private var isDropTargeted = false
    @State private var isHovering = false
    @FocusState private var isTextFieldFocused: Bool
    
    private var isNewlyCreated: Bool {
        workspace.id == newlyCreatedWorkspaceID
    }
    
    var body: some View {
        if workspace.children.isEmpty {
            // Leaf workspace
            workspaceContent
                .tag(SidebarItemType.workspace(workspace.id))
                .listRowBackground(dropHighlightBackground)
                .draggable(SidebarDragItem.workspace(workspace.id))
                .dropDestination(for: SidebarDragItem.self) { items, _ in
                    handleDrop(items)
                } isTargeted: { targeted in
                    isDropTargeted = targeted
                }
        } else {
            // Workspace with children
            DisclosureGroup(isExpanded: $workspace.isExpanded) {
                ForEach(workspace.sortedChildren) { child in
                    WorkspaceRow(
                        workspace: child,
                        selection: $selection,
                        newlyCreatedWorkspaceID: $newlyCreatedWorkspaceID
                    )
                }
                .onMove { source, destination in
                    moveChildWorkspaces(from: source, to: destination)
                }
            } label: {
                workspaceContent
                    .tag(SidebarItemType.workspace(workspace.id))
                    .draggable(SidebarDragItem.workspace(workspace.id))
                    .dropDestination(for: SidebarDragItem.self) { items, _ in
                        handleDrop(items)
                    } isTargeted: { targeted in
                        isDropTargeted = targeted
                    }
            }
            .listRowBackground(dropHighlightBackground)
        }
    }
    
    @ViewBuilder
    private var workspaceContent: some View {
        HStack {
            if isRenaming {
                TextField("Workspace name", text: $newName)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onSubmit { commitRename() }
                    .onExitCommand { cancelRename() }
            } else {
                Label {
                    Text(workspace.name.isEmpty ? "Untitled" : workspace.name)
                } icon: {
                    Image(systemName: workspace.icon)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isHovering {
                    workspaceMenu
                } else if workspace.totalDocumentCount > 0 {
                    Text("\(workspace.totalDocumentCount)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            workspaceContextMenuItems
        }
        .onAppear {
            if isNewlyCreated {
                startRenaming()
            }
        }
        .onChange(of: newlyCreatedWorkspaceID) { _, newValue in
            if newValue == workspace.id {
                startRenaming()
            }
        }
    }
    
    @ViewBuilder
    private var workspaceMenu: some View {
        Menu {
            workspaceContextMenuItems
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .font(.caption)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
    
    @ViewBuilder
    private var workspaceContextMenuItems: some View {
        Button { startRenaming() } label: {
            Label("Rename", systemImage: "pencil")
        }
        
        Button { createSubWorkspace() } label: {
            Label("New Sub-workspace", systemImage: "folder.badge.plus")
        }
        
        Divider()
        
        Button { moveUp() } label: {
            Label("Move Up", systemImage: "arrow.up")
        }
        .disabled(!canMoveUp)
        
        Button { moveDown() } label: {
            Label("Move Down", systemImage: "arrow.down")
        }
        .disabled(!canMoveDown)
        
        if workspace.parent != nil {
            Button { moveToRoot() } label: {
                Label("Move to Top Level", systemImage: "arrow.up.to.line")
            }
        }
        
        Divider()
        
        Button(role: .destructive) { deleteWorkspace() } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private var siblings: [Workspace] {
        if let parent = workspace.parent {
            return parent.sortedChildren
        } else {
            return allWorkspaces.filter { $0.parent == nil }.sorted { $0.sortOrder < $1.sortOrder }
        }
    }
    
    private var canMoveUp: Bool {
        guard let index = siblings.firstIndex(where: { $0.id == workspace.id }) else { return false }
        return index > 0
    }
    
    private var canMoveDown: Bool {
        guard let index = siblings.firstIndex(where: { $0.id == workspace.id }) else { return false }
        return index < siblings.count - 1
    }
    
    private func moveUp() {
        guard let index = siblings.firstIndex(where: { $0.id == workspace.id }), index > 0 else { return }
        let other = siblings[index - 1]
        let temp = workspace.sortOrder
        workspace.sortOrder = other.sortOrder
        other.sortOrder = temp
        // Update timestamps so sync detects the change
        workspace.updatedAt = Date()
        other.updatedAt = Date()
        
        // Trigger auto-sync
        NotificationCenter.default.post(name: Notification.Name("WorkspaceDidChange"), object: nil)
    }
    
    private func moveDown() {
        guard let index = siblings.firstIndex(where: { $0.id == workspace.id }), index < siblings.count - 1 else { return }
        let other = siblings[index + 1]
        let temp = workspace.sortOrder
        workspace.sortOrder = other.sortOrder
        other.sortOrder = temp
        // Update timestamps so sync detects the change
        workspace.updatedAt = Date()
        other.updatedAt = Date()
        
        // Trigger auto-sync
        NotificationCenter.default.post(name: Notification.Name("WorkspaceDidChange"), object: nil)
    }
    
    @ViewBuilder
    private var dropHighlightBackground: some View {
        if isDropTargeted {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.2))
        } else {
            Color.clear
        }
    }
    
    // MARK: - Actions
    
    private func handleDrop(_ items: [SidebarDragItem]) -> Bool {
        var handled = false
        for item in items {
            switch item {
            case .document(let id):
                if let document = allDocuments.first(where: { $0.id == id }) {
                    document.workspace = workspace
                    document.updatedAt = Date()
                    handled = true
                }
            case .workspace(let id):
                guard id != workspace.id else { continue }
                if let droppedWorkspace = allWorkspaces.first(where: { $0.id == id }) {
                    // Don't allow dropping a parent onto its child
                    guard !isDescendant(workspace, of: droppedWorkspace) else { continue }
                    
                    droppedWorkspace.parent = workspace
                    droppedWorkspace.sortOrder = workspace.children.count
                    droppedWorkspace.updatedAt = Date()
                    workspace.isExpanded = true
                    handled = true
                }
            }
        }
        return handled
    }
    
    private func isDescendant(_ child: Workspace, of ancestor: Workspace) -> Bool {
        var current: Workspace? = child
        while let parent = current?.parent {
            if parent.id == ancestor.id { return true }
            current = parent
        }
        return false
    }
    
    private func startRenaming() {
        newName = workspace.name
        isRenaming = true
        isTextFieldFocused = true
    }
    
    private func commitRename() {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        workspace.name = trimmed.isEmpty ? "Untitled" : trimmed
        workspace.updatedAt = Date()
        isRenaming = false
        
        if workspace.id == newlyCreatedWorkspaceID {
            newlyCreatedWorkspaceID = nil
        }
    }
    
    private func cancelRename() {
        isRenaming = false
        if workspace.name.isEmpty {
            workspace.name = "Untitled"
        }
        if workspace.id == newlyCreatedWorkspaceID {
            newlyCreatedWorkspaceID = nil
        }
    }
    
    private func createSubWorkspace() {
        let sub = Workspace(name: "", parent: workspace)
        sub.sortOrder = workspace.children.count
        modelContext.insert(sub)
        workspace.isExpanded = true
        newlyCreatedWorkspaceID = sub.id
    }
    
    private func moveToRoot() {
        workspace.parent = nil
        // Get count of root workspaces for sort order
        let rootCount = allWorkspaces.filter { $0.parent == nil }.count
        workspace.sortOrder = rootCount
        workspace.updatedAt = Date()
    }
    
    private func moveChildWorkspaces(from source: IndexSet, to destination: Int) {
        // Get the sorted children array and move
        var children = workspace.sortedChildren
        children.move(fromOffsets: source, toOffset: destination)
        
        // Update sortOrder for all children
        for (index, child) in children.enumerated() {
            child.sortOrder = index
            child.updatedAt = Date()
        }
        
        // Trigger auto-sync
        NotificationCenter.default.post(name: Notification.Name("WorkspaceDidChange"), object: nil)
    }
    
    private func deleteWorkspace() {
        modelContext.delete(workspace)
    }
}

// MARK: - Sidebar Item Row

struct SidebarItemRow: View {
    let item: SidebarItem
    
    var body: some View {
        Label {
            HStack {
                Text(item.title.isEmpty ? "Untitled" : item.title)
                Spacer()
                if let badge = item.badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary)
                        .clipShape(Capsule())
                }
            }
        } icon: {
            Image(systemName: item.icon)
                .foregroundStyle(item.iconColor ?? .secondary)
        }
    }
}

// MARK: - Sidebar Footer

struct SidebarFooter: View {
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        HStack {
            Button {
                openSettings()
            } label: {
                Image(systemName: "gearshape")
                    .font(.body)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("Settings")
            
            Spacer()
            
            Button {
                openWindow(id: "community")
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text("Community")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Open Community")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.allDocuments), shouldCreateWorkspace: .constant(false))
            .modelContainer(for: [Document.self, Workspace.self], inMemory: true)
    } content: {
        Text("Content")
    } detail: {
        Text("Detail")
    }
}
