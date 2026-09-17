//
//  DesignTokens.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Standardized design tokens adhering to 8pt grid, dark aviation aesthetic, and anti-slop guidelines.
public enum DesignTokens {
    // MARK: - Color Palette (Dark Aviation System)
    public static let canvasBackground = Color(hex: "0A0E14")      // Deep aeronautical cockpit black
    public static let cardBackground = Color(hex: "121820")        // High contrast slate card
    public static let cardBackgroundSecondary = Color(hex: "1A232E")
    public static let cardBorder = Color(hex: "233040")            // Subtle metallic border

    // Semantic Status Accents
    public static let verdictSafe = Color(hex: "22C55E")           // Aviation Emerald Green
    public static let verdictCaution = Color(hex: "F59E0B")        // Aviation Amber Caution
    public static let verdictNoGo = Color(hex: "EF4444")           // Aviation Red Alert
    public static let aeroBlue = Color(hex: "38BDF8")              // Flight telemetry cyan
    public static let skyBlue = Color(hex: "0284C7")

    // Typography Neutral Tones
    public static let textPrimary = Color(hex: "F1F5F9")           // Bright white/silver
    public static let textSecondary = Color(hex: "94A3B8")         // Neutral slate gray
    public static let textMuted = Color(hex: "64748B")             // Dark slate

    // MARK: - Spacing Tokens (8pt Grid)
    public static let spaceXS: CGFloat = 4.0
    public static let spaceS: CGFloat = 8.0
    public static let spaceM: CGFloat = 16.0
    public static let spaceL: CGFloat = 24.0
    public static let spaceXL: CGFloat = 32.0
    public static let spaceXXL: CGFloat = 48.0

    // MARK: - Corner Radii
    public static let radiusS: CGFloat = 8.0
    public static let radiusM: CGFloat = 14.0
    public static let radiusL: CGFloat = 20.0
    public static let radiusPill: CGFloat = 999.0
}

// MARK: - Color Hex Initializer

extension Color {
    public init(hex: String) {
        let hexCleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexCleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexCleaned.count {
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
