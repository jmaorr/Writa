//
//  ToolbarConfiguration.swift
//  Writa
//
//  Defines the editor toolbar configuration including available tools,
//  grouping, and visibility settings.
//

import SwiftUI

// MARK: - Toolbar Entry

/// Represents an item in the toolbar - either a tool or a separator
/// Named "ToolbarEntry" to avoid conflict with SwiftUI's ToolbarItem
enum ToolbarEntry: Identifiable, Codable, Equatable, Hashable {
    case tool(EditorTool)
    case separator
    
    var id: String {
        switch self {
        case .tool(let tool): return "tool-\(tool.rawValue)"
        case .separator: return "separator-\(UUID().uuidString)"
        }
    }
    
    // Custom coding to handle the enum
    enum CodingKeys: String, CodingKey {
        case type, tool
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        if type == "separator" {
            self = .separator
        } else {
            let tool = try container.decode(EditorTool.self, forKey: .tool)
            self = .tool(tool)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .separator:
            try container.encode("separator", forKey: .type)
        case .tool(let tool):
            try container.encode("tool", forKey: .type)
            try container.encode(tool, forKey: .tool)
        }
    }
}

// MARK: - Editor Tool

enum EditorTool: String, CaseIterable, Identifiable, Codable, Hashable {
    // Text Styles
    case title
    case heading
    case body
    
    // Text Formatting
    case bold
    case italic
    case underline
    case strikethrough
    case code
    case highlight
    case subscript_
    case superscript_
    
    // Text Alignment
    case alignLeft
    case alignCenter
    case alignRight
    case alignJustify
    
    // Lists
    case bulletList
    case numberedList
    case taskList
    case taskCard
    
    // Blocks
    case quote
    case codeBlock
    case divider
    
    // Media
    case image
    case link
    case table
    
    // AI / Snippets
    case promptSnippet
    
    // Color
    case textColor
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .title: return "Title"
        case .heading: return "Heading"
        case .body: return "Body"
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .strikethrough: return "Strikethrough"
        case .code: return "Code"
        case .highlight: return "Highlight"
        case .subscript_: return "Subscript"
        case .superscript_: return "Superscript"
        case .alignLeft: return "Align Left"
        case .alignCenter: return "Align Center"
        case .alignRight: return "Align Right"
        case .alignJustify: return "Align Justify"
        case .bulletList: return "Bullets"
        case .numberedList: return "Numbers"
        case .taskList: return "Tasks"
        case .taskCard: return "Task Card"
        case .quote: return "Quote"
        case .codeBlock: return "Code Block"
        case .divider: return "Divider"
        case .image: return "Image"
        case .link: return "Link"
        case .table: return "Table"
        case .promptSnippet: return "Prompt Snippet"
        case .textColor: return "Text Color"
        }
    }
    
    var icon: String {
        switch self {
        case .title: return "textformat.size.larger"
        case .heading: return "textformat.size"
        case .body: return "textformat"
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .strikethrough: return "strikethrough"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .highlight: return "highlighter"
        case .subscript_: return "textformat.subscript"
        case .superscript_: return "textformat.superscript"
        case .alignLeft: return "text.alignleft"
        case .alignCenter: return "text.aligncenter"
        case .alignRight: return "text.alignright"
        case .alignJustify: return "text.justify"
        case .bulletList: return "list.bullet"
        case .numberedList: return "list.number"
        case .taskList: return "checklist"
        case .taskCard: return "checklist.unchecked"
        case .quote: return "text.quote"
        case .codeBlock: return "curlybraces"
        case .divider: return "minus"
        case .image: return "photo"
        case .link: return "link"
        case .table: return "tablecells"
        case .promptSnippet: return "sparkles"
        case .textColor: return "paintpalette"
        }
    }
    
    var shortcut: String? {
        switch self {
        case .title: return "⌘1"
        case .heading: return "⌘2"
        case .body: return "⌘0"
        case .bold: return "⌘B"
        case .italic: return "⌘I"
        case .underline: return "⌘U"
        case .strikethrough: return "⌘⇧X"
        case .code: return "⌘E"
        case .highlight: return "⌘⇧H"
        case .alignLeft: return "⌘⇧L"
        case .alignCenter: return "⌘⇧E"
        case .alignRight: return "⌘⇧R"
        case .alignJustify: return "⌘⇧J"
        case .bulletList: return "⌘⇧8"
        case .numberedList: return "⌘⇧7"
        case .taskList: return "⌘⇧9"
        case .taskCard: return "⌘⇧T"
        case .quote: return "⌘⇧B"
        case .codeBlock: return "⌘⌥C"
        case .image: return "⌘⇧I"
        case .link: return "⌘K"
        case .promptSnippet: return "⌘⇧P"
        default: return nil
        }
    }
    
    /// Custom label style for Settings view (compact icons)
    var customLabel: String? {
        switch self {
        case .title: return "H1"
        case .heading: return "H2"
        case .body: return "B"
        default: return nil
        }
    }
    
    /// Label to display in the toolbar (full text for title/heading/body)
    var toolbarLabel: String? {
        switch self {
        case .title: return "Title"
        case .heading: return "Heading"
        case .body: return "Body"
        default: return customLabel
        }
    }
    
    /// Whether this tool uses a text label (wider button)
    var usesTextLabel: Bool {
        toolbarLabel != nil && toolbarLabel!.count > 2
    }
    
    var category: ToolCategory {
        switch self {
        case .title, .heading, .body:
            return .textStyles
        case .bold, .italic, .underline, .strikethrough, .code, .highlight, .subscript_, .superscript_, .textColor:
            return .formatting
        case .alignLeft, .alignCenter, .alignRight, .alignJustify:
            return .alignment
        case .bulletList, .numberedList, .taskList, .taskCard:
            return .lists
        case .quote, .codeBlock, .divider:
            return .blocks
        case .image, .link, .table, .promptSnippet:
            return .media
        }
    }
}

