//
//  AirspaceCardView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Tactical Airspace & Authorization card adhering to AAA aviation standards:
/// - Clear, beautifully spaced data columns for Facility and UASFM Ceiling.
/// - Large, sharp numeric readouts with monospaced precision.
/// - Sleek 0.5pt hairline border with 16pt uniform padding.
/// - Integrated LAANC authorization trigger.
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
        VStack(alignment: .leading, spacing: DesignTokens.space16) {
            // Header Row: Section Label + Classification Pill
            HStack(alignment: .center) {
                Label {
                    Text("AIRSPACE AUTHORIZATION")
                        .font(.caption2.weight(.bold).monospaced())
                        .tracking(0.6)
                        .foregroundStyle(DesignTokens.textTertiary)
                } icon: {
                    Image(systemName: "shield.checkered")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                // Classification Pill
                Text(airspaceClass.badgeLabel)
                    .font(.caption2.weight(.heavy).monospaced())
                    .tracking(0.5)
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(badgeBackground)
                    )
            }

            // Balanced Data Columns: Facility & Ceiling Readouts
            HStack(alignment: .top, spacing: DesignTokens.space16) {
                // Facility Column
                VStack(alignment: .leading, spacing: DesignTokens.space4) {
                    Text("FACILITY / JURISDICTION")
                        .font(.caption2.weight(.semibold).monospaced())
                        .tracking(0.4)
                        .foregroundStyle(DesignTokens.textTertiary)

                    Text(airspace?.facilityName ?? "Class G Uncontrolled Airspace")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if let ident = airspace?.airportIdent {
                        Text("IDENT: \(ident)")
                            .font(.caption.weight(.bold).monospaced())
                            .foregroundStyle(DesignTokens.accent)
                            .padding(.top, 1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // UASFM Ceiling Column
                VStack(alignment: .trailing, spacing: DesignTokens.space4) {
                    Text("MAX UASFM CEILING")
                        .font(.caption2.weight(.semibold).monospaced())
                        .tracking(0.4)
                        .foregroundStyle(DesignTokens.textTertiary)

                    if let ceiling = airspace?.uasfmCeilingFeet {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("\(ceiling)")
                                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                                .foregroundStyle(ceiling == 0 ? DesignTokens.statusAlert : DesignTokens.textPrimary)
                            Text("FT AGL")
                                .font(.caption.weight(.heavy).monospaced())
                                .foregroundStyle(DesignTokens.textSecondary)
                        }
                    } else {
                        HStack(alignment: .firstTextBaseline, spacing: 3) {
                            Text("400")
                                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                                .foregroundStyle(DesignTokens.statusSafe)
                            Text("FT AGL")
                                .font(.caption.weight(.heavy).monospaced())
                                .foregroundStyle(DesignTokens.textSecondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(DesignTokens.space12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                    .fill(DesignTokens.surfaceTertiary)
            )

            // Regulatory Note Callout
            if let note = airspace?.regulatoryNote {
                HStack(alignment: .top, spacing: DesignTokens.space8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundStyle(badgeColor)
                        .padding(.top, 2)

                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineSpacing(2)
                }
            }

            // LAANC Direct Filing Action (if required)
            if airspace?.requiresLAANC == true {
                Button(action: onOpenLAANC) {
                    HStack(spacing: DesignTokens.space8) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.subheadline.weight(.bold))
                        Text(airspace?.isZeroCeiling == true ? "File Manual Waiver via LAANC Provider" : "Request Instant LAANC Authorization")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                            .fill(airspace?.isZeroCeiling == true ? DesignTokens.surfaceTertiary : DesignTokens.accent)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                    .stroke(airspace?.isZeroCeiling == true ? DesignTokens.statusAlert.opacity(0.5) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.interactivePress)
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
}
