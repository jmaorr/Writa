//
//  ThemeManager.swift
//  Writa
//
//  Central theme management for the application.
//  Handles theme switching, persistence, and CSS export for the editor.
//

import SwiftUI
import Observation

// MARK: - Theme Mode

enum ThemeMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Preset

enum ThemePreset: String, CaseIterable, Identifiable {
    case apple = "Apple Native"
    case minimal = "Minimal"
    case editorial = "Editorial"
    case custom = "Custom"
    
    var id: String { rawValue }
}

// MARK: - Theme Manager

@Observable
final class ThemeManager {
    // MARK: - Properties
    
    /// Incremented whenever any editor setting changes - use this to observe all changes at once
    var editorSettingsVersion: Int = 0
    
    /// Flag to prevent applyPreset during initialization
    private var isLoadingSettings: Bool = false
    
    var mode: ThemeMode = .system {
        didSet { persistSettings() }
    }
    
    var preset: ThemePreset = .apple {
        didSet {
            // Only apply preset if not loading settings (to avoid overwriting loaded values)
            if !isLoadingSettings {
                applyPreset()
            }
            persistSettings()
        }
    }
    
    var tokens: DesignTokens = .default
    
    // MARK: - Editor Font Customization
    
    var editorFontFamily: String = ".AppleSystemUIFont" {
        didSet {
            updateEditorTypography()
            persistSettings()
        }
    }
    
    var editorFontSize: CGFloat = 16 {
        didSet {
            updateEditorTypography()
            persistSettings()
        }
    }
    
    var editorLineHeight: CGFloat = 1.4 {
        didSet {
            updateEditorTypography()
            persistSettings()
        }
    }
    
    // Per-style spacing (multiplier of font size)
    var paragraphSpacingBefore: CGFloat = 0.0 {
        didSet { persistSettings() }
    }
    var paragraphSpacingAfter: CGFloat = 0.3 {
        didSet { persistSettings() }
    }
    
    var h1SpacingBefore: CGFloat = 1.5 {
        didSet { persistSettings() }
    }
    var h1SpacingAfter: CGFloat = 0.0 {
        didSet { persistSettings() }
    }
    
    var h2SpacingBefore: CGFloat = 1.2 {
        didSet { persistSettings() }
    }
    var h2SpacingAfter: CGFloat = 0.0 {
        didSet { persistSettings() }
    }
    
    var h3SpacingBefore: CGFloat = 1.0 {
        didSet { persistSettings() }
    }
    var h3SpacingAfter: CGFloat = 0.0 {
        didSet { persistSettings() }
    }
    
    // Background colors - initialize to explicit defaults (not system colors)
    var editorBackgroundColorLight: Color = Color(hex: "#ffffff") ?? .white {
        didSet { persistSettings() }
    }
    var editorBackgroundColorDark: Color = Color(hex: "#1e1e1e") ?? Color(white: 0.12) {
        didSet { persistSettings() }
    }
    
    // Layout
    var editorContentWidth: CGFloat = 720 {
        didSet { persistSettings() }
    }
    
    var editorPadding: CGFloat = 32 {
        didSet { persistSettings() }
    }
    
    // MARK: - Accent Color Override
    
    var useSystemAccent: Bool = true {
        didSet { persistSettings() }
    }
    
    var customAccentColor: Color = .blue {
        didSet { persistSettings() }
    }
    
    var accentColor: Color {
        useSystemAccent ? .accentColor : customAccentColor
    }
    
    // MARK: - Initialization
    
    init() {
        isLoadingSettings = true
        loadSettings()
        isLoadingSettings = false
        
        // If no preset was saved, apply default preset
        if UserDefaults.standard.string(forKey: "theme.preset") == nil {
            applyPreset()
        }
    }
    
    // MARK: - Preset Application
    
