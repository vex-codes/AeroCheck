//
//  WindShearCardView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Signature Detail: Interactive 400ft Altitudinal Wind Shear Profile meter comparing
/// surface wind sounding against the legal 400ft Part 107 ceiling and aircraft flight envelope.
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

    private var windWarningColor: Color {
        if effective400ftWind > maxRatedWind {
            return DesignTokens.verdictNoGo
        } else if effective400ftWind >= maxRatedWind * 0.85 {
            return DesignTokens.verdictCaution
        } else {
            return DesignTokens.verdictSafe
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.spaceM) {
            // Header Row
            HStack {
                Label {
                    Text("ATMOSPHERIC SOUNDING & 400 FT WIND SHEAR")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)
                } icon: {
                    Image(systemName: "wind")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.aeroBlue)
                }

                Spacer()

                Text(wReport.isHighAltitudeModelLive ? "OPEN-METEO ALOFT" : "HELLMANN SHEAR MODEL")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.aeroBlue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(DesignTokens.aeroBlue.opacity(0.12))
                    )
            }

            // High-Impact Comparison Gauge: Surface vs 400ft Ceiling
            HStack(spacing: DesignTokens.spaceM) {
                // Surface Telemetry
                VStack(alignment: .leading, spacing: 2) {
                    Text("SURFACE WIND")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", wReport.surfaceWindSpeedMph))
                            .font(.system(size: 26, weight: .heavy, design: .monospaced))
                            .foregroundStyle(DesignTokens.textPrimary)
                        Text("mph")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    if let gust = wReport.surfaceWindGustMph {
                        Text(String(format: "Gusts: %.1f mph", gust))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DesignTokens.verdictCaution)
                    } else {
                        Text("Stable Surface Air")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(DesignTokens.textMuted)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Arrow Flow Indicator
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(windWarningColor)
                    let delta = effective400ftWind - wReport.surfaceWindSpeedMph
                    Text(String(format: "+%.1f mph", max(0, delta)))
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(windWarningColor)
                }
                .padding(.horizontal, 4)

                // 400ft AGL Telemetry
                VStack(alignment: .trailing, spacing: 2) {
                    Text("400 FT AGL CEILING")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", effective400ftWind))
                            .font(.system(size: 26, weight: .heavy, design: .monospaced))
                            .foregroundStyle(windWarningColor)
                        Text("mph")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(DesignTokens.textSecondary)
                    }

                    Text("Max Envelope: \(Int(maxRatedWind)) mph")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(windWarningColor)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(DesignTokens.spaceM)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.radiusS)
                    .fill(DesignTokens.cardBackgroundSecondary)
            )

            // Altitude Gradient Bar Profile (Surface, 100ft, 200ft, 300ft, 400ft)
            VStack(alignment: .leading, spacing: DesignTokens.spaceS) {
                Text("ALTITUDINAL SHEAR GRADIENT (AGL)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.textMuted)

                VStack(spacing: 6) {
                    altitudeRow(altitude: "400 ft", wind: wReport.wind400ftMph, maxLimit: maxRatedWind, highlight: true)
                    altitudeRow(altitude: "300 ft", wind: wReport.wind300ftMph, maxLimit: maxRatedWind)
                    altitudeRow(altitude: "200 ft", wind: wReport.wind200ftMph, maxLimit: maxRatedWind)
                    altitudeRow(altitude: "100 ft", wind: wReport.wind100ftMph, maxLimit: maxRatedWind)
                    altitudeRow(altitude: "Surface", wind: wReport.surfaceWindSpeedMph, maxLimit: maxRatedWind)
                }
            }

            // Grid: Visibility, Cloud Ceiling, Density Altitude
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: DesignTokens.spaceS) {
                metricCell(
                    title: "VISIBILITY",
                    value: String(format: "%.1f SM", wReport.visibilityStatuteMiles),
                    statusColor: wReport.visibilityStatuteMiles >= 5.0 ? DesignTokens.verdictSafe : (wReport.visibilityStatuteMiles >= 3.0 ? DesignTokens.verdictCaution : DesignTokens.verdictNoGo),
                    subtitle: wReport.flightCategory.rawValue
                )

                metricCell(
                    title: "CEILING",
                    value: wReport.cloudCeilingFeet != nil ? "\(wReport.cloudCeilingFeet!) ft" : "CLR / ∞",
                    statusColor: (wReport.cloudCeilingFeet == nil || wReport.cloudCeilingFeet! > 1000) ? DesignTokens.verdictSafe : (wReport.cloudCeilingFeet! >= 500 ? DesignTokens.verdictCaution : DesignTokens.verdictNoGo),
                    subtitle: "Cloud Base"
                )

                metricCell(
                    title: "DENSITY ALT",
                    value: "\(Int(densityAltitude)) ft",
                    statusColor: densityAltitude > 4000 ? DesignTokens.verdictCaution : DesignTokens.verdictSafe,
                    subtitle: thrustLossPercent != nil ? "-\(thrustLossPercent!)% thrust" : "Optimal"
                )
            }

            // Raw METAR Toggle
            Button {
                withAnimation {
                    showRawMetar.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 11))
                    Text(showRawMetar ? "Hide Raw METAR" : "View Station METAR (\(wReport.stationId))")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    Spacer()
                    Image(systemName: showRawMetar ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                }
                .foregroundStyle(DesignTokens.textSecondary)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)

            if showRawMetar {
                Text(wReport.rawMetar)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(DesignTokens.aeroBlue)
                    .padding(DesignTokens.spaceS)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusS)
                            .fill(DesignTokens.canvasBackground)
                    )
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

    // MARK: - Subcomponents

    private func altitudeRow(altitude: String, wind: Double, maxLimit: Double, highlight: Bool = false) -> some View {
        HStack(spacing: DesignTokens.spaceS) {
            Text(altitude)
                .font(.system(size: 10, weight: highlight ? .bold : .regular, design: .monospaced))
                .foregroundStyle(highlight ? DesignTokens.textPrimary : DesignTokens.textSecondary)
                .frame(width: 52, alignment: .leading)

            GeometryReader { geo in
                let normalizedRatio = min(1.0, max(0.05, wind / max(35.0, maxLimit * 1.2)))
                let barWidth = geo.size.width * normalizedRatio

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(DesignTokens.cardBackgroundSecondary)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignTokens.aeroBlue,
                                    wind > maxLimit ? DesignTokens.verdictNoGo : (wind > maxLimit * 0.85 ? DesignTokens.verdictCaution : DesignTokens.verdictSafe)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: barWidth)
                }
            }
            .frame(height: 10)

            Text(String(format: "%.1f mph", wind))
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(wind > maxLimit ? DesignTokens.verdictNoGo : DesignTokens.textPrimary)
                .frame(width: 58, alignment: .trailing)
        }
        .frame(height: 14)
    }

    private func metricCell(title: String, value: String, statusColor: Color, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundStyle(DesignTokens.textMuted)

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(statusColor)

            Text(subtitle)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(DesignTokens.textSecondary)
        }
        .padding(DesignTokens.spaceS)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusS)
                .fill(DesignTokens.cardBackgroundSecondary)
        )
    }
}
