//
//  EditorTheme.swift
//  Writa
//
//  Codable editor theme model for pre-baked themes and cloud sync.
//  Contains all customizable editor appearance settings.
//

import SwiftUI

// MARK: - Editor Theme

/// Complete editor theme configuration - Codable for sync
struct EditorTheme: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    var category: ThemeCategory
    var isBuiltIn: Bool
    
    // Typography
    var fontFamily: String
    var fontSize: CGFloat
    var lineHeight: CGFloat
    
    // Per-style spacing (multiplier of font size)
    var paragraphSpacingBefore: CGFloat
    var paragraphSpacingAfter: CGFloat
    var h1SpacingBefore: CGFloat
    var h1SpacingAfter: CGFloat
    var h2SpacingBefore: CGFloat
    var h2SpacingAfter: CGFloat
    var h3SpacingBefore: CGFloat
    var h3SpacingAfter: CGFloat
    
    // Layout
    var contentWidth: CGFloat
    var padding: CGFloat
    
    // Colors (stored as hex for sync compatibility)
    var accentColorHex: String?  // nil = use system accent
    
    // Metadata
    var author: String?
    var version: Int
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String = "",
        category: ThemeCategory = .custom,
        isBuiltIn: Bool = false,
        fontFamily: String = ".AppleSystemUIFont",
        fontSize: CGFloat = 16,
        lineHeight: CGFloat = 1.4,
        paragraphSpacingBefore: CGFloat = 0.0,
        paragraphSpacingAfter: CGFloat = 0.3,
        h1SpacingBefore: CGFloat = 1.5,
        h1SpacingAfter: CGFloat = 0.0,
        h2SpacingBefore: CGFloat = 1.2,
        h2SpacingAfter: CGFloat = 0.0,
        h3SpacingBefore: CGFloat = 1.0,
        h3SpacingAfter: CGFloat = 0.0,
        contentWidth: CGFloat = 720,
        padding: CGFloat = 32,
        accentColorHex: String? = nil,
        author: String? = nil,
        version: Int = 1
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.isBuiltIn = isBuiltIn
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.paragraphSpacingBefore = paragraphSpacingBefore
        self.paragraphSpacingAfter = paragraphSpacingAfter
        self.h1SpacingBefore = h1SpacingBefore
        self.h1SpacingAfter = h1SpacingAfter
        self.h2SpacingBefore = h2SpacingBefore
        self.h2SpacingAfter = h2SpacingAfter
        self.h3SpacingBefore = h3SpacingBefore
        self.h3SpacingAfter = h3SpacingAfter
        self.contentWidth = contentWidth
        self.padding = padding
        self.accentColorHex = accentColorHex
        self.author = author
        self.version = version
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Theme Category

enum ThemeCategory: String, Codable, CaseIterable, Identifiable {
    case minimal = "Minimal"
    case focused = "Focused"
    case classic = "Classic"
    case modern = "Modern"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .minimal: return "square"
        case .focused: return "eye"
        case .classic: return "book"
        case .modern: return "sparkles"
        case .custom: return "paintbrush"
        }
    }
}

// MARK: - Built-in Theme Library

struct ThemeLibrary {
    
