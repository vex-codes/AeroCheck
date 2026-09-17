//
//  WindShearCardView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Professional Altitudinal Wind Shear & Atmospheric Telemetry Grid adhering to ForeFlight/DJI Fly:
/// - Edge-to-edge seamless presentation with zero boxy container nesting.
/// - Staggered multi-column dashboard grid with 28pt Semibold numbers.
/// - Sleek 3px multi-segment shear gradient track lines with numeric markers.
/// - Borderless 3-column pill layout for Visibility, Cloud Base, and Density Altitude.
/// - Clean 0.5px hairline bottom divider.
public struct WindShearCardView: View {
    public let weather: AviationWeatherReport?
    public let drone: DroneProfile
    public let densityAltitude: Double
    public let thrustLossPercent: Double?

    @State private var showRawMetar: Bool = false

    public init(
        weather: AviationWeatherReport?,
        drone: DroneProfile,
        densityAltitude: Double,
        thrustLossPercent: Double?
    ) {
        self.weather = weather
        self.drone = drone
        self.densityAltitude = densityAltitude
        self.thrustLossPercent = thrustLossPercent
    }

    private var wReport: AviationWeatherReport {
        weather ?? AviationWeatherReport.sampleVFR
    }

    private var maxRatedWind: Double {
        drone.maxWindResistanceMph
    }

    private var effective400ftWind: Double {
        max(wReport.wind400ftMph, wReport.windGust400ftMph ?? wReport.wind400ftMph)
    }

