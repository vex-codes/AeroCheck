//
//  VerdictBannerView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Primary Go / Caution / No-Go verdict banner adhering to Apple Human Interface Guidelines:
/// - Semantic typography (Title, Headline, Subheadline, Footnote)
/// - Restrained status color accents with calm surfaces
/// - Flat surface with precise hairline borders
/// - Strict 8pt spatial rhythm and minimum 44x44pt tap target
public struct VerdictBannerView: View {
    public let result: RiskAssessmentResult?
    public let isLoading: Bool

    @State private var isExpanded: Bool = false

    public init(result: RiskAssessmentResult?, isLoading: Bool) {
        self.result = result
        self.isLoading = isLoading
    }

    private var statusColor: Color {
        guard let res = result else { return DesignTokens.accent }
        switch res.overallVerdict {
        case .safe: return DesignTokens.statusSafe
        case .caution: return DesignTokens.statusCaution
        case .noGo: return DesignTokens.statusAlert
        }
    }

    private var statusBadgeMuted: Color {
        guard let res = result else { return DesignTokens.accentMuted }
        switch res.overallVerdict {
        case .safe: return DesignTokens.statusSafeMuted
        case .caution: return DesignTokens.statusCautionMuted
        case .noGo: return DesignTokens.statusAlertMuted
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space12) {
            // Header Bar
            HStack(alignment: .center, spacing: DesignTokens.space12) {
                // Status Indicator Pill
                HStack(spacing: DesignTokens.space8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)

                    Text(isLoading ? "EVALUATING" : (result?.overallVerdict.rawValue ?? "STANDBY"))
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, DesignTokens.space8)
                .padding(.vertical, DesignTokens.space4)
                .background(
                    Capsule()
                        .fill(statusBadgeMuted)
                )

                Spacer()

                if let factors = result?.factors, !factors.isEmpty {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: DesignTokens.space4) {
                            Text(isExpanded ? "Hide Details" : "View Factors (\(factors.count))")
                                .font(.footnote.weight(.medium))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(DesignTokens.accent)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.interactivePress)
                }
            }

            // Headline
            Text(isLoading ? "Analyzing Airspace & Atmospheric Soundings" : (result?.primaryHeadline ?? "Awaiting Telemetry"))
                .font(.title3.weight(.bold))
                .foregroundStyle(DesignTokens.textPrimary)

            // Rationale Copy
            if let rationale = result?.detailedRationale {
                Text(rationale)
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineSpacing(2)
            }

            // Expandable Regulatory RAM Factor Breakdown
            if isExpanded, let factors = result?.factors {
                VStack(alignment: .leading, spacing: DesignTokens.space8) {
                    Divider()
                        .background(DesignTokens.borderHairline)
                        .padding(.vertical, DesignTokens.space4)

                    Text("RISK ASSESSMENT MATRIX BREAKDOWN")
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)

                    ForEach(factors) { factor in
                        HStack(alignment: .top, spacing: DesignTokens.space8) {
                            Circle()
                                .fill(colorForVerdict(factor.severity))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack {
                                    Text(factor.category.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DesignTokens.textPrimary)

                                    Spacer()

                                    Text(factor.regulatoryReference)
                                        .font(.caption.weight(.medium).monospaced())
                                        .foregroundStyle(DesignTokens.textTertiary)
                                }

                                Text(factor.summary)
                                    .font(.footnote)
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
        .padding(DesignTokens.space16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                .fill(DesignTokens.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                        .stroke(DesignTokens.borderHairline, lineWidth: 1)
                )
        )
    }

    private func colorForVerdict(_ verdict: RiskVerdict) -> Color {
        switch verdict {
        case .safe: return DesignTokens.statusSafe
        case .caution: return DesignTokens.statusCaution
        case .noGo: return DesignTokens.statusAlert
        }
    }
}