    /// All built-in themes available to users
    static let builtIn: [EditorTheme] = [
        // MARK: - Minimal Category
        
        EditorTheme(
            id: "default",
            name: "Default",
            description: "Clean and balanced. The standard Writa experience.",
            category: .minimal,
            isBuiltIn: true,
            fontFamily: ".AppleSystemUIFont",
            fontSize: 16,
            lineHeight: 1.4,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 0.3,
            h1SpacingBefore: 1.5,
            h1SpacingAfter: 0.0,
            h2SpacingBefore: 1.2,
            h2SpacingAfter: 0.0,
            h3SpacingBefore: 1.0,
            h3SpacingAfter: 0.0,
            contentWidth: 720,
            padding: 32,
            author: "Writa"
        ),
        
        EditorTheme(
            id: "compact",
            name: "Compact",
            description: "Tighter spacing for information-dense writing.",
            category: .minimal,
            isBuiltIn: true,
            fontFamily: ".AppleSystemUIFont",
            fontSize: 15,
            lineHeight: 1.5,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 0.5,
            h1SpacingBefore: 1.0,
            h1SpacingAfter: 0.3,
            h2SpacingBefore: 0.8,
            h2SpacingAfter: 0.25,
            h3SpacingBefore: 0.6,
            h3SpacingAfter: 0.2,
            contentWidth: 680,
            padding: 24,
            author: "Writa"
        ),
        
        EditorTheme(
            id: "airy",
            name: "Airy",
            description: "Extra breathing room for comfortable reading.",
            category: .minimal,
            isBuiltIn: true,
            fontFamily: ".AppleSystemUIFont",
            fontSize: 16,
            lineHeight: 1.8,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 1.0,
            h1SpacingBefore: 2.0,
            h1SpacingAfter: 0.6,
            h2SpacingBefore: 1.5,
            h2SpacingAfter: 0.5,
            h3SpacingBefore: 1.2,
            h3SpacingAfter: 0.4,
            contentWidth: 640,
            padding: 48,
            author: "Writa"
        ),
        
        // MARK: - Focused Category
        
        EditorTheme(
            id: "typewriter",
            name: "Typewriter",
            description: "Monospace font for a classic writing feel.",
            category: .focused,
            isBuiltIn: true,
            fontFamily: "SF Mono",
            fontSize: 15,
            lineHeight: 1.7,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 1.2,
            h1SpacingBefore: 2.0,
            h1SpacingAfter: 0.8,
            h2SpacingBefore: 1.5,
            h2SpacingAfter: 0.6,
            h3SpacingBefore: 1.2,
            h3SpacingAfter: 0.4,
            contentWidth: 640,
            padding: 40,
            author: "Writa"
        ),
        
        EditorTheme(
            id: "novelist",
            name: "Novelist",
            description: "Generous margins for long-form writing.",
            category: .focused,
            isBuiltIn: true,
            fontFamily: ".AppleSystemUIFont",
            fontSize: 17,
            lineHeight: 1.9,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 0.4,
            h1SpacingBefore: 2.0,
            h1SpacingAfter: 0.5,
            h2SpacingBefore: 1.5,
            h2SpacingAfter: 0.4,
            h3SpacingBefore: 1.2,
            h3SpacingAfter: 0.3,
            contentWidth: 580,
            padding: 64,
            author: "Writa"
        ),
        
        // MARK: - Classic Category
        
        EditorTheme(
            id: "editorial",
            name: "Editorial",
            description: "Elegant serif typography for polished prose.",
            category: .classic,
            isBuiltIn: true,
            fontFamily: "New York",
            fontSize: 18,
            lineHeight: 1.8,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 1.0,
            h1SpacingBefore: 2.0,
            h1SpacingAfter: 0.6,
            h2SpacingBefore: 1.5,
            h2SpacingAfter: 0.5,
            h3SpacingBefore: 1.2,
            h3SpacingAfter: 0.4,
            contentWidth: 680,
            padding: 40,
            author: "Writa"
        ),
        
        EditorTheme(
            id: "literary",
            name: "Literary",
            description: "Traditional book-like reading experience.",
            category: .classic,
            isBuiltIn: true,
            fontFamily: "Georgia",
            fontSize: 18,
            lineHeight: 1.75,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 0.8,
            h1SpacingBefore: 1.8,
            h1SpacingAfter: 0.5,
            h2SpacingBefore: 1.4,
            h2SpacingAfter: 0.4,
            h3SpacingBefore: 1.0,
            h3SpacingAfter: 0.3,
            contentWidth: 600,
            padding: 56,
            author: "Writa"
        ),
        
        // MARK: - Modern Category
        
        EditorTheme(
            id: "technical",
            name: "Technical",
            description: "Optimized for documentation and code-heavy content.",
            category: .modern,
            isBuiltIn: true,
            fontFamily: ".AppleSystemUIFont",
            fontSize: 15,
            lineHeight: 1.6,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 0.8,
            h1SpacingBefore: 1.5,
            h1SpacingAfter: 0.5,
            h2SpacingBefore: 1.25,
            h2SpacingAfter: 0.4,
            h3SpacingBefore: 1.0,
            h3SpacingAfter: 0.3,
            contentWidth: 800,
            padding: 32,
            author: "Writa"
        ),
        
        EditorTheme(
            id: "presentation",
            name: "Presentation",
            description: "Large, clear text for sharing and presenting.",
            category: .modern,
            isBuiltIn: true,
            fontFamily: ".AppleSystemUIFont",
            fontSize: 20,
            lineHeight: 1.7,
            paragraphSpacingBefore: 0.0,
            paragraphSpacingAfter: 1.2,
            h1SpacingBefore: 2.0,
            h1SpacingAfter: 0.8,
            h2SpacingBefore: 1.5,
            h2SpacingAfter: 0.6,
            h3SpacingBefore: 1.2,
            h3SpacingAfter: 0.5,
            contentWidth: 760,
            padding: 48,
            author: "Writa"
        ),
    ]
    
