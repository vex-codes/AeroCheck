//
//  AviationMath.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation

/// FAA Part 107.29 Daylight, Civil Twilight, and Night operations status.
public enum SolarFlightStatus: String, Codable, Sendable {
    case daylight = "Daylight"
    case civilTwilight = "Civil Twilight"
    case night = "Night Operations"

    public var badgeTitle: String {
        switch self {
        case .daylight: return "DAYLIGHT VFR"
        case .civilTwilight: return "CIVIL TWILIGHT"
        case .night: return "NIGHT OPS"
        }
    }

    public var lightingRequirement: String {
        switch self {
        case .daylight:
            return "Standard daylight flight (§ 107.29)"
        case .civilTwilight:
            return "Anti-collision strobe required (3 SM visibility, § 107.29(b))"
        case .night:
            return "Anti-collision strobe (3 SM) + Night training required (§ 107.29(a))"
        }
    }
}

public struct SolarTimesResult: Sendable {
    public let dawn: Date
    public let sunrise: Date
    public let sunset: Date
    public let dusk: Date
    public let status: SolarFlightStatus

    public init(dawn: Date, sunrise: Date, sunset: Date, dusk: Date, status: SolarFlightStatus) {
        self.dawn = dawn
        self.sunrise = sunrise
        self.sunset = sunset
        self.dusk = dusk
        self.status = status
    }
}

