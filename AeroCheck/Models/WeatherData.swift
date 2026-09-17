//
//  WeatherData.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation

/// FAA Flight Category for visual vs instrument flight rules.
public nonisolated enum FlightCategory: String, Codable, Sendable {
    case vfr = "VFR"
    case mvfr = "MVFR"
    case ifr = "IFR"
    case lifr = "LIFR"
    case unknown = "UNKNOWN"

    public var title: String {
        switch self {
        case .vfr: return "Visual Flight Rules (VFR)"
        case .mvfr: return "Marginal VFR (MVFR)"
        case .ifr: return "Instrument Flight Rules (IFR)"
        case .lifr: return "Low IFR (LIFR)"
        case .unknown: return "VFR (Assumed)"
        }
    }
}

/// Raw DTO representing individual cloud layer from NOAA METAR JSON.
nonisolated public struct NOAACloudLayer: Codable, Sendable {
    public let cover: String?
    public let base: Int?

    public init(cover: String? = nil, base: Int? = nil) {
        self.cover = cover
        self.base = base
    }
}

/// Raw DTO parsed from NOAA Aviation Weather Center JSON API.
nonisolated public struct NOAAMetarItem: Codable, Sendable {
    public let icaoId: String?
    public let obsTime: Int?
    public let reportTime: String?
    public let temp: Double?
    public let dewp: Double?
    public let wspd: Double? // knots
    public let wgst: Double? // knots
    public let wdir: AnyCodableValue? // degrees or "VRB"
    public let visib: AnyCodableValue? // SM
    public let altim: Double? // hPa or inHg
    public let ceil: Double? // hundreds of feet (e.g., 25 = 2500ft)
    public let fltcat: String?
    public let fltCat: String?
    public let cover: String?
    public let clouds: [NOAACloudLayer]?
    public let rawOb: String?
    public let lat: Double?
    public let lon: Double?
    public let elev: Double? // meters
}

/// Open-Meteo Hourly Forecast DTO.
nonisolated public struct OpenMeteoForecastResponse: Codable, Sendable {
    public let hourly: OpenMeteoHourlyData?
}

nonisolated public struct OpenMeteoHourlyData: Codable, Sendable {
    public let time: [String]?
    public let wind_speed_10m: [Double?]?
    public let wind_speed_80m: [Double?]?
    public let wind_speed_120m: [Double?]?
    public let wind_gusts_10m: [Double?]?
    public let temperature_2m: [Double?]?
}

/// Unified, processed aviation weather report ready for UI and risk evaluation.
nonisolated public struct AviationWeatherReport: Codable, Sendable {
    public let stationId: String
    public let observationTime: Date
    public let rawMetar: String
    public let surfaceWindSpeedMph: Double
    public let surfaceWindGustMph: Double?
    public let windDirectionDegrees: Int?
    public let flightCategory: FlightCategory
    public let cloudCeilingFeet: Int? // nil = clear / unlimited
    public let visibilityStatuteMiles: Double
    public let temperatureCelsius: Double
    public let dewpointCelsius: Double?
    public let altimeterInHg: Double
    public let elevationFeet: Double
    
    // Altitude wind profile (up to 400ft AGL Part 107 legal ceiling)
    public let wind100ftMph: Double
    public let wind200ftMph: Double
    public let wind300ftMph: Double
    public let wind400ftMph: Double
    public let windGust400ftMph: Double?
    public let isHighAltitudeModelLive: Bool // true: Open-Meteo, false: Hellmann derived

    public nonisolated init(
        stationId: String,
        observationTime: Date,
        rawMetar: String,
        surfaceWindSpeedMph: Double,
        surfaceWindGustMph: Double?,
        windDirectionDegrees: Int?,
        flightCategory: FlightCategory,
        cloudCeilingFeet: Int?,
        visibilityStatuteMiles: Double,
        temperatureCelsius: Double,
        dewpointCelsius: Double?,
        altimeterInHg: Double,
        elevationFeet: Double,
        wind100ftMph: Double,
        wind200ftMph: Double,
        wind300ftMph: Double,
        wind400ftMph: Double,
        windGust400ftMph: Double?,
        isHighAltitudeModelLive: Bool
    ) {
        self.stationId = stationId
        self.observationTime = observationTime
        self.rawMetar = rawMetar
        self.surfaceWindSpeedMph = surfaceWindSpeedMph
        self.surfaceWindGustMph = surfaceWindGustMph
        self.windDirectionDegrees = windDirectionDegrees
        self.flightCategory = flightCategory
        self.cloudCeilingFeet = cloudCeilingFeet
        self.visibilityStatuteMiles = visibilityStatuteMiles
        self.temperatureCelsius = temperatureCelsius
        self.dewpointCelsius = dewpointCelsius
        self.altimeterInHg = altimeterInHg
        self.elevationFeet = elevationFeet
        self.wind100ftMph = wind100ftMph
        self.wind200ftMph = wind200ftMph
        self.wind300ftMph = wind300ftMph
        self.wind400ftMph = wind400ftMph
        self.windGust400ftMph = windGust400ftMph
        self.isHighAltitudeModelLive = isHighAltitudeModelLive
    }

    /// Default baseline weather for previews or offline initialization.
    public nonisolated static var sampleVFR: AviationWeatherReport {
        AviationWeatherReport(
            stationId: "KSFO",
            observationTime: Date(),
            rawMetar: "KSFO 162100Z 28012G18KT 10SM FEW025 18/11 A2994",
            surfaceWindSpeedMph: 13.8,
            surfaceWindGustMph: 20.7,
            windDirectionDegrees: 280,
            flightCategory: .vfr,
            cloudCeilingFeet: 2500,
            visibilityStatuteMiles: 10.0,
            temperatureCelsius: 18.0,
            dewpointCelsius: 11.0,
            altimeterInHg: 29.94,
            elevationFeet: 13.0,
            wind100ftMph: 17.2,
            wind200ftMph: 19.8,
            wind300ftMph: 21.5,
            wind400ftMph: 22.8,
            windGust400ftMph: 26.2,
            isHighAltitudeModelLive: true
        )
    }
}
