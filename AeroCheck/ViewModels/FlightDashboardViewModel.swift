//
//  FlightDashboardViewModel.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation
import CoreLocation
import SwiftUI
import Combine

/// Central coordinator driving the main Flight Dashboard, orchestrating concurrent API fetches,
/// risk assessment evaluation, drone profile management, and PDF generation.
@Observable
public final class FlightDashboardViewModel: @unchecked Sendable {
    public var locationManager = LocationManager()
    
    // State
    public var selectedDrone: DroneProfile
    public var droneProfiles: [DroneProfile]
    public var airspace: AirspaceEvaluation?
    public var weather: AviationWeatherReport?
    public var riskResult: RiskAssessmentResult?
    
    public var isLoading: Bool = false
    public var lastUpdated: Date?
    public var errorMessage: String?
    
    // Terrain and operational variables
    public var terrainRoughness: TerrainRoughness = .suburban
    
    // Pre-Flight Sign-off & Modals
    public var signOffRecord: PreFlightSignOffRecord = PreFlightSignOffRecord()
    public var generatedPDFData: Data?
    public var showChecklistSheet: Bool = false
    public var showPDFShareSheet: Bool = false
    public var showDronePickerSheet: Bool = false
    public var showCoordinateSheet: Bool = false

    private var hasInitialized = false

    public init() {
        let loadedProfiles: [DroneProfile]
        if let savedData = UserDefaults.standard.data(forKey: "aerocheck.droneProfiles"),
           let decoded = try? JSONDecoder().decode([DroneProfile].self, from: savedData) {
            loadedProfiles = decoded
        } else {
            loadedProfiles = DroneProfile.standardProfiles
        }
        self.droneProfiles = loadedProfiles

        if let savedSelectedId = UserDefaults.standard.string(forKey: "aerocheck.selectedDroneId"),
           let match = loadedProfiles.first(where: { $0.id == savedSelectedId }) {
            self.selectedDrone = match
        } else {
            self.selectedDrone = loadedProfiles.first ?? DroneProfile.default
        }
    }

    /// Initializes location updates and performs initial data fetch.
    public func onAppear() {
        guard !hasInitialized else { return }
        hasInitialized = true
        locationManager.requestCurrentLocation()
    }

    /// Triggers concurrent data fetching across FAA ArcGIS and NOAA/Open-Meteo services.
    public func refreshData() async {
        guard let coord = locationManager.coordinate else {
            // Request coordinate fix first
            locationManager.requestCurrentLocation()
            return
        }

        isLoading = true
        errorMessage = nil

        async let airspaceFetch = FAADataService.shared.fetchAirspaceStatus(coordinate: coord)
        async let weatherFetch = WeatherService.shared.fetchWeather(coordinate: coord)

        let (fetchedAirspace, fetchedWeather) = await (airspaceFetch, weatherFetch)

        self.airspace = fetchedAirspace
        self.weather = fetchedWeather

        // Evaluate RAM risk matrix against active aircraft specs
        self.riskResult = RiskEngine.evaluateRisk(
            airspace: fetchedAirspace,
            weather: fetchedWeather,
            drone: selectedDrone
        )

        self.lastUpdated = Date()
        self.isLoading = false
    }

    /// Selects active aircraft profile and re-evaluates risk.
    public func selectDrone(_ drone: DroneProfile) {
        self.selectedDrone = drone
        UserDefaults.standard.set(drone.id, forKey: "aerocheck.selectedDroneId")

        if let air = airspace, let w = weather {
            self.riskResult = RiskEngine.evaluateRisk(airspace: air, weather: w, drone: drone)
        }
    }

    /// Adds custom drone profile.
    public func addCustomDrone(_ profile: DroneProfile) {
        droneProfiles.append(profile)
        if let encoded = try? JSONEncoder().encode(droneProfiles) {
            UserDefaults.standard.set(encoded, forKey: "aerocheck.droneProfiles")
        }
        selectDrone(profile)
    }

    /// Launches native LAANC USS app or opens web fallback.
    public func openLAANCProvider() {
        guard let autopylotUrl = URL(string: "autopylot://") else { return }
        UIApplication.shared.open(autopylotUrl, options: [:]) { success in
            if !success {
                // Fallback to web portal
                if let webUrl = URL(string: "https://www.autopylot.io") {
                    UIApplication.shared.open(webUrl)
                }
            }
        }
    }

    /// Generates audit-ready PDF document and displays share sheet.
    public func generateAuditPDF() {
        guard let air = airspace,
              let w = weather,
              let r = riskResult,
              let coord = locationManager.coordinate else {
            return
        }

        let pdf = PDFReportGenerator.generateComplianceReport(
            airspace: air,
            weather: w,
            drone: selectedDrone,
            risk: r,
            signOff: signOffRecord,
            locationCoordinate: coord,
            locationAddress: locationManager.placemarkName
        )

        self.generatedPDFData = pdf
        self.showPDFShareSheet = true
    }
}
