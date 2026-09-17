//
//  FAADataService.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation
import CoreLocation

/// Public FAA ArcGIS REST API interface for UAS Facility Maps (UASFM) and Controlled Airspace boundaries.
public actor FAADataService {
    public static let shared = FAADataService()

    private let uasfmEndpoint = "https://services6.arcgis.com/ssFJjBtikUpload/arcgis/rest/services/UASFM_Admin_Feature_Layer/FeatureServer/0/query"
    private let controlledAirspaceEndpoint = "https://services6.arcgis.com/ssFJjBtikUpload/arcgis/rest/services/Controlled_Airspace/FeatureServer/0/query"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Evaluates airspace status at given GPS coordinates by querying FAA ArcGIS services concurrently.
    public func fetchAirspaceStatus(coordinate: CLLocationCoordinate2D) async -> AirspaceEvaluation {
        async let uasfmQuery = queryArcGIS(endpoint: uasfmEndpoint, coordinate: coordinate)
        async let controlledQuery = queryArcGIS(endpoint: controlledAirspaceEndpoint, coordinate: coordinate)

        let (uasfmResult, controlledResult) = await (uasfmQuery, controlledQuery)

        return parseAirspaceResults(
            uasfmFeatures: uasfmResult?.features,
            controlledFeatures: controlledResult?.features,
            coordinate: coordinate
        )
    }

    // MARK: - ArcGIS REST Query Helper

    private func queryArcGIS(endpoint: String, coordinate: CLLocationCoordinate2D) async -> ArcGISQueryResponse? {
        guard var components = URLComponents(string: endpoint) else { return nil }

        components.queryItems = [
            URLQueryItem(name: "geometry", value: "\(coordinate.longitude),\(coordinate.latitude)"),
            URLQueryItem(name: "geometryType", value: "esriGeometryPoint"),
            URLQueryItem(name: "inSR", value: "4326"),
            URLQueryItem(name: "spatialRel", value: "esriSpatialRelIntersects"),
            URLQueryItem(name: "outFields", value: "*"),
            URLQueryItem(name: "returnGeometry", value: "false"),
            URLQueryItem(name: "f", value: "pjson")
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
            let decoded = try JSONDecoder().decode(ArcGISQueryResponse.self, from: data)
            return decoded
        } catch {
            // Non-critical network error; return nil to allow graceful fallback
            return nil
        }
    }

    // MARK: - Result Parsing

    private func parseAirspaceResults(
        uasfmFeatures: [ArcGISFeature]?,
        controlledFeatures: [ArcGISFeature]?,
        coordinate: CLLocationCoordinate2D
    ) -> AirspaceEvaluation {
        var ceiling: Int? = nil
        var detectedClass: AirspaceClass = .classG
        var facilityName: String? = nil
        var airportIdent: String? = nil

        // 1. Inspect UASFM Feature Layer (highest authority for UAS grid ceilings)
        if let uasfmFeature = uasfmFeatures?.first, let attrs = uasfmFeature.attributes {
            if let ceilVal = attrs["CEILING"]?.intValue {
                ceiling = ceilVal
            } else if let ceilStr = attrs["CEILING"]?.stringValue, let ceilInt = Int(ceilStr) {
                ceiling = ceilInt
            }

            if let name = attrs["NAME"]?.stringValue ?? attrs["AIRPORT_NAME"]?.stringValue {
                facilityName = name
            }

            if let ident = attrs["IDENT"]?.stringValue ?? attrs["ICAO_ID"]?.stringValue {
                airportIdent = ident
            }

            if let clsStr = attrs["AIRSPACE_CLASS"]?.stringValue?.uppercased() {
                detectedClass = AirspaceClass(rawValue: clsStr) ?? .classD
            } else {
                detectedClass = .classD // Controlled default when inside UASFM grid
            }
        }

        // 2. Inspect Controlled Airspace Boundaries if not fully resolved
        if let controlledFeature = controlledFeatures?.first, let attrs = controlledFeature.attributes {
            if detectedClass == .classG {
                if let cls = attrs["AIRSPACE_CLASS"]?.stringValue ?? attrs["CLASS"]?.stringValue {
                    let upper = cls.uppercased()
                    detectedClass = AirspaceClass(rawValue: upper) ?? .classD
                }
            }
            if facilityName == nil {
                facilityName = attrs["NAME"]?.stringValue
            }
            if airportIdent == nil {
                airportIdent = attrs["IDENT"]?.stringValue
            }
        }

        // If no controlled airspace records matched, location is standard Class G
        if uasfmFeatures?.isEmpty ?? true && controlledFeatures?.isEmpty ?? true {
            return AirspaceEvaluation(
                airspaceClass: .classG,
                uasfmCeilingFeet: 400,
                facilityName: "Class G Uncontrolled",
                airportIdent: nil,
                requiresLAANC: false,
                isZeroCeiling: false,
                regulatoryNote: "Class G Airspace: Fly up to 400 ft AGL under § 107.51 without LAANC authorization."
            )
        }

        let isControlled = detectedClass.isControlled
        let isZero = (ceiling == 0)
        let note: String

        if isControlled {
            if isZero {
                note = "CRITICAL: 0 ft UASFM ceiling at \(airportIdent ?? "Airport"). Standard LAANC auto-approval disabled. Advanced ATC waiver required."
            } else if let c = ceiling {
                note = "Controlled \(detectedClass.title): LAANC authorization required prior to flight up to \(c) ft AGL ceiling."
            } else {
                note = "Controlled \(detectedClass.title): LAANC authorization required prior to flight."
            }
        } else {
            note = "Uncontrolled Airspace: Legal up to 400 ft AGL under Part 107."
        }

        return AirspaceEvaluation(
            airspaceClass: detectedClass,
            uasfmCeilingFeet: ceiling,
            facilityName: facilityName,
            airportIdent: airportIdent,
            requiresLAANC: isControlled,
            isZeroCeiling: isZero,
            regulatoryNote: note
        )
    }
}
