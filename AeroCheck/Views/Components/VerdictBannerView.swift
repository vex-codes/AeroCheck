//
//  VerdictBannerView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Primary Go / Caution / No-Go Verdict Banner presenting operational clearance and safety rationale.
public struct VerdictBannerView: View {
    public let result: RiskAssessmentResult?
    public let isLoading: Bool

    @State private var isExpanded: Bool = false

    public init(result: RiskAssessmentResult?, isLoading: Bool) {
        self.result = result
        self.isLoading = isLoading
    }

    private var verdictColor: Color {
        guard let res = result else { return DesignTokens.aeroBlue }
        switch res.overallVerdict {
        case .safe: return DesignTokens.verdictSafe
        case .caution: return DesignTokens.verdictCaution
        case .noGo: return DesignTokens.verdictNoGo
        }
    }

    private var statusIcon: String {
        guard let res = result else { return "antenna.radiowaves.left.and.right" }
        return res.overallVerdict.systemIcon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spaceM) {
            HStack(spacing: DesignTokens.spaceM) {
                // Status Icon Badge with dynamic pulse
                ZStack {
                    Circle()
                        .fill(verdictColor.opacity(0.18))
                        .frame(width: 48, height: 48)

                    Image(systemName: isLoading ? "arrow.triangle.2.circlepath" : statusIcon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(verdictColor)
                        .symbolEffect(.pulse, isActive: isLoading)
                }

                VStack(alignment: .leading, spacing: DesignTokens.spaceXS) {
                    Text(isLoading ? "EVALUATING AIRSPACE & WEATHER..." : (result?.overallVerdict.title ?? "SYSTEM READY"))
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .foregroundStyle(verdictColor)
                        .kerning(1.2)

                    Text(isLoading ? "Syncing FAA ArcGIS & NOAA Data" : (result?.primaryHeadline ?? "Awaiting Telemetry"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                }

                Spacer()

                if let factors = result?.factors, !factors.isEmpty {
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(DesignTokens.textSecondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Summary Rationale
            if let rationale = result?.detailedRationale {
                Text(rationale)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineSpacing(3)
            }

            // Detailed Factors Accordion
            if isExpanded, let factors = result?.factors {
                Divider()
                    .overlay(DesignTokens.cardBorder)

                VStack(alignment: .leading, spacing: DesignTokens.spaceS) {
                    Text("RAM COMPLIANCE BREAKDOWN")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)

                    ForEach(factors) { factor in
                        HStack(alignment: .top, spacing: DesignTokens.spaceS) {
                            Circle()
                                .fill(colorForFactor(factor.severity))
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(factor.category.rawValue)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(DesignTokens.textPrimary)

                                    Spacer()

                                    Text(factor.regulatoryReference)
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundStyle(DesignTokens.textMuted)
                                }

                                Text(factor.summary)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundStyle(DesignTokens.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(DesignTokens.spaceM)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                .fill(DesignTokens.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                        .stroke(verdictColor.opacity(0.35), lineWidth: 1.2)
                )
        )
    }

    private func colorForFactor(_ severity: RiskVerdict) -> Color {
        switch severity {
        case .safe: return DesignTokens.verdictSafe
        case .caution: return DesignTokens.verdictCaution
        case .noGo: return DesignTokens.verdictNoGo
        }
    }
}