    /// Get a theme by ID
    static func theme(withId id: String) -> EditorTheme? {
        builtIn.first { $0.id == id }
    }
    
    /// Get themes by category
    static func themes(in category: ThemeCategory) -> [EditorTheme] {
        builtIn.filter { $0.category == category }
    }
    
    /// Default theme
    static var defaultTheme: EditorTheme {
        theme(withId: "default") ?? builtIn[0]
    }
}

// MARK: - Theme Application Extension

extension ThemeManager {
    /// Apply a pre-built theme
    func apply(theme: EditorTheme) {
        editorFontFamily = theme.fontFamily
        editorFontSize = theme.fontSize
        editorLineHeight = theme.lineHeight
        
        // Per-style spacing
        paragraphSpacingBefore = theme.paragraphSpacingBefore
        paragraphSpacingAfter = theme.paragraphSpacingAfter
        h1SpacingBefore = theme.h1SpacingBefore
        h1SpacingAfter = theme.h1SpacingAfter
        h2SpacingBefore = theme.h2SpacingBefore
        h2SpacingAfter = theme.h2SpacingAfter
        h3SpacingBefore = theme.h3SpacingBefore
        h3SpacingAfter = theme.h3SpacingAfter
        
        editorContentWidth = theme.contentWidth
        editorPadding = theme.padding
        
        // Store the selected theme ID
        selectedThemeId = theme.id
        
        // Handle accent color if specified
        if let hex = theme.accentColorHex {
            useSystemAccent = false
            customAccentColor = Color(hex: hex) ?? .blue
        } else {
            useSystemAccent = true
        }
        
        // Switch to custom preset (since we're applying specific values)
        preset = .custom
    }
    
    /// Current theme ID (for sync)
    var selectedThemeId: String {
        get { UserDefaults.standard.string(forKey: "theme.selectedId") ?? "default" }
        set { UserDefaults.standard.set(newValue, forKey: "theme.selectedId") }
    }
    
    /// Get the currently applied theme (or construct from current settings)
    var currentTheme: EditorTheme {
        EditorTheme(
            id: selectedThemeId,
            name: "Current",
            fontFamily: editorFontFamily,
            fontSize: editorFontSize,
            lineHeight: editorLineHeight,
            paragraphSpacingBefore: paragraphSpacingBefore,
            paragraphSpacingAfter: paragraphSpacingAfter,
            h1SpacingBefore: h1SpacingBefore,
            h1SpacingAfter: h1SpacingAfter,
            h2SpacingBefore: h2SpacingBefore,
            h2SpacingAfter: h2SpacingAfter,
            h3SpacingBefore: h3SpacingBefore,
            h3SpacingAfter: h3SpacingAfter,
            contentWidth: editorContentWidth,
            padding: editorPadding,
            accentColorHex: useSystemAccent ? nil : customAccentColor.toHex()
        )
    }
}

// MARK: - Color Hex Conversion

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String? {
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return nil }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