    private func applyPreset() {
        switch preset {
        case .apple:
            tokens = .default
            editorFontFamily = ".AppleSystemUIFont"
            editorFontSize = 16
            editorLineHeight = 1.4
            paragraphSpacingBefore = 0.0
            paragraphSpacingAfter = 0.3
            h1SpacingBefore = 1.5
            h1SpacingAfter = 0.0
            h2SpacingBefore = 1.2
            h2SpacingAfter = 0.0
            h3SpacingBefore = 1.0
            h3SpacingAfter = 0.0
            editorContentWidth = 720
            editorPadding = 32
            
        case .minimal:
            tokens = .default
            editorFontFamily = ".AppleSystemUIFont"
            editorFontSize = 15
            editorLineHeight = 1.4
            paragraphSpacingBefore = 0.0
            paragraphSpacingAfter = 0.3
            h1SpacingBefore = 1.2
            h1SpacingAfter = 0.0
            h2SpacingBefore = 1.0
            h2SpacingAfter = 0.0
            h3SpacingBefore = 0.8
            h3SpacingAfter = 0.0
            editorContentWidth = 640
            editorPadding = 48
            
        case .editorial:
            tokens = .default
            editorFontFamily = "New York"  // Apple's serif font
            editorFontSize = 18
            editorLineHeight = 1.4
            paragraphSpacingBefore = 0.0
            paragraphSpacingAfter = 0.3
            h1SpacingBefore = 2.0
            h1SpacingAfter = 0.0
            h2SpacingBefore = 1.5
            h2SpacingAfter = 0.0
            h3SpacingBefore = 1.2
            h3SpacingAfter = 0.0
            editorContentWidth = 680
            editorPadding = 40
            
        case .custom:
            // Keep current custom settings
            break
        }
    }
    
    private func updateEditorTypography() {
        // Update editor-specific typography tokens
        var typography = tokens.typography
        typography = TypographyTokens(
            primaryFamily: typography.primaryFamily,
            monoFamily: typography.monoFamily,
            editorFamily: editorFontFamily,
            largeTitle: typography.largeTitle,
            title1: typography.title1,
            title2: typography.title2,
            title3: typography.title3,
            headline: typography.headline,
            body: typography.body,
            callout: typography.callout,
            subheadline: typography.subheadline,
            footnote: typography.footnote,
            caption1: typography.caption1,
            caption2: typography.caption2,
            editorBody: TextStyle(
                size: editorFontSize,
                weight: .regular,
                lineHeight: editorLineHeight,
                letterSpacing: 0,
                family: editorFontFamily == ".AppleSystemUIFont" ? nil : editorFontFamily
            ),
            editorHeading1: typography.editorHeading1,
            editorHeading2: typography.editorHeading2,
            editorHeading3: typography.editorHeading3,
            editorCode: typography.editorCode,
            editorBlockquote: typography.editorBlockquote
        )
        tokens = DesignTokens(
            colors: tokens.colors,
            typography: typography,
            spacing: tokens.spacing,
            radius: tokens.radius,
            shadows: tokens.shadows
        )
    }
    
    // MARK: - CSS Export for Editor
    
