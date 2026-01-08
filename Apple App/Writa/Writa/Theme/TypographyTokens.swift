//
//  TypographyTokens.swift
//  Writa
//
//  Typography definitions for the theming system.
//  Uses SF Pro by default with semantic text styles.
//

import SwiftUI

// MARK: - Typography Tokens

struct TypographyTokens {
    // MARK: - Font Families
    let primaryFamily: String
    let monoFamily: String
    let editorFamily: String  // Can be customized independently
    
    // MARK: - Text Styles
    let largeTitle: TextStyle
    let title1: TextStyle
    let title2: TextStyle
    let title3: TextStyle
    let headline: TextStyle
    let body: TextStyle
    let callout: TextStyle
    let subheadline: TextStyle
    let footnote: TextStyle
    let caption1: TextStyle
    let caption2: TextStyle
    
    // MARK: - Editor Specific Styles
    let editorBody: TextStyle
    let editorHeading1: TextStyle
    let editorHeading2: TextStyle
    let editorHeading3: TextStyle
    let editorCode: TextStyle
    let editorBlockquote: TextStyle
}

// MARK: - Text Style Definition

struct TextStyle {
    let size: CGFloat
    let weight: Font.Weight
    let lineHeight: CGFloat  // Multiplier
    let letterSpacing: CGFloat
    let family: String?  // nil = use default
    
    var font: Font {
        if let family = family {
            return .custom(family, size: size).weight(weight)
        }
        return .system(size: size, weight: weight)
    }
    
    var nsFont: NSFont {
        if let family = family, let font = NSFont(name: family, size: size) {
            return font
        }
        return NSFont.systemFont(ofSize: size, weight: weight.nsWeight)
    }
}

// MARK: - Font Weight Conversion

extension Font.Weight {
    var nsWeight: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}

// MARK: - Default Typography (SF Pro)

extension TypographyTokens {
    static let `default` = TypographyTokens(
        primaryFamily: ".AppleSystemUIFont",  // SF Pro
        monoFamily: "SF Mono",
        editorFamily: ".AppleSystemUIFont",
        
        // System text styles matching Apple HIG
        largeTitle: TextStyle(size: 34, weight: .bold, lineHeight: 1.2, letterSpacing: 0.37, family: nil),
        title1: TextStyle(size: 28, weight: .bold, lineHeight: 1.2, letterSpacing: 0.36, family: nil),
        title2: TextStyle(size: 22, weight: .bold, lineHeight: 1.25, letterSpacing: 0.35, family: nil),
        title3: TextStyle(size: 20, weight: .semibold, lineHeight: 1.25, letterSpacing: 0.38, family: nil),
        headline: TextStyle(size: 17, weight: .semibold, lineHeight: 1.3, letterSpacing: -0.41, family: nil),
        body: TextStyle(size: 17, weight: .regular, lineHeight: 1.4, letterSpacing: -0.41, family: nil),
        callout: TextStyle(size: 16, weight: .regular, lineHeight: 1.35, letterSpacing: -0.31, family: nil),
        subheadline: TextStyle(size: 15, weight: .regular, lineHeight: 1.35, letterSpacing: -0.24, family: nil),
        footnote: TextStyle(size: 13, weight: .regular, lineHeight: 1.35, letterSpacing: -0.08, family: nil),
        caption1: TextStyle(size: 12, weight: .regular, lineHeight: 1.3, letterSpacing: 0, family: nil),
        caption2: TextStyle(size: 11, weight: .regular, lineHeight: 1.3, letterSpacing: 0.07, family: nil),
        
        // Editor styles
        editorBody: TextStyle(size: 16, weight: .regular, lineHeight: 1.6, letterSpacing: 0, family: nil),
        editorHeading1: TextStyle(size: 32, weight: .bold, lineHeight: 1.3, letterSpacing: -0.5, family: nil),
        editorHeading2: TextStyle(size: 24, weight: .bold, lineHeight: 1.35, letterSpacing: -0.3, family: nil),
        editorHeading3: TextStyle(size: 20, weight: .semibold, lineHeight: 1.4, letterSpacing: -0.2, family: nil),
        editorCode: TextStyle(size: 14, weight: .regular, lineHeight: 1.5, letterSpacing: 0, family: "SF Mono"),
        editorBlockquote: TextStyle(size: 16, weight: .regular, lineHeight: 1.6, letterSpacing: 0, family: nil)
    )
}

// MARK: - CSS Export for Editor Bridge

extension TypographyTokens {
    /// Generates CSS for the embedded Tiptap editor
    func toCSSVariables() -> String {
        """
        :root {
            --writa-font-family: '\(editorFamily)', -apple-system, BlinkMacSystemFont, sans-serif;
            --writa-font-mono: '\(monoFamily)', ui-monospace, monospace;
            
            --writa-font-size-body: \(editorBody.size)px;
            --writa-line-height-body: \(editorBody.lineHeight);
            
            --writa-font-size-h1: \(editorHeading1.size)px;
            --writa-font-weight-h1: \(editorHeading1.weight.cssValue);
            --writa-line-height-h1: \(editorHeading1.lineHeight);
            
            --writa-font-size-h2: \(editorHeading2.size)px;
            --writa-font-weight-h2: \(editorHeading2.weight.cssValue);
            --writa-line-height-h2: \(editorHeading2.lineHeight);
            
            --writa-font-size-h3: \(editorHeading3.size)px;
            --writa-font-weight-h3: \(editorHeading3.weight.cssValue);
            --writa-line-height-h3: \(editorHeading3.lineHeight);
            
            --writa-font-size-code: \(editorCode.size)px;
            --writa-line-height-code: \(editorCode.lineHeight);
        }
        """
    }
}

// MARK: - Font Weight CSS Value

extension Font.Weight {
    var cssValue: Int {
        switch self {
        case .ultraLight: return 100
        case .thin: return 200
        case .light: return 300
        case .regular: return 400
        case .medium: return 500
        case .semibold: return 600
        case .bold: return 700
        case .heavy: return 800
        case .black: return 900
        default: return 400
        }
    }
}
