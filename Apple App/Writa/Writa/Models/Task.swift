//
//  Task.swift
//  Writa
//
//  Represents a task extracted from TipTap TaskCard content.
//  Tasks are aggregated from all documents for the central Tasks view.
//

import Foundation

/// Represents a single task extracted from a document's TipTap content
struct ExtractedTask: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String?
    let isCompleted: Bool
    let documentID: UUID
    let documentTitle: String
    let nodeIndex: Int  // Position within the document for updates
    
    init(
        title: String,
        description: String?,
        isCompleted: Bool,
        documentID: UUID,
        documentTitle: String,
        nodeIndex: Int
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.documentID = documentID
        self.documentTitle = documentTitle
        self.nodeIndex = nodeIndex
    }
}

// MARK: - ProseMirror JSON Parsing

/// Parses TipTap/ProseMirror JSON to extract TaskCard nodes
struct TaskExtractor {
    
    /// Extract all tasks from a document's content
    static func extractTasks(from document: Document) -> [ExtractedTask] {
        guard let contentData = document.content else { return [] }
        
        do {
            guard let json = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
                return []
            }
            
            var tasks: [ExtractedTask] = []
            var nodeIndex = 0
            
            // Parse the document content recursively
            if let content = json["content"] as? [[String: Any]] {
                for node in content {
                    extractTasksFromNode(
                        node,
                        documentID: document.id,
                        documentTitle: document.displayTitle,
                        tasks: &tasks,
                        nodeIndex: &nodeIndex
                    )
                }
            }
            
            return tasks
        } catch {
            print("❌ Failed to parse document content for tasks: \(error)")
            return []
        }
    }
    
    /// Recursively extract tasks from a ProseMirror node
    private static func extractTasksFromNode(
        _ node: [String: Any],
        documentID: UUID,
        documentTitle: String,
        tasks: inout [ExtractedTask],
        nodeIndex: inout Int
    ) {
        guard let type = node["type"] as? String else { return }
        
        if type == "taskCard" {
            // Extract task card data
            let attrs = node["attrs"] as? [String: Any] ?? [:]
            let isCompleted = attrs["checked"] as? Bool ?? false
            
            var title = ""
            var description: String?
            
            // Parse child nodes for title and description
            if let content = node["content"] as? [[String: Any]] {
                for child in content {
                    if let childType = child["type"] as? String {
                        if childType == "taskCardTitle" {
                            title = extractText(from: child)
                        } else if childType == "taskCardDescription" {
                            let descText = extractText(from: child)
                            if !descText.isEmpty {
                                description = descText
                            }
                        }
                    }
                }
            }
            
            // Only add tasks that have a title
            if !title.isEmpty {
                let task = ExtractedTask(
                    title: title,
                    description: description,
                    isCompleted: isCompleted,
                    documentID: documentID,
                    documentTitle: documentTitle,
                    nodeIndex: nodeIndex
                )
                tasks.append(task)
            }
            
            nodeIndex += 1
        }
        
        // Recursively check child nodes (for taskCardList containers, etc.)
        if let content = node["content"] as? [[String: Any]] {
            for child in content {
                extractTasksFromNode(
                    child,
                    documentID: documentID,
                    documentTitle: documentTitle,
                    tasks: &tasks,
                    nodeIndex: &nodeIndex
                )
            }
        }
    }
    
    /// Extract plain text from a node's content
    private static func extractText(from node: [String: Any]) -> String {
        guard let content = node["content"] as? [[String: Any]] else { return "" }
        
        var text = ""
        for child in content {
            if let childType = child["type"] as? String {
                if childType == "text", let textContent = child["text"] as? String {
                    text += textContent
                } else {
                    // Recursively get text from nested nodes
                    text += extractText(from: child)
                }
            }
        }
        return text
    }
}

// MARK: - Task Toggle

struct TaskToggler {
    
    /// Toggle the completion status of a task in a document's content
    /// Returns the updated content data, or nil if the operation failed
    static func toggleTask(at nodeIndex: Int, in document: Document) -> Data? {
        guard let contentData = document.content else { return nil }
        
        do {
            guard var json = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
                return nil
            }
            
            var currentIndex = 0
            if var content = json["content"] as? [[String: Any]] {
                if toggleTaskInNodes(&content, targetIndex: nodeIndex, currentIndex: &currentIndex) {
                    json["content"] = content
                    return try JSONSerialization.data(withJSONObject: json)
                }
            }
            
            return nil
        } catch {
            print("❌ Failed to toggle task: \(error)")
            return nil
        }
    }
    
    /// Recursively find and toggle the task at the target index
    private static func toggleTaskInNodes(
        _ nodes: inout [[String: Any]],
        targetIndex: Int,
        currentIndex: inout Int
    ) -> Bool {
        for i in nodes.indices {
            guard let type = nodes[i]["type"] as? String else { continue }
            
            if type == "taskCard" {
                if currentIndex == targetIndex {
                    // Found the task - toggle its checked attribute
                    var attrs = nodes[i]["attrs"] as? [String: Any] ?? [:]
                    let currentChecked = attrs["checked"] as? Bool ?? false
                    attrs["checked"] = !currentChecked
                    nodes[i]["attrs"] = attrs
                    return true
                }
                currentIndex += 1
            }
            
            // Recursively check child nodes
            if var content = nodes[i]["content"] as? [[String: Any]] {
                if toggleTaskInNodes(&content, targetIndex: targetIndex, currentIndex: &currentIndex) {
                    nodes[i]["content"] = content
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - Document Extension

extension Document {
    /// Extract all tasks from this document's content
    var extractedTasks: [ExtractedTask] {
        TaskExtractor.extractTasks(from: self)
    }
    
    /// Count of incomplete tasks in this document
    var incompleteTaskCount: Int {
        extractedTasks.filter { !$0.isCompleted }.count
    }
    
    /// Count of all tasks in this document
    var totalTaskCount: Int {
        extractedTasks.count
    }
    
    /// Toggle a task's completion status
    func toggleTask(at nodeIndex: Int) -> Bool {
        if let updatedContent = TaskToggler.toggleTask(at: nodeIndex, in: self) {
            self.content = updatedContent
            self.updatedAt = Date()
            return true
        }
        return false
    }
}