    /// Generates complete CSS for the embedded Tiptap editor
    func editorCSS(for colorScheme: ColorScheme) -> String {
        let isDark = colorScheme == .dark
        let colorVars = tokens.colors.toCSSVariables(for: colorScheme)
        let typographyVars = tokens.typography.toCSSVariables()
        
        // Computed values for editor
        let fontFamily = editorFontFamily == ".AppleSystemUIFont" 
            ? "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif" 
            : "'\(editorFontFamily)', -apple-system, sans-serif"
        
        // Per-style spacing (multiplied by font size)
        let pMarginTop = Int(editorFontSize * paragraphSpacingBefore)
        let pMarginBottom = Int(editorFontSize * paragraphSpacingAfter)
        let h1MarginTop = Int(editorFontSize * h1SpacingBefore)
        let h1MarginBottom = Int(editorFontSize * h1SpacingAfter)
        let h2MarginTop = Int(editorFontSize * h2SpacingBefore)
        let h2MarginBottom = Int(editorFontSize * h2SpacingAfter)
        let h3MarginTop = Int(editorFontSize * h3SpacingBefore)
        let h3MarginBottom = Int(editorFontSize * h3SpacingAfter)
        
        // General spacing for other elements (use paragraph after spacing as base)
        let paragraphMargin = editorFontSize * paragraphSpacingAfter
        
        // Background color
        let backgroundColor = isDark ? editorBackgroundColorDark : editorBackgroundColorLight
        let backgroundColorHex = backgroundColor.toHex() ?? (isDark ? "#1e1e1e" : "#ffffff")
        
        return """
        \(colorVars)
        \(typographyVars)
        
        /* Editor Container */
        #editor {
            padding: \(Int(editorPadding))px;
            padding-top: \(Int(editorPadding) + 52)px; /* Extra space for formatting toolbar */
            background-color: \(backgroundColorHex);
        }
        
        /* Base Typography */
        .tiptap {
            max-width: \(Int(editorContentWidth))px;
            margin: 0 auto;
            font-family: \(fontFamily);
            font-size: \(Int(editorFontSize))px;
            line-height: \(editorLineHeight);
            color: var(--writa-editor-text);
            outline: none;
            min-height: 300px;
            background-color: transparent;
        }
        
        /* Paragraphs */
        .tiptap p {
            margin: \(pMarginTop)px 0 \(pMarginBottom)px 0;
            line-height: \(editorLineHeight);
        }
        
        .tiptap p:first-child {
            margin-top: 0;
        }
        
        .tiptap p:last-child {
            margin-bottom: 0;
        }
        
        /* Ensure consistent line-height for all inline content */
        .tiptap p *, .tiptap li * {
            line-height: inherit;
        }
        
        /* Headings */
        .tiptap h1 {
            font-size: \(Int(editorFontSize * 2))px;
            font-weight: 700;
            line-height: 1.2;
            margin: \(h1MarginTop)px 0 \(h1MarginBottom)px 0;
            color: var(--writa-text-primary);
        }
        
        .tiptap h1:first-child {
            margin-top: 0;
        }
        
        .tiptap h2 {
            font-size: \(Int(editorFontSize * 1.5))px;
            font-weight: 600;
            line-height: 1.3;
            margin: \(h2MarginTop)px 0 \(h2MarginBottom)px 0;
            color: var(--writa-text-primary);
        }
        
        .tiptap h2:first-child {
            margin-top: 0;
        }
        
        .tiptap h3 {
            font-size: \(Int(editorFontSize * 1.25))px;
            font-weight: 600;
            line-height: 1.35;
            margin: \(h3MarginTop)px 0 \(h3MarginBottom)px 0;
            color: var(--writa-text-primary);
        }
        
        .tiptap h3:first-child {
            margin-top: 0;
        }
        
        /* Text Formatting */
        .tiptap strong { font-weight: 600; }
        .tiptap em { font-style: italic; }
        .tiptap u { text-decoration: underline; }
        .tiptap s { text-decoration: line-through; color: var(--writa-text-secondary); }
        /* Highlight colors - brighter in dark mode for readability */
        .tiptap mark { 
            padding: 0.1em 0.2em;
            border-radius: 2px;
        }
        
        \(isDark ? """
        /* Dark mode highlights - balanced opacity (0.4) with white text for readability */
        /* TipTap applies colors as inline styles, so we override for better visibility */
        .tiptap mark[style*="#fef08a"],
        .tiptap mark[style*="#FEF08A"],
        .tiptap mark[data-color="#fef08a"],
        .tiptap mark[data-color="#FEF08A"] {
            background-color: rgba(254, 240, 138, 0.4) !important;
            color: var(--writa-text-primary) !important;
        }
        .tiptap mark[style*="#86efac"],
        .tiptap mark[style*="#86EFAC"],
        .tiptap mark[data-color="#86efac"],
        .tiptap mark[data-color="#86EFAC"] {
            background-color: rgba(134, 239, 172, 0.4) !important;
            color: var(--writa-text-primary) !important;
        }
        .tiptap mark[style*="#93c5fd"],
        .tiptap mark[style*="#93C5FD"],
        .tiptap mark[data-color="#93c5fd"],
        .tiptap mark[data-color="#93C5FD"] {
            background-color: rgba(147, 197, 253, 0.4) !important;
            color: var(--writa-text-primary) !important;
        }
        .tiptap mark[style*="#f9a8d4"],
        .tiptap mark[style*="#F9A8D4"],
        .tiptap mark[data-color="#f9a8d4"],
        .tiptap mark[data-color="#F9A8D4"] {
            background-color: rgba(249, 168, 212, 0.4) !important;
            color: var(--writa-text-primary) !important;
        }
        .tiptap mark[style*="#fdba74"],
        .tiptap mark[style*="#FDBA74"],
        .tiptap mark[data-color="#fdba74"],
        .tiptap mark[data-color="#FDBA74"] {
            background-color: rgba(253, 186, 116, 0.4) !important;
            color: var(--writa-text-primary) !important;
        }
        .tiptap mark[style*="#c4b5fd"],
        .tiptap mark[style*="#C4B5FD"],
        .tiptap mark[data-color="#c4b5fd"],
        .tiptap mark[data-color="#C4B5FD"] {
            background-color: rgba(196, 181, 253, 0.4) !important;
            color: var(--writa-text-primary) !important;
        }
        /* Default for any other highlight color in dark mode */
        .tiptap mark {
            background-color: rgba(254, 240, 138, 0.4) !important;
            color: var(--writa-text-primary) !important;
        }
        """ : """
        /* Light mode highlights - standard opacity */
        .tiptap mark {
            background-color: rgba(254, 240, 138, 0.8);
        }
        """)
        
        /* Inline Code */
        .tiptap code {
            font-family: 'SF Mono', ui-monospace, monospace;
            font-size: 0.9em;
            background: \(isDark ? "rgba(255,255,255,0.1)" : "rgba(0,0,0,0.05)");
            padding: 0.15em 0.4em;
            border-radius: 4px;
        }
        
        /* Code Blocks */
        .tiptap pre {
            font-family: 'SF Mono', ui-monospace, monospace;
            font-size: \(Int(editorFontSize - 2))px;
            line-height: 1.5;
            background: \(isDark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.04)");
            border-radius: 8px;
            padding: 16px;
            margin: \(Int(paragraphMargin))px 0;
            overflow-x: auto;
        }
        
        .tiptap pre code {
            background: none;
            padding: 0;
            font-size: inherit;
        }
        
        /* Lists */
        .tiptap ul, .tiptap ol {
            padding-left: 24px;
            margin: \(Int(paragraphMargin))px 0;
        }
        
        .tiptap li {
            margin-bottom: \(Int(paragraphMargin * 0.3))px;
            line-height: \(editorLineHeight);
        }
        
        .tiptap li p {
            margin: 0;
        }
        
        /* Task Lists */
        .tiptap ul[data-type="taskList"] {
            list-style: none;
            padding-left: 0;
        }
        
        .tiptap ul[data-type="taskList"] li {
            display: flex;
            align-items: flex-start;
            gap: 8px;
        }
        
        .tiptap ul[data-type="taskList"] input[type="checkbox"] {
            margin-top: 4px;
            cursor: pointer;
            accent-color: var(--writa-accent);
        }
        
        .tiptap ul[data-type="taskList"] li[data-checked="true"] > div {
            text-decoration: line-through;
            color: var(--writa-text-tertiary);
        }
        
        /* Blockquotes */
        .tiptap blockquote {
            border-left: 3px solid var(--writa-accent);
            padding-left: 16px;
            margin: \(Int(paragraphMargin))px 0;
            color: var(--writa-text-secondary);
            font-style: italic;
        }
        
        .tiptap blockquote p {
            margin: 0;
        }
        
        /* Links */
        .tiptap a {
            color: var(--writa-accent);
            text-decoration: none;
            cursor: pointer;
        }
        
        .tiptap a:hover {
            text-decoration: underline;
        }
        
        /* Images */
        .tiptap img {
            max-width: 100%;
            height: auto;
            border-radius: 8px;
            margin: \(Int(paragraphMargin))px 0;
            display: block;
        }
        
        .tiptap img.ProseMirror-selectednode {
            outline: 2px solid var(--writa-accent);
            outline-offset: 2px;
        }
        
        /* Horizontal Rule */
        .tiptap hr {
            border: none;
            border-top: 1px solid \(isDark ? "rgba(255,255,255,0.15)" : "rgba(0,0,0,0.1)");
            margin: \(Int(paragraphMargin * 2))px 0;
        }
        
        /* Tables */
        .tiptap table {
            border-collapse: collapse;
            table-layout: fixed;
            width: 100%;
            margin: \(Int(paragraphMargin))px 0;
        }
        
        .tiptap td, .tiptap th {
            border: 1px solid \(isDark ? "rgba(255,255,255,0.15)" : "rgba(0,0,0,0.1)");
            padding: 8px 12px;
            vertical-align: top;
        }
        
        .tiptap th {
            font-weight: 600;
            background: \(isDark ? "rgba(255,255,255,0.05)" : "rgba(0,0,0,0.03)");
        }
        
        /* Selection */
        .tiptap ::selection {
            background: var(--writa-editor-selection);
        }
        
        /* Placeholder */
        .tiptap p.is-editor-empty:first-child::before {
            content: attr(data-placeholder);
            float: left;
            color: var(--writa-text-tertiary);
            pointer-events: none;
            height: 0;
        }
        
        /* Text Alignment */
        .tiptap .text-left { text-align: left; }
        .tiptap .text-center { text-align: center; }
        .tiptap .text-right { text-align: right; }
        .tiptap .text-justify { text-align: justify; }
        
        /* Sub/Superscript */
        .tiptap sub { vertical-align: sub; font-size: 0.8em; }
        .tiptap sup { vertical-align: super; font-size: 0.8em; }
        """
    }
    
