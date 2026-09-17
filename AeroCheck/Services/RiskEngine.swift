//
//  RiskEngine.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation
import CoreLocation

/// Core algorithmic Risk Assessment Matrix (RAM) conforming to FAA Part 107 pre-flight standards.
public enum RiskEngine {

    /// Evaluates environmental conditions against aircraft capabilities and FAA legal constraints.
    public static func evaluateRisk(
        airspace: AirspaceEvaluation,
        weather: AviationWeatherReport,
        drone: DroneProfile,
        plannedAltitudeFeet: Int = 400,
        coordinate: CLLocationCoordinate2D? = nil
    ) -> RiskAssessmentResult {
        var factors: [RiskFactorItem] = []

        // 1. Airspace Factor (§ 107.41)
        let airspaceFactor: RiskFactorItem
        if airspace.isZeroCeiling {
            airspaceFactor = RiskFactorItem(
                category: .airspace,
                severity: .noGo,
                summary: "Zero-foot (0 ft) UASFM ceiling grid at \(airspace.airportIdent ?? "Airport"). Standard LAANC automated authorization unavailable.",
                regulatoryReference: "FAA § 107.41 / UASFM"
            )
        } else if airspace.requiresLAANC {
            let ceilingText = airspace.uasfmCeilingFeet != nil ? "\(airspace.uasfmCeilingFeet!) ft AGL" : "surface"
            airspaceFactor = RiskFactorItem(
                category: .airspace,
                severity: .caution,
                summary: "Controlled \(airspace.airspaceClass.title). LAANC authorization required prior to flight up to \(ceilingText).",
                regulatoryReference: "FAA § 107.41"
            )
        } else {
            airspaceFactor = RiskFactorItem(
                category: .airspace,
                severity: .safe,
                summary: "Class G Uncontrolled Airspace. No prior ATC or LAANC authorization required up to 400 ft AGL.",
                regulatoryReference: "FAA § 107.51(b)"
            )
        }
        factors.append(airspaceFactor)

        // 2. Flight Visibility Factor (§ 107.51(c))
        let vis = weather.visibilityStatuteMiles
        let visibilityFactor: RiskFactorItem
        if vis < 3.0 {
            visibilityFactor = RiskFactorItem(
                category: .visibility,
                severity: .noGo,
                summary: String(format: "Flight visibility (%.1f SM) is below the FAA legal minimum of 3.0 statute miles.", vis),
                regulatoryReference: "FAA § 107.51(c)"
            )
        } else if vis <= 5.0 {
            visibilityFactor = RiskFactorItem(
                category: .visibility,
                severity: .caution,
                summary: String(format: "Marginal visibility (%.1f SM). Maintain close visual line of sight with visual observer.", vis),
                regulatoryReference: "FAA § 107.51(c)"
            )
        } else {
            visibilityFactor = RiskFactorItem(
                category: .visibility,
                severity: .safe,
                summary: String(format: "Visibility (%.1f SM) exceeds FAA Part 107 minimum requirement.", vis),
                regulatoryReference: "FAA § 107.51(c)"
            )
        }
        factors.append(visibilityFactor)

        // 3. Cloud Clearance & Ceiling (§ 107.51(d))
        let cloudFactor: RiskFactorItem
        if let ceiling = weather.cloudCeilingFeet {
            if ceiling < 500 {
                cloudFactor = RiskFactorItem(
                    category: .cloudCeiling,
                    severity: .noGo,
                    summary: "Cloud ceiling is \(ceiling) ft AGL. Law requires maintaining at least 500 ft below clouds (§ 107.51(d)).",
                    regulatoryReference: "FAA § 107.51(d)"
                )
            } else if ceiling <= 1000 {
                let maxLegalAltitude = max(50, ceiling - 500)
                cloudFactor = RiskFactorItem(
                    category: .cloudCeiling,
                    severity: .caution,
                    summary: "Low ceiling (\(ceiling) ft AGL). Maximum legal flight altitude restricted to \(maxLegalAltitude) ft AGL.",
                    regulatoryReference: "FAA § 107.51(d)"
                )
            } else {
                cloudFactor = RiskFactorItem(
                    category: .cloudCeiling,
                    severity: .safe,
                    summary: "Cloud ceiling is \(ceiling) ft AGL, providing sufficient 500 ft vertical buffer.",
                    regulatoryReference: "FAA § 107.51(d)"
                )
            }
        } else {
            cloudFactor = RiskFactorItem(
                category: .cloudCeiling,
                severity: .safe,
                summary: "Clear skies reported. No cloud clearance ceiling restrictions.",
                regulatoryReference: "FAA § 107.51(d)"
            )
        }
        factors.append(cloudFactor)

        // 4. Wind at Planned Altitude vs Aircraft Envelope
        let targetAltitude = min(400, max(50, plannedAltitudeFeet))
        let windAtAlt: Double
        let gustAtAlt: Double?

        if targetAltitude <= 75 {
            windAtAlt = weather.surfaceWindSpeedMph
            gustAtAlt = weather.surfaceWindGustMph
        } else if targetAltitude <= 150 {
            windAtAlt = weather.wind100ftMph
            gustAtAlt = weather.surfaceWindGustMph != nil ? (weather.wind100ftMph * 1.2) : nil
        } else if targetAltitude <= 250 {
            windAtAlt = weather.wind200ftMph
            gustAtAlt = weather.surfaceWindGustMph != nil ? (weather.wind200ftMph * 1.2) : nil
        } else if targetAltitude <= 350 {
            windAtAlt = weather.wind300ftMph
            gustAtAlt = weather.surfaceWindGustMph != nil ? (weather.wind300ftMph * 1.2) : nil
        } else {
            windAtAlt = weather.wind400ftMph
            gustAtAlt = weather.windGust400ftMph
        }

        let effectiveWind = max(windAtAlt, gustAtAlt ?? windAtAlt)
        let maxRated = drone.maxWindResistanceMph

        let windFactor: RiskFactorItem
        if effectiveWind > maxRated {
            windFactor = RiskFactorItem(
                category: .windAloft,
                severity: .noGo,
                summary: String(format: "Wind/gusts at %dft (%.1f mph) exceed %@ maximum rating (%.1f mph). Risk of flyaway.", targetAltitude, effectiveWind, drone.name, maxRated),
                regulatoryReference: "Manufacturer Flight Envelope"
            )
        } else if effectiveWind >= maxRated * 0.85 {
            windFactor = RiskFactorItem(
                category: .windAloft,
                severity: .caution,
                summary: String(format: "Wind at %dft (%.1f mph) is within 15%% of %@ maximum rating (%.1f mph). Expect turbulence.", targetAltitude, effectiveWind, drone.name, maxRated),
                regulatoryReference: "Pre-Flight Safety Buffer"
            )
        } else {
            windFactor = RiskFactorItem(
                category: .windAloft,
                severity: .safe,
                summary: String(format: "Wind at %dft AGL (%.1f mph) is safely within %@ rating (%.1f mph).", targetAltitude, effectiveWind, drone.name, maxRated),
                regulatoryReference: "Manufacturer Flight Envelope"
            )
        }
        factors.append(windFactor)

        // 5. Density Altitude & Motor Performance
        let pa = AviationMath.pressureAltitude(elevationFeet: weather.elevationFeet, altimeterInHg: weather.altimeterInHg)
        let da = AviationMath.densityAltitude(elevationFeet: weather.elevationFeet, altimeterInHg: weather.altimeterInHg, actualTempCelsius: weather.temperatureCelsius)
        let thrustLoss = AviationMath.thrustDegradationPercentage(densityAltitudeFeet: da)

        if da > 4000 {
            let lossText = thrustLoss != nil ? String(format: "%.1f%%", thrustLoss!) : "12-18%"
            factors.append(RiskFactorItem(
                category: .densityAltitude,
                severity: .caution,
                summary: "High Density Altitude (\(Int(da)) ft). Expect approximately \(lossText) drop in motor thrust efficiency and faster battery discharge.",
                regulatoryReference: "Aerodynamic Performance Advisory"
            ))
        }

        // 6. Operating Temperature Check
        let temp = weather.temperatureCelsius
        if temp < drone.minOperatingTempC || temp > drone.maxOperatingTempC {
            factors.append(RiskFactorItem(
                category: .temperature,
                severity: .caution,
                summary: String(format: "Ambient temperature (%.1f°C) exceeds %@ operating envelope (%.0f°C to %.0f°C). Risk of battery shutdown.", temp, drone.name, drone.minOperatingTempC, drone.maxOperatingTempC),
                regulatoryReference: "Battery & Sensor Temp Limit"
            ))
        }

        // 7. Daylight, Civil Twilight & Anti-Collision Lighting Check (§ 107.29)
        if let coord = coordinate {
            let solar = AviationMath.solarTimes(latitude: coord.latitude, longitude: coord.longitude)
            switch solar.status {
            case .daylight:
                factors.append(RiskFactorItem(
                    category: .solarLighting,
                    severity: .safe,
                    summary: "Daylight operations active. Standard visual line-of-sight Part 107 flight rules.",
                    regulatoryReference: "FAA § 107.29"
                ))
            case .civilTwilight:
                factors.append(RiskFactorItem(
                    category: .solarLighting,
                    severity: .caution,
                    summary: "Civil Twilight operations. Anti-collision lighting visible for at least 3 statute miles mandatory (§ 107.29(b)).",
                    regulatoryReference: "FAA § 107.29(b)"
                ))
            case .night:
                factors.append(RiskFactorItem(
                    category: .solarLighting,
                    severity: .caution,
                    summary: "Night operations active. Anti-collision strobe (3 SM visibility) and Remote Pilot night training verification required.",
                    regulatoryReference: "FAA § 107.29(a)"
                ))
            }
        }

        // Aggregate Overall Verdict
        let overallVerdict: RiskVerdict
        let primaryHeadline: String
        let detailedRationale: String

        if factors.contains(where: { $0.severity == .noGo }) {
            overallVerdict = .noGo
            primaryHeadline = "FLIGHT PROHIBITED / NO-GO"
            let noGoReasons = factors.filter { $0.severity == .noGo }.map { $0.summary }.joined(separator: " • ")
            detailedRationale = "Regulatory or aircraft safety thresholds breached: \(noGoReasons)"
        } else if factors.contains(where: { $0.severity == .caution }) {
            overallVerdict = .caution
            primaryHeadline = "PROCEED WITH CAUTION"
            let cautionReasons = factors.filter { $0.severity == .caution }.map { $0.summary }.joined(separator: " • ")
            detailedRationale = "Operational precautions required: \(cautionReasons)"
        } else {
            overallVerdict = .safe
            primaryHeadline = "APPROVED / ALL SYSTEMS GO"
            detailedRationale = "Environmental and airspace conditions are optimal for flight up to 400 ft AGL."
        }

        return RiskAssessmentResult(
            overallVerdict: overallVerdict,
            primaryHeadline: primaryHeadline,
            detailedRationale: detailedRationale,
            factors: factors,
            densityAltitudeFeet: da,
            pressureAltitudeFeet: pa,
            thrustEfficiencyLossPercent: thrustLoss
        )
    }
}
