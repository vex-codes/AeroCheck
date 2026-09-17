//
//  WindShearCardView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Altitudinal wind shear profile and atmospheric sounding card adhering to Apple Human Interface Guidelines:
/// - Semantic typography (Title2, Subheadline, Footnote, Monospaced Caption)
/// - Flat container with crisp 1pt hairline borders (no floating gradients or drop shadows)
/// - Single dominant interactive accent with disciplined status highlights
/// - Accessible 44pt touch targets with active press feedback
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
        VStack(alignment: .leading, spacing: DesignTokens.space12) {
            // Header Row
            HStack {
                Label {
                    Text("ATMOSPHERIC SOUNDING & WIND SHEAR")
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)
                } icon: {
                    Image(systemName: "wind")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                Text(wReport.isHighAltitudeModelLive ? "OPEN-METEO ALOFT" : "HELLMANN SHEAR MODEL")
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundStyle(DesignTokens.accent)
                    .padding(.horizontal, DesignTokens.space8)
                    .padding(.vertical, DesignTokens.space4)
                    .background(
                        Capsule().fill(DesignTokens.accentMuted)
                    )
            }

            // Surface vs 400ft Ceiling Comparison Block
            HStack(spacing: DesignTokens.space12) {
                // Surface Reading
                VStack(alignment: .leading, spacing: DesignTokens.space4) {
                    Text("SURFACE (10M)")
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", wReport.surfaceWindSpeedMph))
                            .font(.title2.weight(.bold).monospaced())
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text("mph")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    if let gust = wReport.surfaceWindGustMph {
                        Text(String(format: "Gusts: %.1f mph", gust))
                            .font(.caption)
                            .foregroundStyle(DesignTokens.statusCaution)
                    } else {
                        Text("Stable Surface Air")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Gradient Shift Indicator
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(windStatusColor)
                    let delta = effective400ftWind - wReport.surfaceWindSpeedMph
                    Text(String(format: "+%.1f", max(0, delta)))
                        .font(.caption2.weight(.bold).monospaced())
                        .foregroundStyle(windStatusColor)
                }
                .padding(.horizontal, DesignTokens.space4)

                // 400ft AGL Reading
                VStack(alignment: .trailing, spacing: DesignTokens.space4) {
                    Text("400 FT AGL CEILING")
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", effective400ftWind))
                            .font(.title2.weight(.bold).monospaced())
                            .foregroundStyle(windStatusColor)
                        Text("mph")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    Text("Limit: \(Int(maxRatedWind)) mph")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(windStatusColor)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(DesignTokens.space12)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                    .fill(DesignTokens.surfaceTertiary)
            )

            // Altitudinal Gradient Bars
            VStack(alignment: .leading, spacing: DesignTokens.space8) {
                Text("ALTITUDINAL PROFILE (AGL)")
                    .font(.caption2.weight(.semibold).monospaced())
                    .foregroundStyle(DesignTokens.textTertiary)

                VStack(spacing: DesignTokens.space8) {
                    altitudeRow(altitude: "400 ft", wind: wReport.wind400ftMph, maxLimit: maxRatedWind, isCeiling: true)
                    altitudeRow(altitude: "300 ft", wind: wReport.wind300ftMph, maxLimit: maxRatedWind)
                    altitudeRow(altitude: "200 ft", wind: wReport.wind200ftMph, maxLimit: maxRatedWind)
                    altitudeRow(altitude: "100 ft", wind: wReport.wind100ftMph, maxLimit: maxRatedWind)
                    altitudeRow(altitude: "Surface", wind: wReport.surfaceWindSpeedMph, maxLimit: maxRatedWind)
                }
            }

            // Metric Summary Cells
            HStack(spacing: DesignTokens.space8) {
                metricCell(
                    title: "VISIBILITY",
                    value: String(format: "%.1f SM", wReport.visibilityStatuteMiles),
                    statusColor: wReport.visibilityStatuteMiles >= 5.0 ? DesignTokens.statusSafe : (wReport.visibilityStatuteMiles >= 3.0 ? DesignTokens.statusCaution : DesignTokens.statusAlert),
                    subtitle: wReport.flightCategory.rawValue
                )

                metricCell(
                    title: "CEILING",
                    value: wReport.cloudCeilingFeet != nil ? "\(wReport.cloudCeilingFeet!) ft" : "CLR / ∞",
                    statusColor: (wReport.cloudCeilingFeet == nil || wReport.cloudCeilingFeet! > 1000) ? DesignTokens.statusSafe : (wReport.cloudCeilingFeet! >= 500 ? DesignTokens.statusCaution : DesignTokens.statusAlert),
                    subtitle: "Cloud Base"
                )

                metricCell(
                    title: "DENSITY ALT",
                    value: "\(Int(densityAltitude)) ft",
                    statusColor: densityAltitude > 4000 ? DesignTokens.statusCaution : DesignTokens.statusSafe,
                    subtitle: thrustLossPercent != nil ? "-\(thrustLossPercent!)% thrust" : "Nominal"
                )
            }

            // Raw METAR Toggle with 44pt tap target
            Button {
                withAnimation(.snappy(duration: 0.25)) {
                    showRawMetar.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "terminal")
                        .font(.caption)
                    Text(showRawMetar ? "Hide Raw METAR" : "View Station METAR (\(wReport.stationId))")
                        .font(.footnote.weight(.medium).monospaced())
                    Spacer()
                    Image(systemName: showRawMetar ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.semibold))
                }
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.interactivePress)

            if showRawMetar {
                Text(wReport.rawMetar)
                    .font(.caption.monospaced())
                    .foregroundStyle(DesignTokens.accent)
                    .padding(DesignTokens.space8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                            .fill(DesignTokens.surfacePrimary)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                    .stroke(DesignTokens.borderHairline, lineWidth: 1)
                            )
                    )
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

    // MARK: - Subcomponents

    private func altitudeRow(altitude: String, wind: Double, maxLimit: Double, isCeiling: Bool = false) -> some View {
        HStack(spacing: DesignTokens.space8) {
            Text(altitude)
                .font(.caption.weight(isCeiling ? .bold : .regular).monospaced())
                .foregroundStyle(isCeiling ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(width: 54, alignment: .leading)

            GeometryReader { geo in
                let ratio = min(1.0, max(0.05, wind / max(30.0, maxLimit * 1.2)))
                let barWidth = geo.size.width * ratio

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(DesignTokens.surfaceTertiary)

                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(wind > maxLimit ? DesignTokens.statusAlert : (wind > maxLimit * 0.85 ? DesignTokens.statusCaution : DesignTokens.accent))
                        .frame(width: barWidth)
                }
            }
            .frame(height: 6)

            Text(String(format: "%.1f mph", wind))
                .font(.caption.weight(.semibold).monospaced())
                .foregroundStyle(wind > maxLimit ? DesignTokens.statusAlert : DesignTokens.textPrimary)
                .frame(width: 60, alignment: .trailing)
        }
        .frame(height: 16)
    }

    private func metricCell(title: String, value: String, statusColor: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.space4) {
            Text(title)
                .font(.caption2.weight(.semibold).monospaced())
                .foregroundStyle(DesignTokens.textTertiary)

            Text(value)
                .font(.subheadline.weight(.bold).monospaced())
                .foregroundStyle(statusColor)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(DesignTokens.space8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                .fill(DesignTokens.surfaceTertiary)
        )
    }
}
