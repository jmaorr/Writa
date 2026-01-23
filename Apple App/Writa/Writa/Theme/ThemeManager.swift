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
    
    var mode: ThemeMode = .system {
        didSet { persistSettings() }
    }
    
    var preset: ThemePreset = .apple {
        didSet {
            applyPreset()
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
    
    var editorLineHeight: CGFloat = 1.6 {
        didSet {
            updateEditorTypography()
            persistSettings()
        }
    }
    
    var editorParagraphSpacing: CGFloat = 1.0 {
        didSet { persistSettings() }
    }
    
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
        loadSettings()
    }
    
    // MARK: - Preset Application
    
    private func applyPreset() {
        switch preset {
        case .apple:
            tokens = .default
            editorFontFamily = ".AppleSystemUIFont"
            editorFontSize = 16
            editorLineHeight = 1.6
            editorParagraphSpacing = 1.0
            editorContentWidth = 720
            editorPadding = 32
            
        case .minimal:
            tokens = .default
            editorFontFamily = ".AppleSystemUIFont"
            editorFontSize = 15
            editorLineHeight = 1.7
            editorParagraphSpacing = 0.8
            editorContentWidth = 640
            editorPadding = 48
            
        case .editorial:
            tokens = .default
            editorFontFamily = "New York"  // Apple's serif font
            editorFontSize = 18
            editorLineHeight = 1.8
            editorParagraphSpacing = 1.2
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
        let colorVars = tokens.colors.toCSSVariables()
        let typographyVars = tokens.typography.toCSSVariables()
        
        // Computed values for editor
        let fontFamily = editorFontFamily == ".AppleSystemUIFont" 
            ? "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif" 
            : "'\(editorFontFamily)', -apple-system, sans-serif"
        let paragraphMargin = editorFontSize * editorParagraphSpacing
        let headingMarginTop = editorFontSize * 1.5
        let headingMarginBottom = editorFontSize * 0.5
        
        return """
        \(colorVars)
        \(typographyVars)
        
        /* Editor Container */
        #editor {
            padding: \(Int(editorPadding))px;
            padding-top: \(Int(editorPadding) + 52)px; /* Extra space for formatting toolbar */
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
        }
        
        /* Paragraphs */
        .tiptap p {
            margin: 0 0 \(Int(paragraphMargin))px 0;
        }
        
        .tiptap p:last-child {
            margin-bottom: 0;
        }
        
        /* Headings */
        .tiptap h1 {
            font-size: \(Int(editorFontSize * 2))px;
            font-weight: 700;
            line-height: 1.2;
            margin: \(Int(headingMarginTop))px 0 \(Int(headingMarginBottom))px 0;
            color: var(--writa-text-primary);
        }
        
        .tiptap h1:first-child {
            margin-top: 0;
        }
        
        .tiptap h2 {
            font-size: \(Int(editorFontSize * 1.5))px;
            font-weight: 600;
            line-height: 1.3;
            margin: \(Int(headingMarginTop))px 0 \(Int(headingMarginBottom))px 0;
            color: var(--writa-text-primary);
        }
        
        .tiptap h3 {
            font-size: \(Int(editorFontSize * 1.25))px;
            font-weight: 600;
            line-height: 1.35;
            margin: \(Int(headingMarginTop * 0.8))px 0 \(Int(headingMarginBottom))px 0;
            color: var(--writa-text-primary);
        }
        
        /* Text Formatting */
        .tiptap strong { font-weight: 600; }
        .tiptap em { font-style: italic; }
        .tiptap u { text-decoration: underline; }
        .tiptap s { text-decoration: line-through; color: var(--writa-text-secondary); }
        .tiptap mark { 
            background-color: \(isDark ? "rgba(254, 240, 138, 0.3)" : "rgba(254, 240, 138, 0.8)");
            padding: 0.1em 0.2em;
            border-radius: 2px;
        }
        
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
        UserDefaults.standard.set(mode.rawValue, forKey: "theme.mode")
        UserDefaults.standard.set(preset.rawValue, forKey: "theme.preset")
        UserDefaults.standard.set(editorFontFamily, forKey: "theme.editorFontFamily")
        UserDefaults.standard.set(editorFontSize, forKey: "theme.editorFontSize")
        UserDefaults.standard.set(editorLineHeight, forKey: "theme.editorLineHeight")
        UserDefaults.standard.set(editorParagraphSpacing, forKey: "theme.editorParagraphSpacing")
        UserDefaults.standard.set(editorContentWidth, forKey: "theme.editorContentWidth")
        UserDefaults.standard.set(editorPadding, forKey: "theme.editorPadding")
        UserDefaults.standard.set(useSystemAccent, forKey: "theme.useSystemAccent")
    }
    
    private func loadSettings() {
        if let modeString = UserDefaults.standard.string(forKey: "theme.mode"),
           let mode = ThemeMode(rawValue: modeString) {
            self.mode = mode
        }
        
        if let presetString = UserDefaults.standard.string(forKey: "theme.preset"),
           let preset = ThemePreset(rawValue: presetString) {
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
        
        let paragraphSpacing = UserDefaults.standard.double(forKey: "theme.editorParagraphSpacing")
        if paragraphSpacing > 0 {
            self.editorParagraphSpacing = paragraphSpacing
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
