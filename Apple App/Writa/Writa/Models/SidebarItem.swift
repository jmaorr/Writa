//
//  SidebarItem.swift
//  Writa
//
//  Navigation model for sidebar items (both static sections and dynamic folders).
//

import Foundation
import SwiftUI

// MARK: - Sidebar Section

enum SidebarSection: String, CaseIterable, Identifiable {
    case library = "Library"
    case folders = "Folders"
    case tags = "Tags"
    case smart = "Smart Filters"
    case community = "Community"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

// MARK: - Sidebar Item Type

enum SidebarItemType: Hashable, Identifiable {
    // Library section
    case allDocuments
    case inbox
    case favorites
    case recent
    
    // Folders section
    case folder(UUID)
    
    // Tags section
    case tag(String)
    
    // Smart filters
    case smartFilter(SmartFilterType)
    
    // Community
    case openCommunity
    
    var id: String {
        switch self {
        case .allDocuments: return "all"
        case .inbox: return "inbox"
        case .favorites: return "favorites"
        case .recent: return "recent"
        case .folder(let id): return "folder-\(id.uuidString)"
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
    let section: SidebarSection
    
    init(
        type: SidebarItemType,
        title: String,
        icon: String,
        iconColor: Color? = nil,
        badge: Int? = nil,
        section: SidebarSection
    ) {
        self.id = type.id
        self.type = type
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.badge = badge
        self.section = section
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
        icon: "doc.text",
        section: .library
    )
    
    static let inbox = SidebarItem(
        type: .inbox,
        title: "Inbox",
        icon: "tray",
        section: .library
    )
    
    static let favorites = SidebarItem(
        type: .favorites,
        title: "Favorites",
        icon: "star",
        iconColor: .yellow,
        section: .library
    )
    
    static let recent = SidebarItem(
        type: .recent,
        title: "Recent",
        icon: "clock",
        section: .library
    )
    
    static let openCommunity = SidebarItem(
        type: .openCommunity,
        title: "Open Community",
        icon: "globe",
        iconColor: .blue,
        section: .community
    )
    
    static func folder(_ folder: Folder) -> SidebarItem {
        SidebarItem(
            type: .folder(folder.id),
            title: folder.name,
            icon: folder.icon,
            iconColor: Color(folder.color),
            badge: folder.documentCount,
            section: .folders
        )
    }
    
    static func tag(_ name: String, count: Int = 0) -> SidebarItem {
        SidebarItem(
            type: .tag(name),
            title: name,
            icon: "tag",
            badge: count,
            section: .tags
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
            icon: icon,
            section: .smart
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
