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

    /// Preloaded standard factory drone specifications.
    public static let standardProfiles: [DroneProfile] = [
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
            id: "dji-air-3",
            name: "DJI Air 3",
            weightGrams: 720,
            maxWindResistanceMph: 27.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Standard Commercial"
        ),
        DroneProfile(
            id: "dji-mavic-3-pro",
            name: "DJI Mavic 3 Pro / Enterprise",
            weightGrams: 958,
            maxWindResistanceMph: 27.0,
            maxOperatingTempC: 40.0,
            minOperatingTempC: -10.0,
            category: "Standard Commercial"
        ),
        DroneProfile(
            id: "dji-matrice-350-rtk",
            name: "DJI Matrice 350 RTK",
            weightGrams: 6470,
            maxWindResistanceMph: 33.5,
            maxOperatingTempC: 50.0,
            minOperatingTempC: -20.0,
            category: "Heavy Enterprise / IP55"
        ),
        DroneProfile(
            id: "custom-5in-fpv",
            name: "Custom 5-inch FPV Quad",
            weightGrams: 680,
            maxWindResistanceMph: 35.0,
            maxOperatingTempC: 45.0,
            minOperatingTempC: -5.0,
            category: "FPV Acro / Cinematic"
        )
    ]

    public static var `default`: DroneProfile {
        standardProfiles[0]
    }
}