    private var windStatusColor: Color {
        if effective400ftWind > maxRatedWind {
            return DesignTokens.statusAlert
        } else if effective400ftWind >= maxRatedWind * 0.85 {
            return DesignTokens.statusCaution
        } else {
            return DesignTokens.statusSafe
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space16) {
            // Header Row
            HStack(alignment: .center) {
                Label {
                    Text("ATMOSPHERIC SOUNDING & WIND SHEAR")
                        .font(.caption2.weight(.heavy))
                        .tracking(0.6)
                        .foregroundStyle(DesignTokens.textTertiary)
                } icon: {
                    Image(systemName: "wind")
                        .font(.caption2)
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                Text(wReport.isHighAltitudeModelLive ? "OPEN-METEO ALOFT" : "HELLMANN MODEL")
                    .font(.caption2.weight(.bold))
                    .tracking(0.4)
                    .foregroundStyle(DesignTokens.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(DesignTokens.accentMuted))
            }

            // Staggered Multi-Column Wind Telemetry Grid
            HStack(alignment: .top, spacing: DesignTokens.space16) {
                // Surface Column
                VStack(alignment: .leading, spacing: 2) {
                    Text("SURFACE (10M)")
                        .font(.caption2.weight(.heavy))
                        .tracking(0.5)
                        .foregroundStyle(DesignTokens.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", wReport.surfaceWindSpeedMph))
                            .font(.system(size: 28, weight: .semibold, design: .default))
                            .foregroundStyle(DesignTokens.textPrimary)

                        Text("MPH")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }

                    if let gust = wReport.surfaceWindGustMph {
                        Text(String(format: "Gusts to %.1f mph", gust))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(DesignTokens.statusCaution)
                    } else {
                        Text("Steady Surface Flow")
                            .font(.caption2)
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Central Shear Vector Indicator
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(windStatusColor)

                    let delta = effective400ftWind - wReport.surfaceWindSpeedMph
                    Text(String(format: "+%.1f", max(0, delta)))
                        .font(.caption2.weight(.heavy).monospaced())
                        .foregroundStyle(windStatusColor)

                    Text("SHEAR")
                        .font(.system(size: 9, weight: .heavy))
                        .tracking(0.5)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.top, 6)

                // 400 FT AGL Ceiling Column
                VStack(alignment: .trailing, spacing: 2) {
                    Text("400 FT AGL CEILING")
                        .font(.caption2.weight(.heavy))
                        .tracking(0.5)
                        .foregroundStyle(DesignTokens.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", effective400ftWind))
                            .font(.system(size: 28, weight: .semibold, design: .default))
                            .foregroundStyle(windStatusColor)

                        Text("MPH")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }

                    Text("Airframe Max: \(Int(maxRatedWind)) mph")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(effective400ftWind > maxRatedWind ? DesignTokens.statusAlert : DesignTokens.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Sleek Ultra-Thin Multi-Segment Shear Track Lines (3px height)
            VStack(alignment: .leading, spacing: DesignTokens.space8) {
                Text("ALTITUDE SHEAR GRADIENT (AGL)")
                    .font(.caption2.weight(.heavy))
                    .tracking(0.5)
                    .foregroundStyle(DesignTokens.textTertiary)

                VStack(spacing: 6) {
                    sleekTrackLine(label: "400 FT", wind: wReport.wind400ftMph, maxLimit: maxRatedWind, isCeiling: true)
                    sleekTrackLine(label: "200 FT", wind: wReport.wind200ftMph, maxLimit: maxRatedWind, isCeiling: false)
                    sleekTrackLine(label: "SFC", wind: wReport.surfaceWindSpeedMph, maxLimit: maxRatedWind, isCeiling: false)
                }
            }

            // Seamless Borderless 3-Column Pill Layout (Zero crypto-box styling)
            HStack(spacing: DesignTokens.space8) {
                borderlessMetricPill(
                    title: "VISIBILITY",
                    value: String(format: "%.1f SM", wReport.visibilityStatuteMiles),
                    statusColor: wReport.visibilityStatuteMiles >= 5.0 ? DesignTokens.statusSafe : (wReport.visibilityStatuteMiles >= 3.0 ? DesignTokens.statusCaution : DesignTokens.statusAlert),
                    subtitle: wReport.flightCategory.rawValue
                )

                borderlessMetricPill(
                    title: "CLOUD BASE",
                    value: wReport.cloudCeilingFeet != nil ? "\(wReport.cloudCeilingFeet!) FT" : "CLR / ∞",
                    statusColor: (wReport.cloudCeilingFeet == nil || wReport.cloudCeilingFeet! > 1000) ? DesignTokens.statusSafe : (wReport.cloudCeilingFeet! >= 500 ? DesignTokens.statusCaution : DesignTokens.statusAlert),
                    subtitle: "§ 107.51 Buffer"
                )

                borderlessMetricPill(
                    title: "DENSITY ALT",
                    value: "\(Int(densityAltitude)) FT",
                    statusColor: densityAltitude > 4000 ? DesignTokens.statusCaution : DesignTokens.statusSafe,
                    subtitle: thrustLossPercent != nil ? "-\(Int(thrustLossPercent!))% Thrust" : "Nominal"
                )
            }

            // Raw Station METAR disclosure button
            Button {
                withAnimation(.snappy(duration: 0.25)) {
                    showRawMetar.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "terminal")
                        .font(.caption2)
                    Text(showRawMetar ? "Hide Raw METAR" : "Raw METAR (\(wReport.stationId))")
                        .font(.caption.weight(.medium))
                    Spacer()
                    Image(systemName: showRawMetar ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(DesignTokens.textTertiary)
                .frame(height: 32)
                .contentShape(Rectangle())
            }
            .buttonStyle(.interactivePress)

            if showRawMetar {
                Text(wReport.rawMetar)
                    .font(.caption.monospaced())
                    .foregroundStyle(DesignTokens.accent)
                    .padding(DesignTokens.space12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                            .fill(DesignTokens.surfaceSecondary)
                    )
            }

            // 0.5px Hairline Separator
            Rectangle()
                .fill(DesignTokens.borderHairline)
                .frame(height: 0.5)
                .padding(.top, DesignTokens.space4)
        }
        .padding(.vertical, DesignTokens.space8)
    }

    // MARK: - Sleek Track Line Subcomponent (3px height)

    private func sleekTrackLine(label: String, wind: Double, maxLimit: Double, isCeiling: Bool) -> some View {
        HStack(spacing: DesignTokens.space8) {
            Text(label)
                .font(.caption2.weight(isCeiling ? .bold : .medium).monospaced())
                .foregroundStyle(isCeiling ? DesignTokens.textPrimary : DesignTokens.textTertiary)
                .frame(width: 52, alignment: .leading)

            GeometryReader { geo in
                let ratio = min(1.0, max(0.04, wind / max(30.0, maxLimit * 1.25)))
                let barWidth = geo.size.width * ratio
                let barColor = wind > maxLimit ? DesignTokens.statusAlert : (wind > maxLimit * 0.85 ? DesignTokens.statusCaution : DesignTokens.accent)

                ZStack(alignment: .leading) {
                    // Muted background track line
                    Capsule()
                        .fill(Color.white.opacity(0.07))

                    // Active track segment
                    Capsule()
                        .fill(barColor)
                        .frame(width: barWidth)
                }
            }
            .frame(height: 3)

            Text(String(format: "%.1f mph", wind))
                .font(.caption2.weight(.semibold).monospaced())
                .foregroundStyle(wind > maxLimit ? DesignTokens.statusAlert : DesignTokens.textSecondary)
                .frame(width: 58, alignment: .trailing)
        }
        .frame(height: 16)
    }

    // MARK: - Borderless Metric Pill (Seamless, minimal geometric footprint)

    private func borderlessMetricPill(title: String, value: String, statusColor: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .heavy))
                .tracking(0.5)
                .foregroundStyle(DesignTokens.textTertiary)

            Text(value)
                .font(.system(size: 17, weight: .bold, design: .default))
                .foregroundStyle(statusColor)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                .fill(DesignTokens.surfaceSecondary.opacity(0.6))
        )
    }
}
