//
//  AirspaceCardView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Airspace classification and UASFM authorization card with direct LAANC deep link integration.
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
            return DesignTokens.verdictNoGo
        } else if airspace?.requiresLAANC == true {
            return DesignTokens.verdictCaution
        } else {
            return DesignTokens.verdictSafe
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spaceM) {
            // Header row with Airspace Badge
            HStack {
                Label {
                    Text("AIRSPACE & UASFM AUTHORIZATION")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)
                } icon: {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.aeroBlue)
                }

                Spacer()

                // Classification Badge
                Text(airspaceClass.badgeLabel)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(badgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(badgeColor.opacity(0.15))
                            .overlay(Capsule().stroke(badgeColor.opacity(0.4), lineWidth: 1))
                    )
            }

            // Facility and Ceiling Grid row
            HStack(alignment: .top, spacing: DesignTokens.spaceM) {
                VStack(alignment: .leading, spacing: DesignTokens.spaceXS) {
                    Text("FACILITY / JURISDICTION")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)

                    Text(airspace?.facilityName ?? "Class G Uncontrolled Area")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: DesignTokens.spaceXS) {
                    Text("UASFM MAX CEILING")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)

                    if let ceiling = airspace?.uasfmCeilingFeet {
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("\(ceiling)")
                                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                .foregroundStyle(ceiling == 0 ? DesignTokens.verdictNoGo : DesignTokens.textPrimary)
                            Text("ft AGL")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DesignTokens.textSecondary)
                        }
                    } else {
                        Text("400 ft (Open)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(DesignTokens.verdictSafe)
                    }
                }
            }

            // Regulatory note
            if let note = airspace?.regulatoryNote {
                HStack(spacing: DesignTokens.spaceS) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.textMuted)

                    Text(note)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(DesignTokens.textSecondary)
                }
                .padding(.vertical, 2)
            }

            // LAANC Action Button (if controlled airspace)
            if airspace?.requiresLAANC == true {
                Button(action: onOpenLAANC) {
                    HStack(spacing: DesignTokens.spaceS) {
                        Image(systemName: "arrow.up.right.square.fill")
                            .font(.system(size: 16))
                        Text(airspace?.isZeroCeiling == true ? "File Advanced Waiver via LAANC App" : "Request Instant LAANC Authorization")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusS)
                            .fill(airspace?.isZeroCeiling == true ? DesignTokens.cardBackgroundSecondary : DesignTokens.skyBlue)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusS)
                                    .stroke(airspace?.isZeroCeiling == true ? DesignTokens.verdictNoGo.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignTokens.spaceM)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                .fill(DesignTokens.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                        .stroke(DesignTokens.cardBorder, lineWidth: 1)
                )
        )
    }
}
