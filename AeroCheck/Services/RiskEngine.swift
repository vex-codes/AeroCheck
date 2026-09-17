//
//  RiskEngine.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation

/// Core algorithmic Risk Assessment Matrix (RAM) conforming to FAA Part 107 pre-flight standards.
public enum RiskEngine {

    /// Evaluates environmental conditions against aircraft capabilities and FAA legal constraints.
    public static func evaluateRisk(
        airspace: AirspaceEvaluation,
        weather: AviationWeatherReport,
        drone: DroneProfile
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

        // 4. Wind at 400ft vs Aircraft Envelope
        let windAt400 = weather.wind400ftMph
        let gustAt400 = weather.windGust400ftMph ?? windAt400
        let effectiveWind = max(windAt400, gustAt400)
        let maxRated = drone.maxWindResistanceMph

        let windFactor: RiskFactorItem
        if effectiveWind > maxRated {
            windFactor = RiskFactorItem(
                category: .windAloft,
                severity: .noGo,
                summary: String(format: "Estimated wind/gusts at 400ft (%.1f mph) exceed %@ maximum limit (%.1f mph). Risk of flyaway.", effectiveWind, drone.name, maxRated),
                regulatoryReference: "Manufacturer Flight Envelope"
            )
        } else if effectiveWind >= maxRated * 0.85 {
            windFactor = RiskFactorItem(
                category: .windAloft,
                severity: .caution,
                summary: String(format: "Wind at 400ft (%.1f mph) is within 15%% of %@ maximum rating (%.1f mph). Expect turbulence.", effectiveWind, drone.name, maxRated),
                regulatoryReference: "Pre-Flight Safety Buffer"
            )
        } else {
            windFactor = RiskFactorItem(
                category: .windAloft,
                severity: .safe,
                summary: String(format: "400ft wind velocity (%.1f mph) is well within aircraft rating (%.1f mph).", effectiveWind, maxRated),
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
