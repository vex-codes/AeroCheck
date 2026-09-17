//
//  VerdictBannerView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Authoritative Cockpit Verdict Banner adhering to ForeFlight/DJI Fly design:
/// - Edge-to-edge seamless presentation with zero boxy container nesting.
/// - Glanceable 30pt heavy status headline readable from 3 feet away.
/// - Human-friendly 1-sentence plain-English synopsis for zero mental effort.
/// - Live telemetry pulse beacon and observation age badge.
/// - Clean 0.5px hairline bottom divider to lead into the telemetry grid.
public struct VerdictBannerView: View {
    public let result: RiskAssessmentResult?
    public let isLoading: Bool
    public let relativeTime: String
    public let stationId: String?

    @State private var isExpanded: Bool = false

    public init(
        result: RiskAssessmentResult?,
        isLoading: Bool,
        relativeTime: String = "Live",
        stationId: String? = nil
    ) {
        self.result = result
        self.isLoading = isLoading
        self.relativeTime = relativeTime
        self.stationId = stationId
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

    private var statusTitle: String {
        if isLoading {
            return "CHECKING TELEMETRY"
        }
        guard let res = result else { return "STANDBY" }
        switch res.overallVerdict {
        case .safe: return "GO FOR FLIGHT"
        case .caution: return "CAUTION ADVISED"
        case .noGo: return "NO-GO RESTRICTED"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space12) {
            // Live Status Beacon & Telemetry Age Bar
            HStack(alignment: .center, spacing: DesignTokens.space8) {
                // Live Pulse Pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)

                    Text(isLoading ? "SYNCING" : "LIVE")
                        .font(.caption2.weight(.heavy))
                        .tracking(0.6)
                        .foregroundStyle(statusColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(statusBadgeBackground))

                if let stn = stationId {
                    Text("\(stn) • \(relativeTime)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                } else {
                    Text(relativeTime)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                Spacer()

                // Expandable Factors Link
                if let factors = result?.factors, !factors.isEmpty {
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Hide Details" : "Compliance (\(factors.count))")
                                .font(.caption2.weight(.semibold))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(DesignTokens.textSecondary)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.interactivePress)
                }
            }

            // Big Bold Glanceable Verdict (Instant pilot comprehension)
            VStack(alignment: .leading, spacing: DesignTokens.space4) {
                Text(statusTitle)
                    .font(.system(size: 30, weight: .black, design: .default))
                    .tracking(-0.5)
                    .foregroundStyle(statusColor)

                // Plain-English Human Synopsis (Zero mental overhead)
                Text(result?.primaryHeadline ?? "Awaiting live FAA and NOAA data synchronization...")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DesignTokens.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Expanded Compliance Checklist Items
            if isExpanded, let factors = result?.factors {
                VStack(alignment: .leading, spacing: DesignTokens.space12) {
                    Rectangle()
                        .fill(DesignTokens.borderHairline)
                        .frame(height: 0.5)
                        .padding(.vertical, DesignTokens.space4)

                    Text("PART 107 REGULATORY MATRIX")
                        .font(.caption2.weight(.heavy))
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
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(DesignTokens.textPrimary)

                                    Spacer()

                                    Text(factor.regulatoryReference)
                                        .font(.caption2.weight(.semibold).monospaced())
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

            // 0.5px Hairline Separator into Telemetry
            Rectangle()
                .fill(DesignTokens.borderHairline)
                .frame(height: 0.5)
                .padding(.top, DesignTokens.space4)
        }
        .padding(.vertical, DesignTokens.space8)
    }

    private func colorForVerdict(_ verdict: RiskVerdict) -> Color {
        switch verdict {
        case .safe: return DesignTokens.statusSafe
        case .caution: return DesignTokens.statusCaution
        case .noGo: return DesignTokens.statusAlert
        }
    }
}
