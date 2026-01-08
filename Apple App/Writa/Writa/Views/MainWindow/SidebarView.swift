//
//  SidebarView.swift
//  Writa
//
//  Main sidebar navigation for the personal library.
//  Displays folders, tags, smart filters, and community access.
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    
    @Binding var selection: SidebarItemType?
    
    // MARK: - Static Items
    
    private let libraryItems: [SidebarItem] = [
        .allDocuments,
        .inbox,
        .favorites,
        .recent
    ]
    
    private let smartFilters: [SidebarItem] = SmartFilterType.allCases.map {
        SidebarItem.smartFilter($0)
    }
    
    var body: some View {
        List(selection: $selection) {
            // MARK: - Library Section
            Section("Library") {
                ForEach(libraryItems) { item in
                    SidebarItemRow(item: item)
                        .tag(item.type)
                }
            }
            
            // MARK: - Folders Section
            Section("Folders") {
                if folders.isEmpty {
                    Text("No folders")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(folders.filter { $0.isRoot }) { folder in
                        FolderTreeRow(folder: folder, selection: $selection)
                    }
                }
            }
            
            // MARK: - Smart Filters Section
            Section("Smart Filters") {
                ForEach(smartFilters) { item in
                    SidebarItemRow(item: item)
                        .tag(item.type)
                }
            }
            
            // MARK: - Community Section
            Section {
                Button {
                    openWindow(id: "community")
                } label: {
                    Label {
                        Text("Open Community")
                    } icon: {
                        Image(systemName: "globe")
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.plain)
                .padding(.vertical, 2)
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            SidebarFooter()
        }
        .toolbar {
            ToolbarItem {
                Button(action: createNewFolder) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func createNewFolder() {
        let folder = Folder(name: "New Folder")
        modelContext.insert(folder)
    }
}

// MARK: - Sidebar Item Row

struct SidebarItemRow: View {
    let item: SidebarItem
    
    var body: some View {
        Label {
            HStack {
                Text(item.title)
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

// MARK: - Folder Tree Row (Recursive)

struct FolderTreeRow: View {
    @Bindable var folder: Folder
    @Binding var selection: SidebarItemType?
    
    var body: some View {
        DisclosureGroup(isExpanded: $folder.isExpanded) {
            // Child folders
            ForEach(folder.children.sorted { $0.sortOrder < $1.sortOrder }) { child in
                FolderTreeRow(folder: child, selection: $selection)
            }
        } label: {
            SidebarItemRow(item: .folder(folder))
                .tag(SidebarItemType.folder(folder.id))
        }
    }
}

// MARK: - Sidebar Footer

struct SidebarFooter: View {
    @Environment(\.openSettings) private var openSettings
    
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
            
            // Sync status indicator (placeholder)
            HStack(spacing: 4) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Synced")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.allDocuments))
            .modelContainer(for: [Document.self, Folder.self], inMemory: true)
    } content: {
        Text("Content")
    } detail: {
        Text("Detail")
    }
}
