//
//  AirspaceData.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation

/// Airspace classification based on FAA regulations (Part 107.41 / AIM).
public enum AirspaceClass: String, Codable, Sendable {
    case classB = "B"
    case classC = "C"
    case classD = "D"
    case classE2 = "E2" // Surface Class E
    case classE = "E"
    case classG = "G"   // Uncontrolled
    case specialUse = "SUA"
    case unknown = "UNKNOWN"

    public var title: String {
        switch self {
        case .classB: return "Class B Controlled"
        case .classC: return "Class C Controlled"
        case .classD: return "Class D Controlled"
        case .classE2, .classE: return "Class E Surface"
        case .classG: return "Class G Uncontrolled"
        case .specialUse: return "Special Use Airspace"
        case .unknown: return "Class G / Unclassified"
        }
    }

    public var badgeLabel: String {
        switch self {
        case .classB: return "CLASS B"
        case .classC: return "CLASS C"
        case .classD: return "CLASS D"
        case .classE2, .classE: return "CLASS E"
        case .classG: return "CLASS G"
        case .specialUse: return "SPECIAL USE"
        case .unknown: return "CLASS G"
        }
    }

    /// Whether operation requires ATC / LAANC authorization prior to flight (§ 107.41).
    public var isControlled: Bool {
        switch self {
        case .classB, .classC, .classD, .classE2:
            return true
        case .classE, .classG, .specialUse, .unknown:
            return false
        }
    }
}

/// Consolidated airspace authorization status at the current coordinate.
public struct AirspaceEvaluation: Codable, Sendable {
    public let airspaceClass: AirspaceClass
    public let uasfmCeilingFeet: Int? // 0, 50, 100, 200, 300, 400, or nil if Class G
    public let facilityName: String?
    public let airportIdent: String?
    public let requiresLAANC: Bool
    public let isZeroCeiling: Bool
    public let regulatoryNote: String

    public init(
        airspaceClass: AirspaceClass,
        uasfmCeilingFeet: Int?,
        facilityName: String?,
        airportIdent: String?,
        requiresLAANC: Bool,
        isZeroCeiling: Bool,
        regulatoryNote: String
    ) {
        self.airspaceClass = airspaceClass
        self.uasfmCeilingFeet = uasfmCeilingFeet
        self.facilityName = facilityName
        self.airportIdent = airportIdent
        self.requiresLAANC = requiresLAANC
        self.isZeroCeiling = isZeroCeiling
        self.regulatoryNote = regulatoryNote
    }

    /// Default Class G uncontrolled airspace model (standard open airspace).
    public static var classGDefault: AirspaceEvaluation {
        AirspaceEvaluation(
            airspaceClass: .classG,
            uasfmCeilingFeet: 400,
            facilityName: "Uncontrolled Airspace",
            airportIdent: nil,
            requiresLAANC: false,
            isZeroCeiling: false,
            regulatoryNote: "Class G Airspace: Fly up to 400 ft AGL without prior ATC or LAANC authorization."
        )
    }
}

// MARK: - ArcGIS REST Response DTOs

nonisolated public struct ArcGISQueryResponse: Codable, Sendable {
    public let features: [ArcGISFeature]?
    public let error: ArcGISError?
}

nonisolated public struct ArcGISError: Codable, Sendable {
    public let code: Int?
    public let message: String?
}

nonisolated public struct ArcGISFeature: Codable, Sendable {
    public let attributes: [String: AnyCodableValue]?
}

/// Flexible JSON decoder helper for ArcGIS attribute dictionary values.
nonisolated public enum AnyCodableValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .null: try container.encodeNil()
        }
    }

    public var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        case .null: return nil
        }
    }

    public var intValue: Int? {
        switch self {
        case .int(let i): return i
        case .double(let d): return Int(d)
        case .string(let s): return Int(s)
        case .bool, .null: return nil
        }
    }

    public var doubleValue: Double? {
        switch self {
        case .double(let d): return d
        case .int(let i): return Double(i)
        case .string(let s): return Double(s)
        case .bool, .null: return nil
        }
    }
}
