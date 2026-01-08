//
//  DesignTokens.swift
//  Writa
//
//  Central design token definitions for the theming system.
//  These tokens define the visual language of the app.
//

import SwiftUI

// MARK: - Design Tokens Container

struct DesignTokens {
    var colors: ColorTokens
    var typography: TypographyTokens
    var spacing: SpacingTokens
    var radius: RadiusTokens
    var shadows: ShadowTokens
    
    static let `default` = DesignTokens(
        colors: .default,
        typography: .default,
        spacing: .default,
        radius: .default,
        shadows: .default
    )
}

// MARK: - Spacing Tokens (4pt Grid)

struct SpacingTokens {
    let xxs: CGFloat   // 2
    let xs: CGFloat    // 4
    let sm: CGFloat    // 8
    let md: CGFloat    // 12
    let lg: CGFloat    // 16
    let xl: CGFloat    // 24
    let xxl: CGFloat   // 32
    let xxxl: CGFloat  // 48
    
    static let `default` = SpacingTokens(
        xxs: 2,
        xs: 4,
        sm: 8,
        md: 12,
        lg: 16,
        xl: 24,
        xxl: 32,
        xxxl: 48
    )
}

// MARK: - Radius Tokens

struct RadiusTokens {
    let none: CGFloat
    let sm: CGFloat
    let md: CGFloat
    let lg: CGFloat
    let xl: CGFloat
    let full: CGFloat
    
    static let `default` = RadiusTokens(
        none: 0,
        sm: 4,
        md: 8,
        lg: 12,
        xl: 16,
        full: 9999
    )
}

// MARK: - Shadow Tokens

struct ShadowTokens {
    let sm: ShadowStyle
    let md: ShadowStyle
    let lg: ShadowStyle
    
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    static let `default` = ShadowTokens(
        sm: ShadowStyle(color: .black.opacity(0.05), radius: 2, x: 0, y: 1),
        md: ShadowStyle(color: .black.opacity(0.1), radius: 4, x: 0, y: 2),
        lg: ShadowStyle(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    )
}

// MARK: - View Modifier Extensions

extension View {
    func shadow(_ style: ShadowTokens.ShadowStyle) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