    // MARK: - Persistence
    
    private func persistSettings() {
        editorSettingsVersion += 1  // Trigger observers
        
        UserDefaults.standard.set(mode.rawValue, forKey: "theme.mode")
        UserDefaults.standard.set(preset.rawValue, forKey: "theme.preset")
        UserDefaults.standard.set(editorFontFamily, forKey: "theme.editorFontFamily")
        UserDefaults.standard.set(editorFontSize, forKey: "theme.editorFontSize")
        UserDefaults.standard.set(editorLineHeight, forKey: "theme.editorLineHeight")
        
        // Per-style spacing
        UserDefaults.standard.set(paragraphSpacingBefore, forKey: "theme.paragraphSpacingBefore")
        UserDefaults.standard.set(paragraphSpacingAfter, forKey: "theme.paragraphSpacingAfter")
        UserDefaults.standard.set(h1SpacingBefore, forKey: "theme.h1SpacingBefore")
        UserDefaults.standard.set(h1SpacingAfter, forKey: "theme.h1SpacingAfter")
        UserDefaults.standard.set(h2SpacingBefore, forKey: "theme.h2SpacingBefore")
        UserDefaults.standard.set(h2SpacingAfter, forKey: "theme.h2SpacingAfter")
        UserDefaults.standard.set(h3SpacingBefore, forKey: "theme.h3SpacingBefore")
        UserDefaults.standard.set(h3SpacingAfter, forKey: "theme.h3SpacingAfter")
        
        // Background colors - always save explicitly
        let lightHex = editorBackgroundColorLight.toHex() ?? "#ffffff"
        let darkHex = editorBackgroundColorDark.toHex() ?? "#1e1e1e"
        UserDefaults.standard.set(lightHex, forKey: "theme.editorBackgroundColorLight")
        UserDefaults.standard.set(darkHex, forKey: "theme.editorBackgroundColorDark")
        
        UserDefaults.standard.set(editorContentWidth, forKey: "theme.editorContentWidth")
        UserDefaults.standard.set(editorPadding, forKey: "theme.editorPadding")
        UserDefaults.standard.set(useSystemAccent, forKey: "theme.useSystemAccent")
    }
    
