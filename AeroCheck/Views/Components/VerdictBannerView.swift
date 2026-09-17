//
//  VerdictBannerView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// AAA Master Verdict Banner:
/// - Heavy typography with refined letter tracking.
/// - Crisp functional status colors (Green / Amber / Crimson) against OLED card backdrop.
/// - Sleek 0.5pt subtle separator border with 16pt uniform internal padding.
/// - Clean legal citations with distinct secondaryLabel styling and comfortable line heights.
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

    private var statusBadgeBackground: Color {
        guard let res = result else { return DesignTokens.accentMuted }
        switch res.overallVerdict {
        case .safe: return DesignTokens.statusSafeMuted
        case .caution: return DesignTokens.statusCautionMuted
        case .noGo: return DesignTokens.statusAlertMuted
        }
    }

    private var statusIcon: String {
        guard let res = result else { return "antenna.radiowaves.left.and.right" }
        return res.overallVerdict.systemIcon
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space12) {
            // Tactical Status Pill & Expand Trigger
            HStack(alignment: .center, spacing: DesignTokens.space8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)

                    Text(isLoading ? "EVALUATING" : (result?.overallVerdict.rawValue ?? "READY"))
                        .font(.caption2.weight(.heavy).monospaced())
                        .tracking(0.8)
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(statusBadgeBackground)
                )

                Spacer()

                if let factors = result?.factors, !factors.isEmpty {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Hide Telemetry" : "Telemetry Factors (\(factors.count))")
                                .font(.caption.weight(.medium))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(DesignTokens.textSecondary)
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.interactivePress)
                }
            }

            // Primary Alert Headline
            Text(isLoading ? "Synchronizing FAA & NOAA Telemetry" : (result?.primaryHeadline ?? "Awaiting Telemetry"))
                .font(.title2.weight(.heavy))
                .tracking(-0.3)
                .foregroundStyle(DesignTokens.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            // Rationale Copy
            if let rationale = result?.detailedRationale {
                Text(rationale)
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.textSecondary)
                    .lineSpacing(3)
            }

            // Expandable RAM Compliance Breakdown
            if isExpanded, let factors = result?.factors {
                VStack(alignment: .leading, spacing: DesignTokens.space12) {
                    Divider()
                        .overlay(DesignTokens.borderHairline)
                        .padding(.top, DesignTokens.space4)

                    Text("REGULATORY COMPLIANCE FACTORS")
                        .font(.caption2.weight(.bold).monospaced())
                        .tracking(0.6)
                        .foregroundStyle(DesignTokens.textTertiary)

                    ForEach(factors) { factor in
                        HStack(alignment: .top, spacing: DesignTokens.space12) {
                            Circle()
                                .fill(colorForVerdict(factor.severity))
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(factor.category.rawValue)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DesignTokens.textPrimary)

                                    Spacer()

                                    Text(factor.regulatoryReference)
                                        .font(.caption2.weight(.medium).monospaced())
                                        .foregroundStyle(DesignTokens.textTertiary)
                                }

                                Text(factor.summary)
                                    .font(.footnote)
                                    .foregroundStyle(DesignTokens.textSecondary)
                                    .lineSpacing(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
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
                        .stroke(DesignTokens.borderHairline.opacity(0.8), lineWidth: 0.5)
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
