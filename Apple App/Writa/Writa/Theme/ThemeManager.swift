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
            
        case .minimal:
            tokens = .default
            editorFontFamily = ".AppleSystemUIFont"
            editorFontSize = 15
            editorLineHeight = 1.7
            
        case .editorial:
            tokens = .default
            editorFontFamily = "New York"  // Apple's serif font
            editorFontSize = 18
            editorLineHeight = 1.8
            
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
        let colorVars = tokens.colors.toCSSVariables()
        let typographyVars = tokens.typography.toCSSVariables()
        
        return """
        \(colorVars)
        \(typographyVars)
        
        .tiptap {
            font-family: var(--writa-font-family);
            font-size: var(--writa-font-size-body);
            line-height: var(--writa-line-height-body);
            color: var(--writa-editor-text);
            background: var(--writa-editor-bg);
        }
        
        .tiptap h1 {
            font-size: var(--writa-font-size-h1);
            font-weight: var(--writa-font-weight-h1);
            line-height: var(--writa-line-height-h1);
        }
        
        .tiptap h2 {
            font-size: var(--writa-font-size-h2);
            font-weight: var(--writa-font-weight-h2);
            line-height: var(--writa-line-height-h2);
        }
        
        .tiptap h3 {
            font-size: var(--writa-font-size-h3);
            font-weight: var(--writa-font-weight-h3);
            line-height: var(--writa-line-height-h3);
        }
        
        .tiptap code {
            font-family: var(--writa-font-mono);
            font-size: var(--writa-font-size-code);
        }
        
        .tiptap pre {
            font-family: var(--writa-font-mono);
            font-size: var(--writa-font-size-code);
            line-height: var(--writa-line-height-code);
            background: var(--writa-bg-secondary);
            border-radius: 8px;
            padding: 16px;
        }
        
        .tiptap blockquote {
            border-left: 3px solid var(--writa-accent);
            padding-left: 16px;
            color: var(--writa-text-secondary);
        }
        
        .tiptap ::selection {
            background: var(--writa-editor-selection);
        }
        """
    }
    
    // MARK: - Persistence
    
    private func persistSettings() {
        UserDefaults.standard.set(mode.rawValue, forKey: "theme.mode")
        UserDefaults.standard.set(preset.rawValue, forKey: "theme.preset")
        UserDefaults.standard.set(editorFontFamily, forKey: "theme.editorFontFamily")
        UserDefaults.standard.set(editorFontSize, forKey: "theme.editorFontSize")
        UserDefaults.standard.set(editorLineHeight, forKey: "theme.editorLineHeight")
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
