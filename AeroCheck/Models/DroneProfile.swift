//
//  DroneProfile.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation

/// Specification profile for UAS aircraft evaluated against environmental risk limits.
public struct DroneProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var weightGrams: Double
    public var maxWindResistanceMph: Double
    public var maxOperatingTempC: Double
    public var minOperatingTempC: Double
    public var category: String

    public init(
        id: String = UUID().uuidString,
        name: String,
        weightGrams: Double,
        maxWindResistanceMph: Double,
        maxOperatingTempC: Double,
        minOperatingTempC: Double,
        category: String
    ) {
        self.id = id
        self.name = name
        self.weightGrams = weightGrams
        self.maxWindResistanceMph = maxWindResistanceMph
        self.maxOperatingTempC = maxOperatingTempC
        self.minOperatingTempC = minOperatingTempC
        self.category = category
    }

    /// Preloaded standard factory drone specifications covering all famous DJI models.
    public static let standardProfiles: [DroneProfile] = [
        // Sub-250g Ultralight Series
        DroneProfile(
            id: "dji-mini-4-pro",
            name: "DJI Mini 4 Pro",
            weightGrams: 249,
            maxWindResistanceMph: 24.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Sub-250g / Cat 1 Eligible"
        ),
        DroneProfile(
            id: "dji-mini-3-pro",
            name: "DJI Mini 3 Pro",
            weightGrams: 249,
            maxWindResistanceMph: 24.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Sub-250g / Cat 1 Eligible"
        ),
        DroneProfile(
            id: "dji-mini-2-se",
            name: "DJI Mini 2 SE",
            weightGrams: 246,
            maxWindResistanceMph: 24.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: 0.0,
            category: "Sub-250g Ultralight"
        ),
        DroneProfile(
            id: "dji-neo",
            name: "DJI Neo",
            weightGrams: 135,
            maxWindResistanceMph: 18.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Sub-250g / Palm Launch"
        ),

        // Air Series
        DroneProfile(
            id: "dji-air-3",
            name: "DJI Air 3",
            weightGrams: 720,
            maxWindResistanceMph: 27.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Dual Camera Mid-Weight"
        ),
        DroneProfile(
            id: "dji-air-2s",
            name: "DJI Air 2S",
            weightGrams: 595,
            maxWindResistanceMph: 24.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: 0.0,
            category: "1-inch Sensor Commercial"
        ),

        // Mavic 3 Flagship Series
        DroneProfile(
            id: "dji-mavic-3-pro",
            name: "DJI Mavic 3 Pro",
            weightGrams: 958,
            maxWindResistanceMph: 27.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Triple Camera Flagship"
        ),
        DroneProfile(
            id: "dji-mavic-3-classic",
            name: "DJI Mavic 3 Classic",
            weightGrams: 895,
            maxWindResistanceMph: 27.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Hasselblad Commercial"
        ),
        DroneProfile(
            id: "dji-mavic-3-enterprise",
            name: "DJI Mavic 3 Enterprise (3E/3T)",
            weightGrams: 915,
            maxWindResistanceMph: 27.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Enterprise RTK / Thermal"
        ),

        // FPV & Cinewhoop Series
        DroneProfile(
            id: "dji-avata-2",
            name: "DJI Avata 2",
            weightGrams: 377,
            maxWindResistanceMph: 24.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "FPV Cinewhoop"
        ),
        DroneProfile(
            id: "dji-avata",
            name: "DJI Avata",
            weightGrams: 410,
            maxWindResistanceMph: 24.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "FPV Cinewhoop"
        ),

        // Cinema & Heavy Enterprise Series
        DroneProfile(
            id: "dji-inspire-3",
            name: "DJI Inspire 3",
            weightGrams: 3995,
            maxWindResistanceMph: 31.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -20.0,
            category: "8K Full-Frame Cinema"
        ),
        DroneProfile(
            id: "dji-matrice-30t",
            name: "DJI Matrice 30T",
            weightGrams: 3770,
            maxWindResistanceMph: 33.5,
            maxOperatingTempC: 50.0,
            minOperatingTempC: -20.0,
            category: "Compact Enterprise IP55"
        ),
        DroneProfile(
            id: "dji-matrice-350-rtk",
            name: "DJI Matrice 350 RTK",
            weightGrams: 6470,
            maxWindResistanceMph: 33.5,
            maxOperatingTempC: 50.0,
            minOperatingTempC: -20.0,
            category: "Heavy Industrial IP55"
        ),

        // Custom FPV
        DroneProfile(
            id: "custom-5in-fpv",
            name: "Custom 5-inch FPV Quad",
            weightGrams: 680,
            maxWindResistanceMph: 35.0,
            maxOperatingTempC: 45.0,
            minOperatingTempC: -5.0,
            category: "FPV Acro / Freestyle"
        )
    ]

    public static var `default`: DroneProfile {
        standardProfiles[0]
    }
}
