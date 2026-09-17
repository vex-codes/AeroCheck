//
//  DesignTokens.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Semantic design tokens adhering to strict Apple Human Interface Guidelines:
/// 1. Typography via iOS semantic text styles (Large Title, Title, Headline, Body, Footnote, Caption).
/// 2. Color defined by role (surfaces, borders, text, single interactive accent).
/// 3. Strict single depth policy: Flat surfaces with precise 1pt/0.5pt hairline borders.
/// 4. 4pt/8pt mathematical rhythm and 44x44pt minimum tap targets.
/// 5. Native micro-interactions and tactile feedback.
public enum DesignTokens {
    // MARK: - Color by Role
    public static let surfacePrimary = Color(hex: "090D12")           // Root background
    public static let surfaceSecondary = Color(hex: "121820")         // Card container
    public static let surfaceTertiary = Color(hex: "18212B")          // Inset cell / sub-container
    public static let borderHairline = Color(hex: "222C38")           // Precise separator border

    // Single cohesive interactive accent (aviation cobalt)
    public static let accent = Color(hex: "0284C7")
    public static let accentMuted = Color(hex: "0284C7").opacity(0.14)

    // Semantic text hierarchy
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "94A3B8")
    public static let textTertiary = Color(hex: "64748B")

    // Telemetry Status (Reserved strictly for regulatory data alerts, NOT brand accents)
    public static let statusSafe = Color(hex: "16A34A")
    public static let statusSafeMuted = Color(hex: "16A34A").opacity(0.12)
    public static let statusCaution = Color(hex: "D97706")
    public static let statusCautionMuted = Color(hex: "D97706").opacity(0.12)
    public static let statusAlert = Color(hex: "DC2626")
    public static let statusAlertMuted = Color(hex: "DC2626").opacity(0.12)

    // Legacy mapping aliases to preserve safety
    public static let canvasBackground = surfacePrimary
    public static let cardBackground = surfaceSecondary
    public static let cardBackgroundSecondary = surfaceTertiary
    public static let cardBorder = borderHairline
    public static let verdictSafe = statusSafe
    public static let verdictCaution = statusCaution
    public static let verdictNoGo = statusAlert
    public static let aeroBlue = accent
    public static let skyBlue = accent
    public static let textMuted = textTertiary

    // MARK: - Spacing & Rhythm (Strict 4pt / 8pt Grid)
    public static let space4: CGFloat = 4.0
    public static let space8: CGFloat = 8.0
    public static let space12: CGFloat = 12.0
    public static let space16: CGFloat = 16.0
    public static let space20: CGFloat = 20.0
    public static let space24: CGFloat = 24.0
    public static let space32: CGFloat = 32.0

    // Legacy aliases
    public static let spaceXS = space4
    public static let spaceS = space8
    public static let spaceM = space16
    public static let spaceL = space24
    public static let spaceXL = space32
    public static let spaceXXL: CGFloat = 48.0

    // MARK: - Consistent Corner Radii (Continuous curves)
    public static let radiusInner: CGFloat = 8.0
    public static let radiusCard: CGFloat = 12.0
    public static let radiusPill: CGFloat = 999.0

    public static let radiusS = radiusInner
    public static let radiusM = radiusCard
    public static let radiusL: CGFloat = 16.0
}

// MARK: - Micro-Interaction Button Style

public struct InteractivePressButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == InteractivePressButtonStyle {
    public static var interactivePress: InteractivePressButtonStyle {
        InteractivePressButtonStyle()
    }
}

// MARK: - Color Hex Initializer

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
