//
//  AirspaceCardView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Seamless Airspace & LAANC Telemetry Section adhering to ForeFlight/DJI Fly:
/// - Pure inset group layout with zero boxy container nesting.
/// - Prominent 28pt Semibold numeric ceiling readout.
/// - Clear, staggered data columns (Facility / Airspace Class vs UASFM Ceiling).
/// - Borderless inline LAANC authorization action.
/// - 0.5px subtle hairline separator.
public struct AirspaceCardView: View {
    public let airspace: AirspaceEvaluation?
    public let onOpenLAANC: () -> Void

    public init(airspace: AirspaceEvaluation?, onOpenLAANC: @escaping () -> Void) {
        self.airspace = airspace
        self.onOpenLAANC = onOpenLAANC
    }

    private var airspaceClass: AirspaceClass {
        airspace?.airspaceClass ?? .classG
    }

    private var badgeColor: Color {
        if airspace?.isZeroCeiling == true {
            return DesignTokens.statusAlert
        } else if airspace?.requiresLAANC == true {
            return DesignTokens.statusCaution
        } else {
            return DesignTokens.statusSafe
        }
    }

    private var badgeBackground: Color {
        if airspace?.isZeroCeiling == true {
            return DesignTokens.statusAlertMuted
        } else if airspace?.requiresLAANC == true {
            return DesignTokens.statusCautionMuted
        } else {
            return DesignTokens.statusSafeMuted
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space12) {
            // Section Header
            HStack(alignment: .center) {
                Label {
                    Text("AIRSPACE & AUTHORIZATION")
                        .font(.caption2.weight(.heavy))
                        .tracking(0.6)
                        .foregroundStyle(DesignTokens.textTertiary)
                } icon: {
                    Image(systemName: "shield.checkered")
                        .font(.caption2)
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                // Classification Pill
                Text(airspaceClass.badgeLabel)
                    .font(.caption2.weight(.heavy))
                    .tracking(0.4)
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(badgeBackground))
            }

            // Staggered Telemetry Layout (Facility vs 28pt Ceiling)
            HStack(alignment: .top, spacing: DesignTokens.space16) {
                // Left Column: Facility & Identification
                VStack(alignment: .leading, spacing: DesignTokens.space4) {
                    Text(airspace?.facilityName ?? "Class G Uncontrolled Airspace")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: DesignTokens.space6) {
                        if let ident = airspace?.airportIdent {
                            Text(ident)
                                .font(.caption.weight(.bold).monospaced())
                                .foregroundStyle(DesignTokens.accent)
                        }

                        Text(airspace?.requiresLAANC == true ? "LAANC Authorization Required" : "Uncontrolled § 107.51")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right Column: 28pt Numeric UASFM Ceiling
                VStack(alignment: .trailing, spacing: 2) {
                    Text("MAX UASFM CEILING")
                        .font(.caption2.weight(.heavy))
                        .tracking(0.5)
                        .foregroundStyle(DesignTokens.textTertiary)

                    let ceilingVal = airspace?.uasfmCeilingFeet ?? 400
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text("\(ceilingVal)")
                            .font(.system(size: 28, weight: .semibold, design: .default))
                            .foregroundStyle(ceilingVal == 0 ? DesignTokens.statusAlert : DesignTokens.textPrimary)

                        Text("FT AGL")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }

                    Text(ceilingVal == 0 ? "Zero Grid Ceiling" : "Standard Limit")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(ceilingVal == 0 ? DesignTokens.statusAlert : DesignTokens.statusSafe)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Regulatory Note Callout (Clean inset row)
            if let note = airspace?.regulatoryNote {
                HStack(alignment: .top, spacing: DesignTokens.space8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(badgeColor)
                        .padding(.top, 2)

                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, DesignTokens.space4)
            }

            // LAANC Action Trigger (if required)
            if airspace?.requiresLAANC == true {
                Button(action: onOpenLAANC) {
                    HStack(spacing: DesignTokens.space8) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.subheadline.weight(.bold))
                        Text(airspace?.isZeroCeiling == true ? "Submit Safety Waiver via LAANC" : "Request Instant LAANC Authorization")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Capsule(style: .continuous)
                            .fill(airspace?.isZeroCeiling == true ? DesignTokens.statusAlertMuted : DesignTokens.accent)
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(airspace?.isZeroCeiling == true ? DesignTokens.statusAlert : Color.white.opacity(0.15), lineWidth: 0.5)
                            )
                    )
                }
                .buttonStyle(.interactivePress)
            }

            // 0.5px Hairline Separator
            Rectangle()
                .fill(DesignTokens.borderHairline)
                .frame(height: 0.5)
                .padding(.top, DesignTokens.space4)
        }
        .padding(.vertical, DesignTokens.space8)
    }
}
