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
    public var plannedAltitudeFeet: Int = 400

    public var relativeLastUpdatedString: String {
        guard let last = lastUpdated else { return "Awaiting fix" }
        let diff = max(0, Int(-last.timeIntervalSinceNow))
        if diff < 15 {
            return "Live"
        } else if diff < 60 {
            return "\(diff)s ago"
        } else if diff < 3600 {
            return "\(diff / 60)m ago"
        } else {
            return "\(diff / 3600)h ago"
        }
    }
    
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
        let savedCustom: [DroneProfile]
        if let savedData = UserDefaults.standard.data(forKey: "aerocheck.droneProfiles"),
           let decoded = try? JSONDecoder().decode([DroneProfile].self, from: savedData) {
            savedCustom = decoded.filter { saved in !DroneProfile.standardProfiles.contains(where: { $0.id == saved.id }) }
        } else {
            savedCustom = []
        }
        let merged = DroneProfile.standardProfiles + savedCustom
        self.droneProfiles = merged

        if let savedSelectedId = UserDefaults.standard.string(forKey: "aerocheck.selectedDroneId"),
           let match = merged.first(where: { $0.id == savedSelectedId }) {
            self.selectedDrone = match
        } else {
            self.selectedDrone = merged.first ?? DroneProfile.default
        }

        let savedPilotName = UserDefaults.standard.string(forKey: "aerocheck.pilotName") ?? ""
        let savedCertNum = UserDefaults.standard.string(forKey: "aerocheck.certificateNumber") ?? ""
        self.signOffRecord = PreFlightSignOffRecord(
            pilotName: savedPilotName,
            remotePilotCertificateNumber: savedCertNum
        )
    }

    public func savePilotCredentials() {
        UserDefaults.standard.set(signOffRecord.pilotName, forKey: "aerocheck.pilotName")
        UserDefaults.standard.set(signOffRecord.remotePilotCertificateNumber, forKey: "aerocheck.certificateNumber")
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

        // Evaluate RAM risk matrix against active aircraft specs and planned altitude
        self.riskResult = RiskEngine.evaluateRisk(
            airspace: fetchedAirspace,
            weather: fetchedWeather,
            drone: selectedDrone,
            plannedAltitudeFeet: plannedAltitudeFeet
        )

        self.lastUpdated = Date()
        self.isLoading = false
    }

    /// Sets planned mission altitude (AGL) and re-evaluates risk matrix against wind profile.
    public func setPlannedAltitude(_ altitude: Int) {
        self.plannedAltitudeFeet = altitude
        if let air = airspace, let w = weather {
            self.riskResult = RiskEngine.evaluateRisk(
                airspace: air,
                weather: w,
                drone: selectedDrone,
                plannedAltitudeFeet: altitude
            )
        }
    }

    /// Selects active aircraft profile and re-evaluates risk.
    public func selectDrone(_ drone: DroneProfile) {
        self.selectedDrone = drone
        UserDefaults.standard.set(drone.id, forKey: "aerocheck.selectedDroneId")

        if let air = airspace, let w = weather {
            self.riskResult = RiskEngine.evaluateRisk(
                airspace: air,
                weather: w,
                drone: drone,
                plannedAltitudeFeet: plannedAltitudeFeet
            )
        }
    }

    /// Adds custom drone profile.
    public func addCustomDrone(_ profile: DroneProfile) {
        droneProfiles.append(profile)
        saveDroneProfiles()
        selectDrone(profile)
    }

    /// Updates existing drone profile (name, limits, etc.).
    public func updateDrone(_ drone: DroneProfile) {
        if let idx = droneProfiles.firstIndex(where: { $0.id == drone.id }) {
            droneProfiles[idx] = drone
            saveDroneProfiles()
            if selectedDrone.id == drone.id {
                selectDrone(drone)
            }
        }
    }

    /// Deletes drone profile.
    public func deleteDrone(_ drone: DroneProfile) {
        droneProfiles.removeAll(where: { $0.id == drone.id })
        saveDroneProfiles()
        if selectedDrone.id == drone.id {
            if let fallback = droneProfiles.first {
                selectDrone(fallback)
            } else {
                selectDrone(DroneProfile.default)
            }
        }
    }

    /// Resets fleet to factory DJI presets.
    public func resetDroneFleetToDefaults() {
        self.droneProfiles = DroneProfile.standardProfiles
        UserDefaults.standard.removeObject(forKey: "aerocheck.droneProfiles")
        selectDrone(DroneProfile.default)
    }

    private func saveDroneProfiles() {
        if let encoded = try? JSONEncoder().encode(droneProfiles) {
            UserDefaults.standard.set(encoded, forKey: "aerocheck.droneProfiles")
        }
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
