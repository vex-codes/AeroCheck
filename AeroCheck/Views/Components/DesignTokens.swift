//
//  DesignTokens.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// AAA Aviation Tactical Design System inspired by ForeFlight, DJI Fly, and Apple HIG:
/// - True OLED pure black canvas (#000000) for cockpit and night-flight visibility.
/// - Apple secondary system surfaces (#1C1C1E) and tertiary cell backgrounds (#2C2C2E).
/// - High-contrast functional aviation signal colors (System Green #34C759, Aviation Amber #FF9500, Alert Red #FF3B30).
/// - Tactical precision accent (#0A84FF).
/// - 0.5pt subtle hairline borders matching native Apple separators (#38383A).
public enum DesignTokens {
    // MARK: - OLED Cockpit Neutral Palette
    public static let surfacePrimary = Color(hex: "000000")           // True OLED Black
    public static let surfaceSecondary = Color(hex: "1C1C1E")         // Apple Dark Mode Card Surface
    public static let surfaceTertiary = Color(hex: "2C2C2E")          // Inset Cell / Telemetry Block
    public static let surfaceElevated = Color(hex: "3A3A3C")          // Interactive Pill / Secondary Hover
    public static let borderHairline = Color(hex: "38383A")           // 0.5pt Native Separator Line

    // MARK: - Tactical Functional Colors (Strictly for flight data status)
    public static let statusSafe = Color(hex: "34C759")               // Aviation Signal Green
    public static let statusSafeMuted = Color(hex: "34C759").opacity(0.14)
    public static let statusCaution = Color(hex: "FF9500")            // Intentional Warning Amber
    public static let statusCautionMuted = Color(hex: "FF9500").opacity(0.14)
    public static let statusAlert = Color(hex: "FF3B30")              // Regulatory Prohibited Crimson
    public static let statusAlertMuted = Color(hex: "FF3B30").opacity(0.14)

    // MARK: - Precision Brand Accent
    public static let accent = Color(hex: "0A84FF")                   // Tactical Precision Blue
    public static let accentMuted = Color(hex: "0A84FF").opacity(0.16)

    // MARK: - Typography Roles
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "8E8E93")           // Apple system secondaryLabel
    public static let textTertiary = Color(hex: "636366")            // Apple system tertiaryLabel
    // MARK: - Layout Rhythm (8pt Mathematical Grid)
    public static let space4: CGFloat = 4.0
    public static let space6: CGFloat = 6.0
    public static let space8: CGFloat = 8.0
    public static let space10: CGFloat = 10.0
    public static let space12: CGFloat = 12.0
    public static let space16: CGFloat = 16.0
    public static let space20: CGFloat = 20.0
    public static let space24: CGFloat = 24.0
    public static let space32: CGFloat = 32.0

    // MARK: - Curvatures
    public static let radiusInner: CGFloat = 10.0
    public static let radiusCard: CGFloat = 16.0
    public static let radiusPill: CGFloat = 999.0
}

// MARK: - Tactile Micro-Interaction Button Style

public struct InteractivePressButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.snappy(duration: 0.15, extraBounce: 0), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InteractivePressButtonStyle {
    public static var interactivePress: InteractivePressButtonStyle {
        InteractivePressButtonStyle()
    }
}

// MARK: - Color Hex Parser

extension Color {
    public init(hex: String) {
        let hexCleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hexCleaned).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hexCleaned.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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
