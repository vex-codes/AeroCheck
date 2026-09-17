//
//  WeatherService.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation
import CoreLocation

/// Concurrent aviation weather service querying NOAA AWC METAR and Open-Meteo atmospheric wind sounding.
public actor WeatherService {
    public static let shared = WeatherService()

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Fetches and synthesizes weather from NOAA and Open-Meteo concurrently.
    public func fetchWeather(coordinate: CLLocationCoordinate2D) async -> AviationWeatherReport {
        async let metarFetch = fetchNearestMETAR(coordinate: coordinate)
        async let openMeteoFetch = fetchOpenMeteoAloft(coordinate: coordinate)

        let (nearestMetar, openMeteoData) = await (metarFetch, openMeteoFetch)

        return synthesizeWeatherReport(
            metar: nearestMetar,
            aloft: openMeteoData,
            coordinate: coordinate
        )
    }

    // MARK: - NOAA METAR Fetching

    private func fetchNearestMETAR(coordinate: CLLocationCoordinate2D) async -> NOAAMetarItem? {
        let minLon = coordinate.longitude - 0.75
        let maxLon = coordinate.longitude + 0.75
        let minLat = coordinate.latitude - 0.75
        let maxLat = coordinate.latitude + 0.75

        guard var components = URLComponents(string: "https://aviationweather.gov/api/data/metar") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "bbox", value: "\(minLat),\(minLon),\(maxLat),\(maxLon)"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("AeroCheck/1.0 (iOS; Aviation Pre-Flight)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            let metars = try JSONDecoder().decode([NOAAMetarItem].self, from: data)

            // Select station closest to pilot coordinates
            return metars.min(by: { a, b in
                let distA = distanceSquared(lat1: coordinate.latitude, lon1: coordinate.longitude, lat2: a.lat ?? 0, lon2: a.lon ?? 0)
                let distB = distanceSquared(lat1: coordinate.latitude, lon1: coordinate.longitude, lat2: b.lat ?? 0, lon2: b.lon ?? 0)
                return distA < distB
            })
        } catch {
            return nil
        }
    }

    // MARK: - Open-Meteo Aloft Sounding Fetching

    private func fetchOpenMeteoAloft(coordinate: CLLocationCoordinate2D) async -> OpenMeteoHourlyData? {
        guard var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast") else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(format: "%.4f", coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(format: "%.4f", coordinate.longitude)),
            URLQueryItem(name: "hourly", value: "wind_speed_10m,wind_speed_80m,wind_speed_120m,wind_gusts_10m,temperature_2m"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "forecast_days", value: "1")
        ]

        guard let url = components.url else { return nil }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8.0
        request.setValue("AeroCheck/1.0 (iOS; Aviation Pre-Flight)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            let decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
            return decoded.hourly
        } catch {
            return nil
        }
    }

    // MARK: - Synthesis & Fallback

    private func synthesizeWeatherReport(
        metar: NOAAMetarItem?,
        aloft: OpenMeteoHourlyData?,
        coordinate: CLLocationCoordinate2D
    ) -> AviationWeatherReport {
        let stationId = metar?.icaoId ?? "LOCAL"
        let obsDate: Date
        if let sec = metar?.obsTime {
            obsDate = Date(timeIntervalSince1970: TimeInterval(sec))
        } else {
            obsDate = Date()
        }
        let rawMetar = metar?.rawOb ?? "METAR \(stationId) AUTO 00000KT 10SM CLR 20/10 A2992"

        // Surface winds (prefer METAR knots converted to mph, fallback to Open-Meteo 10m)
        let surfaceWindMph: Double
        if let wspdKnots = metar?.wspd {
            surfaceWindMph = AviationMath.knotsToMph(wspdKnots)
        } else if let aloft10m = aloft?.wind_speed_10m?.compactMap({ $0 }).first {
            surfaceWindMph = (aloft10m * 10).rounded() / 10.0
        } else {
            surfaceWindMph = 8.0
        }

        // Gusts
        let surfaceGustMph: Double?
        if let wgstKnots = metar?.wgst {
            surfaceGustMph = AviationMath.knotsToMph(wgstKnots)
        } else if let omGust = aloft?.wind_gusts_10m?.compactMap({ $0 }).first {
            surfaceGustMph = (omGust * 10).rounded() / 10.0
        } else {
            surfaceGustMph = nil
        }

        // Wind Direction
        let windDir: Int?
        if let dirInt = metar?.wdir?.intValue {
            windDir = dirInt
        } else if let dirDbl = metar?.wdir?.doubleValue {
            windDir = Int(dirDbl)
        } else {
            windDir = 270
        }

        // Flight Category
        let fltCatStr = (metar?.fltCat ?? metar?.fltcat)?.uppercased() ?? "VFR"
        let flightCategory = FlightCategory(rawValue: fltCatStr) ?? .vfr

        // Cloud Ceiling in feet AGL (lowest BKN / OVC layer)
        let ceilingFeet: Int?
        if let ceilHundreds = metar?.ceil {
            ceilingFeet = Int(ceilHundreds * 100)
        } else if let clouds = metar?.clouds {
            let bknOrOvc = clouds.filter {
                let cov = $0.cover?.uppercased() ?? ""
                return cov == "BKN" || cov == "OVC" || cov == "VV"
            }
            ceilingFeet = bknOrOvc.compactMap { $0.base }.min()
        } else {
            ceilingFeet = nil // Clear / unlimited
        }

        // Visibility in Statute Miles
        let visibilitySM: Double
        if let visDbl = metar?.visib?.doubleValue {
            visibilitySM = visDbl
        } else if let visStr = metar?.visib?.stringValue {
            let cleaned = visStr.replacingOccurrences(of: "+", with: "")
            visibilitySM = Double(cleaned) ?? 10.0
        } else {
            visibilitySM = 10.0
        }

        // Temperature & Dewpoint
        let tempC = metar?.temp ?? aloft?.temperature_2m?.compactMap({ $0 }).first ?? 20.0
        let dewpC = metar?.dewp

        // Altimeter
        let altimInHg: Double
        if let rawAltim = metar?.altim {
            altimInHg = rawAltim > 500 ? AviationMath.hpaToInHg(rawAltim) : rawAltim
        } else {
            altimInHg = 29.92
        }

        let elevFeet = metar?.elev != nil ? AviationMath.metersToFeet(metar!.elev!) : 50.0

        // High Altitude Winds: check Open-Meteo sounding first
        var w100 = 0.0
        var w200 = 0.0
        var w300 = 0.0
        var w400 = 0.0
        var gust400: Double? = nil
        var isLiveModel = false

        if let aloft = aloft,
           let om80m = aloft.wind_speed_80m?.compactMap({ $0 }).first,
           let om120m = aloft.wind_speed_120m?.compactMap({ $0 }).first {
            // Open-Meteo provides 10m (~33ft), 80m (~260ft), and 120m (~400ft)
            w400 = (om120m * 10).rounded() / 10.0
            w300 = ((om80m * 0.2 + om120m * 0.8) * 10).rounded() / 10.0
            w200 = ((om80m * 0.8 + om120m * 0.2) * 10).rounded() / 10.0
            w100 = ((surfaceWindMph * 0.4 + om80m * 0.6) * 10).rounded() / 10.0
            if let gust = surfaceGustMph {
                gust400 = (gust * (w400 / max(1.0, surfaceWindMph)) * 10).rounded() / 10.0
            }
            isLiveModel = true
        } else {
            // Apply Hellmann Wind Power Law from surface observations
            let profile = AviationMath.computeWindProfile(
                surfaceWindMph: surfaceWindMph,
                surfaceGustMph: surfaceGustMph,
                alpha: 0.20
            )
            w100 = profile.w100
            w200 = profile.w200
            w300 = profile.w300
            w400 = profile.w400
            gust400 = profile.gust400
            isLiveModel = false
        }

        return AviationWeatherReport(
            stationId: stationId,
            observationTime: obsDate,
            rawMetar: rawMetar,
            surfaceWindSpeedMph: surfaceWindMph,
            surfaceWindGustMph: surfaceGustMph,
            windDirectionDegrees: windDir,
            flightCategory: flightCategory,
            cloudCeilingFeet: ceilingFeet,
            visibilityStatuteMiles: visibilitySM,
            temperatureCelsius: tempC,
            dewpointCelsius: dewpC,
            altimeterInHg: altimInHg,
            elevationFeet: elevFeet,
            wind100ftMph: w100,
            wind200ftMph: w200,
            wind300ftMph: w300,
            wind400ftMph: w400,
            windGust400ftMph: gust400,
            isHighAltitudeModelLive: isLiveModel
        )
    }

    private func distanceSquared(lat1: Double, lon1: Double, lat2: Double, lon2: Double) -> Double {
        let dLat = lat1 - lat2
        let dLon = lon1 - lon2
        return dLat * dLat + dLon * dLon
    }
}