    private func loadSettings() {
        if let modeString = UserDefaults.standard.string(forKey: "theme.mode"),
           let mode = ThemeMode(rawValue: modeString) {
            self.mode = mode
        }
        
        // Load preset without triggering applyPreset (to avoid overwriting loaded colors)
        if let presetString = UserDefaults.standard.string(forKey: "theme.preset"),
           let preset = ThemePreset(rawValue: presetString) {
            // Set preset - isLoadingSettings flag prevents applyPreset from running
            self.preset = preset
        }
        
        if let fontFamily = UserDefaults.standard.string(forKey: "theme.editorFontFamily") {
            self.editorFontFamily = fontFamily
        }
        
        let fontSize = UserDefaults.standard.double(forKey: "theme.editorFontSize")
        if fontSize > 0 {
            self.editorFontSize = fontSize
        }
        
        let lineHeight = UserDefaults.standard.double(forKey: "theme.editorLineHeight")
        if lineHeight > 0 {
            self.editorLineHeight = lineHeight
        }
        
        // Per-style spacing (check for existence since 0 is valid)
        if UserDefaults.standard.object(forKey: "theme.paragraphSpacingBefore") != nil {
            self.paragraphSpacingBefore = UserDefaults.standard.double(forKey: "theme.paragraphSpacingBefore")
        }
        if UserDefaults.standard.object(forKey: "theme.paragraphSpacingAfter") != nil {
            self.paragraphSpacingAfter = UserDefaults.standard.double(forKey: "theme.paragraphSpacingAfter")
        }
        if UserDefaults.standard.object(forKey: "theme.h1SpacingBefore") != nil {
            self.h1SpacingBefore = UserDefaults.standard.double(forKey: "theme.h1SpacingBefore")
        }
        if UserDefaults.standard.object(forKey: "theme.h1SpacingAfter") != nil {
            self.h1SpacingAfter = UserDefaults.standard.double(forKey: "theme.h1SpacingAfter")
        }
        if UserDefaults.standard.object(forKey: "theme.h2SpacingBefore") != nil {
            self.h2SpacingBefore = UserDefaults.standard.double(forKey: "theme.h2SpacingBefore")
        }
        if UserDefaults.standard.object(forKey: "theme.h2SpacingAfter") != nil {
            self.h2SpacingAfter = UserDefaults.standard.double(forKey: "theme.h2SpacingAfter")
        }
        if UserDefaults.standard.object(forKey: "theme.h3SpacingBefore") != nil {
            self.h3SpacingBefore = UserDefaults.standard.double(forKey: "theme.h3SpacingBefore")
        }
        if UserDefaults.standard.object(forKey: "theme.h3SpacingAfter") != nil {
            self.h3SpacingAfter = UserDefaults.standard.double(forKey: "theme.h3SpacingAfter")
        }
        
        // Background colors - load independently, always load if key exists
        // Load light mode color
        if let lightHex = UserDefaults.standard.string(forKey: "theme.editorBackgroundColorLight"),
           !lightHex.isEmpty {
            if let lightColor = Color(hex: lightHex) {
                self.editorBackgroundColorLight = lightColor
            } else {
                print("⚠️ Failed to parse light background color: \(lightHex), using default white")
                self.editorBackgroundColorLight = Color(hex: "#ffffff") ?? .white
            }
        } else {
            // No saved value - ensure default is white
            self.editorBackgroundColorLight = Color(hex: "#ffffff") ?? .white
        }
        
        // Load dark mode color
        if let darkHex = UserDefaults.standard.string(forKey: "theme.editorBackgroundColorDark"),
           !darkHex.isEmpty {
            if let darkColor = Color(hex: darkHex) {
                self.editorBackgroundColorDark = darkColor
            } else {
                print("⚠️ Failed to parse dark background color: \(darkHex), using default dark gray")
                self.editorBackgroundColorDark = Color(hex: "#1e1e1e") ?? Color(white: 0.12)
            }
        } else {
            // No saved value - ensure default is dark gray
            self.editorBackgroundColorDark = Color(hex: "#1e1e1e") ?? Color(white: 0.12)
        }
        
        let contentWidth = UserDefaults.standard.double(forKey: "theme.editorContentWidth")
        if contentWidth > 0 {
            self.editorContentWidth = contentWidth
        }
        
        let padding = UserDefaults.standard.double(forKey: "theme.editorPadding")
        if padding > 0 {
            self.editorPadding = padding
        }
        
        self.useSystemAccent = UserDefaults.standard.bool(forKey: "theme.useSystemAccent")
    }
}

// MARK: - Environment Key

private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    func themed(_ manager: ThemeManager) -> some View {
        self
            .environment(\.themeManager, manager)
            .preferredColorScheme(manager.mode.colorScheme)
    }
}
