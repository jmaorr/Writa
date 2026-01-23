//
//  SidebarItem.swift
//  Writa
//
//  Navigation model for sidebar items (sections, workspaces, and static items).
//

import Foundation
import SwiftUI

// MARK: - Sidebar Section Type

enum SidebarSectionType: Hashable, Identifiable {
    case library                    // Static "Library" section
    case workspaceSection(UUID)     // User-created sections
    case smartFilters               // Static "Smart Filters" section
    case community                  // Static "Community" section
    
    var id: String {
        switch self {
        case .library: return "library"
        case .workspaceSection(let id): return "section-\(id.uuidString)"
        case .smartFilters: return "smart-filters"
        case .community: return "community"
        }
    }
}

// MARK: - Sidebar Item Type

enum SidebarItemType: Hashable, Identifiable {
    // Library section
    case allDocuments
    case tasks
    case favorites
    case recent
    case trash
    
    // Workspaces (user-created)
    case workspace(UUID)
    
    // Tags section
    case tag(String)
    
    // Smart filters
    case smartFilter(SmartFilterType)
    
    // Community
    case openCommunity
    
    var id: String {
        switch self {
        case .allDocuments: return "all"
        case .tasks: return "tasks"
        case .favorites: return "favorites"
        case .recent: return "recent"
        case .trash: return "trash"
        case .workspace(let id): return "workspace-\(id.uuidString)"
        case .tag(let name): return "tag-\(name)"
        case .smartFilter(let type): return "smart-\(type.rawValue)"
        case .openCommunity: return "community"
        }
    }
}

// MARK: - Smart Filter Types

enum SmartFilterType: String, CaseIterable {
    case recentlyEdited = "Recently Edited"
    case recentlyCreated = "Recently Created"
    case longDocuments = "Long Documents"
    case hasImages = "With Images"
}

// MARK: - Sidebar Item

struct SidebarItem: Identifiable, Hashable {
    let id: String
    let type: SidebarItemType
    let title: String
    let icon: String
    let iconColor: Color?
    let badge: Int?
    
    init(
        type: SidebarItemType,
        title: String,
        icon: String,
        iconColor: Color? = nil,
        badge: Int? = nil
    ) {
        self.id = type.id
        self.type = type
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.badge = badge
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SidebarItem, rhs: SidebarItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Default Items

extension SidebarItem {
    static let allDocuments = SidebarItem(
        type: .allDocuments,
        title: "All Documents",
        icon: "doc.text"
    )
    
    static let tasks = SidebarItem(
        type: .tasks,
        title: "Tasks",
        icon: "checkmark.circle",
        iconColor: .blue
    )
    
    static let favorites = SidebarItem(
        type: .favorites,
        title: "Favorites",
        icon: "star",
        iconColor: .yellow
    )
    
    static let recent = SidebarItem(
        type: .recent,
        title: "Recent",
        icon: "clock"
    )
    
    static func trash(count: Int) -> SidebarItem {
        SidebarItem(
            type: .trash,
            title: "Trash",
            icon: count > 0 ? "trash.fill" : "trash",
            iconColor: .secondary,
            badge: count > 0 ? count : nil
        )
    }
    
    static let openCommunity = SidebarItem(
        type: .openCommunity,
        title: "Open Community",
        icon: "globe",
        iconColor: .blue
    )
    
    static func workspace(_ workspace: Workspace) -> SidebarItem {
        SidebarItem(
            type: .workspace(workspace.id),
            title: workspace.name,
            icon: workspace.icon,
            iconColor: Color(workspace.color),
            badge: workspace.documentCount > 0 ? workspace.documentCount : nil
        )
    }
    
    static func tag(_ name: String, count: Int = 0) -> SidebarItem {
        SidebarItem(
            type: .tag(name),
            title: name,
            icon: "tag",
            badge: count > 0 ? count : nil
        )
    }
    
    static func smartFilter(_ type: SmartFilterType) -> SidebarItem {
        let icon: String
        switch type {
        case .recentlyEdited: icon = "pencil.circle"
        case .recentlyCreated: icon = "plus.circle"
        case .longDocuments: icon = "doc.text.magnifyingglass"
        case .hasImages: icon = "photo"
        }
        
        return SidebarItem(
            type: .smartFilter(type),
            title: type.rawValue,
            icon: icon
        )
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(_ hex: String) {
        // Handle system color names
        switch hex.lowercased() {
        case "systemblue": self = .blue
        case "systemred": self = .red
        case "systemgreen": self = .green
        case "systemorange": self = .orange
        case "systempurple": self = .purple
        case "systemyellow": self = .yellow
        case "systempink": self = .pink
        case "systemteal": self = .teal
        case "systemindigo": self = .indigo
        default:
            // Parse hex color
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)
            let a, r, g, b: UInt64
            switch hex.count {
            case 3: // RGB (12-bit)
                (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
            case 6: // RGB (24-bit)
                (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
            case 8: // ARGB (32-bit)
                (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
            default:
                (a, r, g, b) = (255, 0, 0, 0)
            }
            self.init(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue: Double(b) / 255,
                opacity: Double(a) / 255
            )
        }
    }
}