// MARK: - Tool Category

enum ToolCategory: String, CaseIterable, Identifiable {
    case textStyles = "Text Styles"
    case formatting = "Formatting"
    case alignment = "Alignment"
    case lists = "Lists"
    case blocks = "Blocks"
    case media = "Media"
    
    var id: String { rawValue }
    
    var tools: [EditorTool] {
        EditorTool.allCases.filter { $0.category == self }
    }
}

// MARK: - Toolbar Configuration

@Observable
class ToolbarConfiguration {
    /// Items shown in the toolbar (tools and separators)
    var visibleItems: [ToolbarEntry]
    
    /// Tools in the visible items
    var visibleTools: [EditorTool] {
        visibleItems.compactMap { item in
            if case .tool(let tool) = item { return tool }
            return nil
        }
    }
    
    /// Tools not visible (shown in overflow menu)
    var hiddenTools: [EditorTool] {
        let visible = Set(visibleTools)
        return EditorTool.allCases.filter { !visible.contains($0) }
    }
    
    /// Groups derived from separators
    var groups: [[EditorTool]] {
        var result: [[EditorTool]] = [[]]
        for item in visibleItems {
            switch item {
            case .tool(let tool):
                result[result.count - 1].append(tool)
            case .separator:
                if !result[result.count - 1].isEmpty {
                    result.append([])
                }
            }
        }
        // Remove trailing empty group
        if result.last?.isEmpty == true {
            result.removeLast()
        }
        return result
    }
    
    init() {
        self.visibleItems = ToolbarConfiguration.defaultItems
        loadFromDefaults()
    }
    
    // MARK: - Default Configuration
    
    static let defaultItems: [ToolbarEntry] = [
        // Group 1: Text Styles
        .tool(.title), .tool(.heading), .tool(.body),
        .separator,
        // Group 2: Text Formatting
        .tool(.bold), .tool(.italic),
        .separator,
        // Group 3: Lists and Media
        .tool(.bulletList), .tool(.taskCard), .tool(.table), .tool(.promptSnippet) // Note: taskCard (Task Card), not taskList (Tasks)
    ]
    
    // MARK: - Item Management
    
    func moveItem(from source: IndexSet, to destination: Int) {
        visibleItems.move(fromOffsets: source, toOffset: destination)
        saveToDefaults()
    }
    
    func addTool(_ tool: EditorTool) {
        // Only add if not already visible
        guard !visibleTools.contains(tool) else { return }
        visibleItems.append(.tool(tool))
        saveToDefaults()
    }
    
    func removeTool(_ tool: EditorTool) {
        visibleItems.removeAll { item in
            if case .tool(let t) = item { return t == tool }
            return false
        }
        saveToDefaults()
    }
    
    func addSeparator() {
        visibleItems.append(.separator)
        saveToDefaults()
    }
    
    func removeItem(at index: Int) {
        guard index < visibleItems.count else { return }
        visibleItems.remove(at: index)
        saveToDefaults()
    }
    
    func resetToDefaults() {
        visibleItems = ToolbarConfiguration.defaultItems
        saveToDefaults()
    }
    
    // MARK: - Persistence
    
    private func saveToDefaults() {
        if let encoded = try? JSONEncoder().encode(visibleItems) {
            UserDefaults.standard.set(encoded, forKey: "toolbar.configuration.v3")
        }
    }
    
    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: "toolbar.configuration.v3"),
           let decoded = try? JSONDecoder().decode([ToolbarEntry].self, from: data) {
            visibleItems = decoded
        }
    }
}

// MARK: - Environment Key

private struct ToolbarConfigurationKey: EnvironmentKey {
    static let defaultValue = ToolbarConfiguration()
}

extension EnvironmentValues {
    var toolbarConfiguration: ToolbarConfiguration {
        get { self[ToolbarConfigurationKey.self] }
        set { self[ToolbarConfigurationKey.self] = newValue }
    }
}

extension View {
    func toolbarConfiguration(_ config: ToolbarConfiguration) -> some View {
        environment(\.toolbarConfiguration, config)
    }
}