/// Mathematical algorithms for atmospheric calculations and aerodynamic limits.
nonisolated public enum AviationMath: Sendable {

    // MARK: - Wind Shear & Hellmann Power Law

    /// Calculates estimated wind speed at altitude using the Hellmann Wind Power Law:
    /// v(z) = v_10 * (z / z_10)^alpha
    ///
    /// - Parameters:
    ///   - surfaceWindSpeedMph: Wind speed measured at 10m height (e.g. from METAR)
    ///   - altitudeFeet: Target AGL altitude in feet (e.g. 100, 200, 300, 400)
    ///   - alpha: Terrain roughness exponent (default 0.20 for suburban)
    /// - Returns: Estimated wind velocity in mph at target altitude
    public static func estimateWindAtAltitude(
        surfaceWindSpeedMph: Double,
        altitudeFeet: Double,
        alpha: Double = 0.20
    ) -> Double {
        guard surfaceWindSpeedMph > 0, altitudeFeet > 0 else {
            return surfaceWindSpeedMph
        }

        let zMeters = altitudeFeet * 0.3048
        let z10Meters = 10.0 // Standard anemometer height (approx 32.8 ft)

        // Prevent negative or zero exponent base
        let ratio = max(0.1, zMeters / z10Meters)
        let estimatedSpeed = surfaceWindSpeedMph * pow(ratio, alpha)
        return (estimatedSpeed * 10).rounded() / 10.0
    }

    /// Computes full wind gradient profile up to 400ft AGL.
    public static func computeWindProfile(
        surfaceWindMph: Double,
        surfaceGustMph: Double?,
        alpha: Double = 0.20
    ) -> (w100: Double, w200: Double, w300: Double, w400: Double, gust400: Double?) {
        let w100 = estimateWindAtAltitude(surfaceWindSpeedMph: surfaceWindMph, altitudeFeet: 100, alpha: alpha)
        let w200 = estimateWindAtAltitude(surfaceWindSpeedMph: surfaceWindMph, altitudeFeet: 200, alpha: alpha)
        let w300 = estimateWindAtAltitude(surfaceWindSpeedMph: surfaceWindMph, altitudeFeet: 300, alpha: alpha)
        let w400 = estimateWindAtAltitude(surfaceWindSpeedMph: surfaceWindMph, altitudeFeet: 400, alpha: alpha)

        var gust400: Double? = nil
        if let surfaceGust = surfaceGustMph, surfaceGust > surfaceWindMph {
            gust400 = estimateWindAtAltitude(surfaceWindSpeedMph: surfaceGust, altitudeFeet: 400, alpha: alpha)
        }

        return (w100, w200, w300, w400, gust400)
    }

    // MARK: - Density Altitude & Atmospheric Physics

    /// Calculates Pressure Altitude (PA) in feet:
    /// PA = elevationFeet + (29.92 - altimeterInHg) * 1000
    public static func pressureAltitude(elevationFeet: Double, altimeterInHg: Double) -> Double {
        let pa = elevationFeet + (29.92 - altimeterInHg) * 1000.0
        return pa.rounded()
    }

    /// Calculates standard atmospheric temperature (°C) at a given elevation:
    /// T_std = 15°C - (1.98°C * (elevationFeet / 1000))
    public static func standardTemperatureCelsius(elevationFeet: Double) -> Double {
        let tStd = 15.0 - (1.98 * (elevationFeet / 1000.0))
        return (tStd * 10).rounded() / 10.0
    }

    /// Calculates Density Altitude (DA) in feet:
    /// DA = PA + 118.8 * (T_actual - T_std)
    public static func densityAltitude(
        elevationFeet: Double,
        altimeterInHg: Double,
        actualTempCelsius: Double
    ) -> Double {
        let pa = pressureAltitude(elevationFeet: elevationFeet, altimeterInHg: altimeterInHg)
        let tStd = standardTemperatureCelsius(elevationFeet: elevationFeet)
        let da = pa + 118.8 * (actualTempCelsius - tStd)
        return da.rounded()
    }

    /// Estimates percentage degradation in rotor thrust efficiency based on high density altitude.
    /// Baseline: ~3% degradation per 1,000 ft above standard sea level; noticeable above 3,000 ft.
    public static func thrustDegradationPercentage(densityAltitudeFeet: Double) -> Double? {
        guard densityAltitudeFeet > 3000 else { return nil }
        let excessAltitude = densityAltitudeFeet - 1000
        let loss = min(35.0, (excessAltitude / 1000.0) * 3.5)
        return (loss * 10).rounded() / 10.0
    }

    // MARK: - Unit Conversion Helpers

    public static func knotsToMph(_ knots: Double) -> Double {
        (knots * 1.15078 * 10).rounded() / 10.0
    }

    public static func mphToKnots(_ mph: Double) -> Double {
        (mph * 0.868976 * 10).rounded() / 10.0
    }

    public static func hpaToInHg(_ hpa: Double) -> Double {
        (hpa * 0.02953 * 100).rounded() / 100.0
    }

    public static func metersToFeet(_ meters: Double) -> Double {
        (meters * 3.28084).rounded()
    }

    // MARK: - FAA § 107.29 Solar & Civil Twilight Calculator

    /// Calculates sunrise, sunset, and civil twilight boundaries for FAA § 107.29 operations.
    public static func solarTimes(latitude: Double, longitude: Double, date: Date = Date()) -> SolarTimesResult {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        let dayOfYear = Double(calendar.ordinality(of: .day, in: .year, for: date) ?? 1)
        let startOfDay = calendar.startOfDay(for: date)

        let pi = Double.pi
        let degToRad = pi / 180.0
        let radToDeg = 180.0 / pi

        // Solar declination (approx in radians)
        let dec = -23.44 * cos(2.0 * pi / 365.0 * (dayOfYear + 10.0)) * degToRad

        // Equation of time (minutes)
        let b = 2.0 * pi * (dayOfYear - 81.0) / 365.0
        let eot = 9.87 * sin(2.0 * b) - 7.53 * cos(b) - 1.5 * sin(b)

        // Solar noon in UTC hours
        let solarNoonHours = (720.0 - (4.0 * longitude) - eot) / 60.0

        let latRad = latitude * degToRad

        func hourAngle(forZenithDeg zenithDeg: Double) -> Double? {
            let zenithRad = zenithDeg * degToRad
            let cosH = (cos(zenithRad) - (sin(latRad) * sin(dec))) / (cos(latRad) * cos(dec))
            if cosH > 1.0 || cosH < -1.0 { return nil }
            return acos(cosH) * radToDeg / 15.0
        }

        let hSunrise = hourAngle(forZenithDeg: 90.833) ?? 6.0
        let hCivil = hourAngle(forZenithDeg: 96.0) ?? (hSunrise + 0.5)

        let dawn = startOfDay.addingTimeInterval((solarNoonHours - hCivil) * 3600.0)
        let sunrise = startOfDay.addingTimeInterval((solarNoonHours - hSunrise) * 3600.0)
        let sunset = startOfDay.addingTimeInterval((solarNoonHours + hSunrise) * 3600.0)
        let dusk = startOfDay.addingTimeInterval((solarNoonHours + hCivil) * 3600.0)

        let status: SolarFlightStatus
        if date >= sunrise && date <= sunset {
            status = .daylight
        } else if (date >= dawn && date < sunrise) || (date > sunset && date <= dusk) {
            status = .civilTwilight
        } else {
            status = .night
        }

        return SolarTimesResult(dawn: dawn, sunrise: sunrise, sunset: sunset, dusk: dusk, status: status)
    }
}
