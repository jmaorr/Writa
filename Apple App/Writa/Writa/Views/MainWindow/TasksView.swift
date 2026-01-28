//
//  TasksView.swift
//  Writa
//
//  Central view for displaying all tasks aggregated from documents.
//  Replaces the Inbox functionality.
//

import SwiftUI
import SwiftData

// MARK: - Sort Options

enum TaskSortOption: String, CaseIterable {
    case documentOrder = "Document Order"
    case alphabetical = "Alphabetical"
    case completionStatus = "Completion Status"
}

// MARK: - Filter Options

enum TaskFilterOption: String, CaseIterable {
    case all = "All Tasks"
    case incomplete = "Incomplete Only"
    case completed = "Completed Only"
}

// MARK: - View Mode

enum TaskViewMode: String, CaseIterable {
    case groupedByDocument = "Grouped by Document"
    case flatList = "Flat List"
}

struct TasksView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<Document> { $0.isTrashed == false })
    private var documents: [Document]
    
    @Binding var selectedDocumentIDs: Set<Document.ID>
    
    @State private var filterOption: TaskFilterOption = .all
    @State private var sortOption: TaskSortOption = .documentOrder
    @State private var viewMode: TaskViewMode = .groupedByDocument
    
    private var allTasks: [ExtractedTask] {
        documents.flatMap { $0.extractedTasks }
    }
    
    private var filteredTasks: [ExtractedTask] {
        switch filterOption {
        case .all:
            return allTasks
        case .incomplete:
            return allTasks.filter { !$0.isCompleted }
        case .completed:
            return allTasks.filter { $0.isCompleted }
        }
    }
    
    private var sortedTasks: [ExtractedTask] {
        switch sortOption {
        case .documentOrder:
            return filteredTasks
        case .alphabetical:
            return filteredTasks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .completionStatus:
            return filteredTasks.sorted { !$0.isCompleted && $1.isCompleted }
        }
    }
    
    private var incompleteTasks: [ExtractedTask] {
        sortedTasks.filter { !$0.isCompleted }
    }
    
    private var completedTasks: [ExtractedTask] {
        sortedTasks.filter { $0.isCompleted }
    }
    
    var body: some View {
        Group {
            if allTasks.isEmpty {
                emptyState
            } else if filteredTasks.isEmpty {
                noMatchingTasksState
            } else {
                taskList
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItemGroup {
                Menu {
                    // View Mode
                    Section("View") {
                        Picker("View Mode", selection: $viewMode) {
                            ForEach(TaskViewMode.allCases, id: \.self) { mode in
                                Label(mode.rawValue, systemImage: mode == .groupedByDocument ? "rectangle.3.group" : "list.bullet")
                                    .tag(mode)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                    
                    // Sort
                    Section("Sort By") {
                        Picker("Sort", selection: $sortOption) {
                            ForEach(TaskSortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                    
                    // Filter
                    Section("Filter") {
                        Picker("Filter", selection: $filterOption) {
                            ForEach(TaskFilterOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
                .menuIndicator(.hidden)
                .help("View, sort, and filter options")
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Tasks", systemImage: "checkmark.circle")
        } description: {
            Text("Tasks you create in your documents will appear here.")
        }
    }
    
    private var noMatchingTasksState: some View {
        ContentUnavailableView {
            Label("No Matching Tasks", systemImage: "line.3.horizontal.decrease.circle")
        } description: {
            Text("No tasks match the current filter.")
        } actions: {
            Button("Show All Tasks") {
                filterOption = .all
            }
        }
    }
    
    // MARK: - Task List
    
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                switch viewMode {
                case .groupedByDocument:
                    groupedTaskList
                case .flatList:
                    flatTaskList
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    // MARK: - Grouped by Document
    
    private var groupedTaskList: some View {
        ForEach(documentsWithTasks, id: \.id) { document in
            Section {
                let tasks = tasksForDocument(document)
                ForEach(tasks) { task in
                    TaskRowView(
                        task: task,
                        onToggle: { toggleTask(task) },
                        onTap: { openDocument(for: task) }
                    )
                }
            } header: {
                documentHeader(for: document)
            }
        }
    }
    
    private var documentsWithTasks: [Document] {
        documents.filter { doc in
            !tasksForDocument(doc).isEmpty
        }
    }
    
    private func tasksForDocument(_ document: Document) -> [ExtractedTask] {
        var tasks = document.extractedTasks
        
        // Apply filter
        switch filterOption {
        case .all:
            break
        case .incomplete:
            tasks = tasks.filter { !$0.isCompleted }
        case .completed:
            tasks = tasks.filter { $0.isCompleted }
        }
        
        // Apply sort
        switch sortOption {
        case .documentOrder:
            break
        case .alphabetical:
            tasks.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .completionStatus:
            tasks.sort { !$0.isCompleted && $1.isCompleted }
        }
        
        return tasks
    }
    
    private func documentHeader(for document: Document) -> some View {
        Button {
            if let doc = documents.first(where: { $0.id == document.id }) {
                selectedDocumentIDs = [doc.id]
            }
        } label: {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundStyle(.secondary)
                
                Text(document.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                let incomplete = document.incompleteTaskCount
                let total = document.totalTaskCount
                Text("\(incomplete)/\(total)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.95))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Flat List
    
    private var flatTaskList: some View {
        Group {
            if !incompleteTasks.isEmpty {
                Section {
                    ForEach(incompleteTasks) { task in
                        TaskRowView(
                            task: task,
                            showDocumentName: true,
                            onToggle: { toggleTask(task) },
                            onTap: { openDocument(for: task) }
                        )
                    }
                } header: {
                    sectionHeader("To Do", count: incompleteTasks.count)
                }
            }
            
            if !completedTasks.isEmpty {
                Section {
                    ForEach(completedTasks) { task in
                        TaskRowView(
                            task: task,
                            showDocumentName: true,
                            onToggle: { toggleTask(task) },
                            onTap: { openDocument(for: task) }
                        )
                    }
                } header: {
                    sectionHeader("Completed", count: completedTasks.count)
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            
            Spacer()
            
            Text("\(count)")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.95))
    }
    
    // MARK: - Actions
    
    private func openDocument(for task: ExtractedTask) {
        if let document = documents.first(where: { $0.id == task.documentID }) {
            selectedDocumentIDs = [document.id]
        }
    }
    
    private func toggleTask(_ task: ExtractedTask) {
        guard let document = documents.first(where: { $0.id == task.documentID }) else { return }
        
        if document.toggleTask(at: task.nodeIndex) {
            try? modelContext.save()
            
            // Notify open editor to sync
            let toggleInfo = TaskToggleInfo(
                documentID: task.documentID,
                nodeIndex: task.nodeIndex,
                isCompleted: !task.isCompleted  // New state after toggle
            )
            NotificationCenter.default.post(
                name: .taskToggled,
                object: toggleInfo
            )
            
            print("✅ Toggled task: \(task.title)")
        }
    }
}

// MARK: - Task Row View

struct TaskRowView: View {
    let task: ExtractedTask
    var showDocumentName: Bool = false
    let onToggle: () -> Void
    let onTap: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Clickable Checkbox
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : isHovering ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovering = hovering
            }
            .help(task.isCompleted ? "Mark as incomplete" : "Mark as complete")
            
            // Content (clickable to open document)
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .leading, spacing: 4) {
                        // Title
                        Text(task.title)
                            .font(.body)
                            .foregroundStyle(task.isCompleted ? .secondary : .primary)
                            .strikethrough(task.isCompleted)
                            .lineLimit(2)
                        
                        // Description
                        if let description = task.description {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        
                        // Document name (in flat view)
                        if showDocumentName {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.text")
                                    .font(.caption2)
                                Text(task.documentTitle)
                                    .font(.caption)
                            }
                            .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Spacer()
                    
                    // Arrow to indicate navigation
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    TasksView(selectedDocumentIDs: .constant([]))
        .modelContainer(for: [Document.self, Workspace.self], inMemory: true)
        .frame(width: 350, height: 600)
}
