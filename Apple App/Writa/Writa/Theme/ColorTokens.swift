//
//  ColorTokens.swift
//  Writa
//
//  Color definitions for the theming system.
//  Uses semantic naming for flexibility across themes.
//

import SwiftUI

// MARK: - Color Tokens

struct ColorTokens {
    // MARK: - Backgrounds
    let backgroundPrimary: Color
    let backgroundSecondary: Color
    let backgroundTertiary: Color
    let backgroundElevated: Color
    
    // MARK: - Surfaces (for cards, sheets, etc.)
    let surfacePrimary: Color
    let surfaceSecondary: Color
    let surfaceHover: Color
    let surfaceSelected: Color
    
    // MARK: - Text
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let textInverse: Color
    
    // MARK: - Borders
    let borderLight: Color
    let borderMedium: Color
    let borderStrong: Color
    
    // MARK: - Accents
    let accentPrimary: Color
    let accentSecondary: Color
    
    // MARK: - Semantic Colors
    let success: Color
    let warning: Color
    let error: Color
    let info: Color
    
    // MARK: - Sidebar Specific
    let sidebarBackground: Color
    let sidebarItemHover: Color
    let sidebarItemSelected: Color
    let sidebarDivider: Color
    
    // MARK: - Editor Specific
    let editorBackground: Color
    let editorText: Color
    let editorSelection: Color
    let editorCursor: Color
}

// MARK: - Default Theme (Apple Native)

extension ColorTokens {
    static let `default` = ColorTokens(
        // Backgrounds - Using system colors for automatic dark/light mode
        backgroundPrimary: Color(nsColor: .windowBackgroundColor),
        backgroundSecondary: Color(nsColor: .controlBackgroundColor),
        backgroundTertiary: Color(nsColor: .underPageBackgroundColor),
        backgroundElevated: Color(nsColor: .windowBackgroundColor),
        
        // Surfaces
        surfacePrimary: Color(nsColor: .controlBackgroundColor),
        surfaceSecondary: Color(nsColor: .controlBackgroundColor).opacity(0.5),
        surfaceHover: Color(nsColor: .selectedContentBackgroundColor).opacity(0.1),
        surfaceSelected: Color(nsColor: .selectedContentBackgroundColor).opacity(0.2),
        
        // Text
        textPrimary: Color(nsColor: .labelColor),
        textSecondary: Color(nsColor: .secondaryLabelColor),
        textTertiary: Color(nsColor: .tertiaryLabelColor),
        textInverse: Color.white,
        
        // Borders
        borderLight: Color(nsColor: .separatorColor).opacity(0.5),
        borderMedium: Color(nsColor: .separatorColor),
        borderStrong: Color(nsColor: .separatorColor).opacity(1.5),
        
        // Accents - Using system accent color
        accentPrimary: Color.accentColor,
        accentSecondary: Color.accentColor.opacity(0.7),
        
        // Semantic
        success: Color.green,
        warning: Color.orange,
        error: Color.red,
        info: Color.blue,
        
        // Sidebar
        sidebarBackground: Color(nsColor: .windowBackgroundColor),
        sidebarItemHover: Color(nsColor: .selectedContentBackgroundColor).opacity(0.1),
        sidebarItemSelected: Color(nsColor: .selectedContentBackgroundColor).opacity(0.15),
        sidebarDivider: Color(nsColor: .separatorColor),
        
        // Editor
        editorBackground: Color(nsColor: .textBackgroundColor),
        editorText: Color(nsColor: .textColor),
        editorSelection: Color.accentColor.opacity(0.3),
        editorCursor: Color.accentColor
    )
}

// MARK: - CSS Export for Editor Bridge

extension ColorTokens {
    /// Generates CSS custom properties for the embedded Tiptap editor
    /// - Parameter colorScheme: The color scheme to use for resolving dynamic colors.
    ///   This ensures consistent color resolution regardless of the current window appearance.
    func toCSSVariables(for colorScheme: ColorScheme) -> String {
        let isDark = colorScheme == .dark
        
        // Use explicit colors based on color scheme to avoid race conditions
        // with dynamic NSColor resolution during view transitions
        let textPrimaryCSS = isDark ? "rgb(240, 240, 240)" : "rgb(29, 29, 31)"
        let textSecondaryCSS = isDark ? "rgba(255, 255, 255, 0.55)" : "rgba(60, 60, 67, 0.6)"
        let textTertiaryCSS = isDark ? "rgba(255, 255, 255, 0.25)" : "rgba(60, 60, 67, 0.3)"
        let editorTextCSS = isDark ? "rgb(240, 240, 240)" : "rgb(0, 0, 0)"
        let bgPrimaryCSS = isDark ? "rgb(30, 30, 30)" : "rgb(255, 255, 255)"
        let bgSecondaryCSS = isDark ? "rgb(44, 44, 46)" : "rgb(242, 242, 247)"
        let borderCSS = isDark ? "rgba(255, 255, 255, 0.15)" : "rgba(0, 0, 0, 0.1)"
        let editorBgCSS = isDark ? "rgb(30, 30, 30)" : "rgb(255, 255, 255)"
        let editorSelectionCSS = isDark ? "rgba(10, 132, 255, 0.3)" : "rgba(0, 122, 255, 0.3)"
        
        return """
        :root {
            --writa-bg-primary: \(bgPrimaryCSS);
            --writa-bg-secondary: \(bgSecondaryCSS);
            --writa-text-primary: \(textPrimaryCSS);
            --writa-text-secondary: \(textSecondaryCSS);
            --writa-text-tertiary: \(textTertiaryCSS);
            --writa-accent: \(accentPrimary.cssValue);
            --writa-border: \(borderCSS);
            --writa-editor-bg: \(editorBgCSS);
            --writa-editor-text: \(editorTextCSS);
            --writa-editor-selection: \(editorSelectionCSS);
        }
        """
    }
    
    /// Legacy method - prefer toCSSVariables(for:) to avoid color resolution issues
    @available(*, deprecated, message: "Use toCSSVariables(for:) with explicit colorScheme to avoid race conditions")
    func toCSSVariables() -> String {
        // Fallback that attempts dynamic resolution (may be unreliable)
        """
        :root {
            --writa-bg-primary: \(backgroundPrimary.cssValue);
            --writa-bg-secondary: \(backgroundSecondary.cssValue);
            --writa-text-primary: \(textPrimary.cssValue);
            --writa-text-secondary: \(textSecondary.cssValue);
            --writa-text-tertiary: \(textTertiary.cssValue);
            --writa-accent: \(accentPrimary.cssValue);
            --writa-border: \(borderMedium.cssValue);
            --writa-editor-bg: \(editorBackground.cssValue);
            --writa-editor-text: \(editorText.cssValue);
            --writa-editor-selection: \(editorSelection.cssValue);
        }
        """
    }
}

// MARK: - Color CSS Export Helper

extension Color {
    var cssValue: String {
        // Convert to NSColor to extract components
        guard let nsColor = NSColor(self).usingColorSpace(.sRGB) else {
            return "rgb(0, 0, 0)"
        }
        
        let r = Int(nsColor.redComponent * 255)
        let g = Int(nsColor.greenComponent * 255)
        let b = Int(nsColor.blueComponent * 255)
        let a = nsColor.alphaComponent
        
        if a < 1.0 {
            return "rgba(\(r), \(g), \(b), \(String(format: "%.2f", a)))"
        } else {
            return "rgb(\(r), \(g), \(b))"
        }
    }
}
