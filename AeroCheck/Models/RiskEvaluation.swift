//
//  RiskEvaluation.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation
import SwiftUI

/// Master Go / Caution / No-Go verdict conforming to FAA Part 107 RAM requirements.
public enum RiskVerdict: String, Codable, Sendable {
    case safe = "GO"
    case caution = "CAUTION"
    case noGo = "NO-GO"

    public var title: String {
        switch self {
        case .safe: return "GO / FLIGHT APPROVED"
        case .caution: return "CAUTION / RESTRICTIONS APPLY"
        case .noGo: return "NO-GO / CRITICAL VIOLATION"
        }
    }

    public var systemIcon: String {
        switch self {
        case .safe: return "checkmark.seal.fill"
        case .caution: return "exclamationmark.triangle.fill"
        case .noGo: return "xmark.octagon.fill"
        }
    }
}

/// Category of risk evaluated by the RAM engine.
public enum RiskCategory: String, Codable, Sendable {
    case airspace = "Airspace Authorization"
    case visibility = "Flight Visibility"
    case cloudCeiling = "Cloud Clearance"
    case windAloft = "Wind & Shear at 400ft"
    case densityAltitude = "Density Altitude & Thrust"
    case temperature = "Aircraft Operating Temp"
    case solarLighting = "Daylight & Lighting (§ 107.29)"
}

/// A specific evaluated factor row in the RAM.
public struct RiskFactorItem: Identifiable, Codable, Sendable {
    public let id: String
    public let category: RiskCategory
    public let severity: RiskVerdict
    public let summary: String
    public let regulatoryReference: String // e.g. "FAA § 107.51", "FAA § 107.41"

    public init(
        id: String = UUID().uuidString,
        category: RiskCategory,
        severity: RiskVerdict,
        summary: String,
        regulatoryReference: String
    ) {
        self.id = id
        self.category = category
        self.severity = severity
        self.summary = summary
        self.regulatoryReference = regulatoryReference
    }
}

/// Comprehensive risk assessment produced by `RiskEngine`.
public struct RiskAssessmentResult: Codable, Sendable {
    public let overallVerdict: RiskVerdict
    public let primaryHeadline: String
    public let detailedRationale: String
    public let factors: [RiskFactorItem]
    public let densityAltitudeFeet: Double
    public let pressureAltitudeFeet: Double
    public let thrustEfficiencyLossPercent: Double? // e.g., 14.5% if DA > 4000ft
    public let generatedAt: Date

    public init(
        overallVerdict: RiskVerdict,
        primaryHeadline: String,
        detailedRationale: String,
        factors: [RiskFactorItem],
        densityAltitudeFeet: Double,
        pressureAltitudeFeet: Double,
        thrustEfficiencyLossPercent: Double?,
        generatedAt: Date = Date()
    ) {
        self.overallVerdict = overallVerdict
        self.primaryHeadline = primaryHeadline
        self.detailedRationale = detailedRationale
        self.factors = factors
        self.densityAltitudeFeet = densityAltitudeFeet
        self.pressureAltitudeFeet = pressureAltitudeFeet
        self.thrustEfficiencyLossPercent = thrustEfficiencyLossPercent
        self.generatedAt = generatedAt
    }
}
