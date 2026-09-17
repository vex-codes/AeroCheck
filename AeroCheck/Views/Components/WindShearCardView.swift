//
//  WindShearCardView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Altitudinal Wind Shear Profile & Telemetry card adhering to ForeFlight/DJI Fly standards:
/// - Surface vs 400ft ceiling comparison gauge with sharp monospaced figures.
/// - Streamlined altitudinal shear gradient meter.
/// - Clear data columns for Visibility, Cloud Ceiling, and Density Altitude.
/// - Sleek 0.5pt hairline border with 16pt uniform padding.
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
            HStack {
                Label {
                    Text("ATMOSPHERIC SOUNDING & WIND SHEAR")
                        .font(.caption2.weight(.bold).monospaced())
                        .tracking(0.6)
                        .foregroundStyle(DesignTokens.textTertiary)
                } icon: {
                    Image(systemName: "wind")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                Text(wReport.isHighAltitudeModelLive ? "OPEN-METEO ALOFT" : "HELLMANN SHEAR MODEL")
                    .font(.caption2.weight(.bold).monospaced())
                    .tracking(0.4)
                    .foregroundStyle(DesignTokens.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(DesignTokens.accentMuted)
                    )
            }

            // Surface vs 400ft Ceiling Telemetry Block
            HStack(spacing: DesignTokens.space12) {
                // Surface Column
                VStack(alignment: .leading, spacing: DesignTokens.space4) {
                    Text("SURFACE WIND (10M)")
                        .font(.caption2.weight(.semibold).monospaced())
                        .tracking(0.4)
                        .foregroundStyle(DesignTokens.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", wReport.surfaceWindSpeedMph))
                            .font(.system(size: 28, weight: .heavy, design: .monospaced))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text("MPH")
                            .font(.caption.weight(.heavy).monospaced())
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    if let gust = wReport.surfaceWindGustMph {
                        Text(String(format: "Gusts: %.1f mph", gust))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DesignTokens.statusCaution)
                    } else {
                        Text("Stable Surface Air")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Gradient Vector Indicator
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(windStatusColor)
                    let delta = effective400ftWind - wReport.surfaceWindSpeedMph
                    Text(String(format: "+%.1f", max(0, delta)))
                        .font(.caption2.weight(.heavy).monospaced())
                        .foregroundStyle(windStatusColor)
                }
                .padding(.horizontal, DesignTokens.space4)

                // 400ft AGL Column
                VStack(alignment: .trailing, spacing: DesignTokens.space4) {
                    Text("400 FT AGL CEILING")
                        .font(.caption2.weight(.semibold).monospaced())
                        .tracking(0.4)
                        .foregroundStyle(DesignTokens.textTertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", effective400ftWind))
                            .font(.system(size: 28, weight: .heavy, design: .monospaced))
                            .foregroundStyle(windStatusColor)
                        Text("MPH")
                            .font(.caption.weight(.heavy).monospaced())
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    Text("Max Envelope: \(Int(maxRatedWind)) mph")
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

            // Streamlined Altitudinal Gradient Bars
            VStack(alignment: .leading, spacing: DesignTokens.space8) {
                Text("ALTITUDE SHEAR GRADIENT (AGL)")
                    .font(.caption2.weight(.semibold).monospaced())
                    .tracking(0.4)
                    .foregroundStyle(DesignTokens.textTertiary)

                VStack(spacing: DesignTokens.space8) {
                    altitudeBar(label: "400 ft (Ceiling)", wind: wReport.wind400ftMph, maxLimit: maxRatedWind, isKey: true)
                    altitudeBar(label: "Surface (10m)", wind: wReport.surfaceWindSpeedMph, maxLimit: maxRatedWind, isKey: false)
                }
            }

            // Key Environmental Readouts (Visibility, Ceiling, Density Alt)
            HStack(spacing: DesignTokens.space8) {
                metricCell(
                    title: "VISIBILITY",
                    value: String(format: "%.1f SM", wReport.visibilityStatuteMiles),
                    statusColor: wReport.visibilityStatuteMiles >= 5.0 ? DesignTokens.statusSafe : (wReport.visibilityStatuteMiles >= 3.0 ? DesignTokens.statusCaution : DesignTokens.statusAlert),
                    subtitle: wReport.flightCategory.rawValue
                )

                metricCell(
                    title: "CLOUD BASE",
                    value: wReport.cloudCeilingFeet != nil ? "\(wReport.cloudCeilingFeet!) ft" : "CLR / ∞",
                    statusColor: (wReport.cloudCeilingFeet == nil || wReport.cloudCeilingFeet! > 1000) ? DesignTokens.statusSafe : (wReport.cloudCeilingFeet! >= 500 ? DesignTokens.statusCaution : DesignTokens.statusAlert),
                    subtitle: "§ 107.51 Buffer"
                )

                metricCell(
                    title: "DENSITY ALT",
                    value: "\(Int(densityAltitude)) ft",
                    statusColor: densityAltitude > 4000 ? DesignTokens.statusCaution : DesignTokens.statusSafe,
                    subtitle: thrustLossPercent != nil ? "-\(thrustLossPercent!)% Thrust" : "Nominal"
                )
            }

            // Raw Station METAR Toggle with 44pt tap target
            Button {
                withAnimation(.snappy(duration: 0.25)) {
                    showRawMetar.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "terminal")
                        .font(.caption)
                    Text(showRawMetar ? "Hide Raw Station METAR" : "View Station METAR (\(wReport.stationId))")
                        .font(.footnote.weight(.medium).monospaced())
                    Spacer()
                    Image(systemName: showRawMetar ? "chevron.up" : "chevron.down")
                        .font(.caption2.weight(.bold))
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
                    .padding(DesignTokens.space12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                            .fill(DesignTokens.surfaceTertiary)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                    .stroke(DesignTokens.borderHairline.opacity(0.8), lineWidth: 0.5)
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
                        .stroke(DesignTokens.borderHairline.opacity(0.8), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Subcomponents

    private func altitudeBar(label: String, wind: Double, maxLimit: Double, isKey: Bool) -> some View {
        HStack(spacing: DesignTokens.space8) {
            Text(label)
                .font(.caption.weight(isKey ? .bold : .regular).monospaced())
                .foregroundStyle(isKey ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(width: 120, alignment: .leading)

            GeometryReader { geo in
                let ratio = min(1.0, max(0.05, wind / max(30.0, maxLimit * 1.2)))
                let barWidth = geo.size.width * ratio

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(DesignTokens.surfaceTertiary)

                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(wind > maxLimit ? DesignTokens.statusAlert : (wind > maxLimit * 0.85 ? DesignTokens.statusCaution : DesignTokens.accent))
                        .frame(width: barWidth)
                }
            }
            .frame(height: 8)

            Text(String(format: "%.1f mph", wind))
                .font(.caption.weight(.bold).monospaced())
                .foregroundStyle(wind > maxLimit ? DesignTokens.statusAlert : DesignTokens.textPrimary)
                .frame(width: 60, alignment: .trailing)
        }
        .frame(height: 18)
    }

    private func metricCell(title: String, value: String, statusColor: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.space4) {
            Text(title)
                .font(.caption2.weight(.bold).monospaced())
                .tracking(0.3)
                .foregroundStyle(DesignTokens.textTertiary)

            Text(value)
                .font(.subheadline.weight(.heavy).monospaced())
                .foregroundStyle(statusColor)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(DesignTokens.space12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                .fill(DesignTokens.surfaceTertiary)
        )
    }
}
