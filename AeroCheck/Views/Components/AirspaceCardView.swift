//
//  AirspaceCardView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Airspace classification & UASFM ceiling card adhering to Apple Human Interface Guidelines:
/// - Semantic typography (Headline, Subheadline, Footnote, Monospaced Caption)
/// - Controlled, purposeful status accents (safe / caution / alert)
/// - 44pt minimum touch target on LAANC trigger with active press feedback
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

    private var badgeMuted: Color {
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
            // Header Row with Airspace Badge
            HStack {
                Label {
                    Text("AIRSPACE & UASFM AUTHORIZATION")
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)
                } icon: {
                    Image(systemName: "shield.checkered")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                // Classification Pill
                Text(airspaceClass.badgeLabel)
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, DesignTokens.space8)
                    .padding(.vertical, DesignTokens.space4)
                    .background(
                        Capsule().fill(badgeMuted)
                    )
            }

            // Facility and Ceiling Grid Row
            HStack(alignment: .top, spacing: DesignTokens.space16) {
                VStack(alignment: .leading, spacing: DesignTokens.space4) {
                    Text("FACILITY")
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)

                    Text(airspace?.facilityName ?? "Class G Uncontrolled Area")
                        .font(.headline)
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignTokens.space4) {
                    Text("UASFM CEILING")
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)

                    if let ceiling = airspace?.uasfmCeilingFeet {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(ceiling)")
                                .font(.title3.weight(.bold).monospaced())
                                .foregroundStyle(ceiling == 0 ? DesignTokens.statusAlert : DesignTokens.textPrimary)
                            Text("ft AGL")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(DesignTokens.textSecondary)
                        }
                    } else {
                        Text("400 ft AGL")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DesignTokens.statusSafe)
                    }
                }
            }

            // Regulatory Note
            if let note = airspace?.regulatoryNote {
                HStack(alignment: .top, spacing: DesignTokens.space8) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.textTertiary)
                        .padding(.top, 1)

                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(DesignTokens.textSecondary)
                        .lineSpacing(2)
                }
                .padding(.vertical, DesignTokens.space4)
            }

            // LAANC Action Button
            if airspace?.requiresLAANC == true {
                Button(action: onOpenLAANC) {
                    HStack(spacing: DesignTokens.space8) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.subheadline.weight(.semibold))
                        Text(airspace?.isZeroCeiling == true ? "File Advanced Waiver (0 ft Grid)" : "Request Instant LAANC Authorization")
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
                                    .stroke(airspace?.isZeroCeiling == true ? DesignTokens.statusAlert.opacity(0.4) : Color.clear, lineWidth: 1)
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
                        .stroke(DesignTokens.borderHairline, lineWidth: 1)
                )
        )
    }
}
