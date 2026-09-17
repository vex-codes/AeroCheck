//
//  PreFlightChecklist.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation

/// FAA Part 107.49 Pre-Flight Inspection item.
public struct ChecklistItem: Identifiable, Codable, Sendable {
    public let id: String
    public let title: String
    public let regulatorySubtitle: String
    public var isCompleted: Bool

    public init(id: String = UUID().uuidString, title: String, regulatorySubtitle: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.regulatorySubtitle = regulatorySubtitle
        self.isCompleted = isCompleted
    }
}

/// Consolidated pre-flight sign-off record for PDF audit generation.
public struct PreFlightSignOffRecord: Codable, Sendable {
    public var pilotName: String
    public var remotePilotCertificateNumber: String
    public var missionPurpose: String
    public var checklistItems: [ChecklistItem]
    public var signatureImageData: Data?
    public var signedAt: Date?

    public init(
        pilotName: String = "",
        remotePilotCertificateNumber: String = "",
        missionPurpose: String = "Commercial Aerial Survey & Mapping",
        checklistItems: [ChecklistItem] = PreFlightSignOffRecord.standardItems,
        signatureImageData: Data? = nil,
        signedAt: Date? = nil
    ) {
        self.pilotName = pilotName
        self.remotePilotCertificateNumber = remotePilotCertificateNumber
        self.missionPurpose = missionPurpose
        self.checklistItems = checklistItems
        self.signatureImageData = signatureImageData
        self.signedAt = signedAt
    }

    public var isAllChecked: Bool {
        checklistItems.allSatisfy { $0.isCompleted }
    }

    /// Standard FAA Part 107.49 pre-flight inspection checklist items.
    public static var standardItems: [ChecklistItem] = [
        ChecklistItem(
            id: "airframe-inspection",
            title: "Airframe & Propellers Inspected",
            regulatorySubtitle: "§ 107.49(a): Free from cracks, warps, motor play, and structural fatigue."
        ),
        ChecklistItem(
            id: "battery-status",
            title: "Power Source & Latches Verified",
            regulatorySubtitle: "§ 107.49(b): Battery securely locked; cells balanced; voltage nominal."
        ),
        ChecklistItem(
            id: "fail-safe-rth",
            title: "Control Links & Fail-Safe RTH Configured",
            regulatorySubtitle: "§ 107.49(c): RTH altitude programmed higher than highest local obstacle."
        ),
        ChecklistItem(
            id: "crew-airspace-briefing",
            title: "Crew Briefing & Non-Participant Clearance",
            regulatorySubtitle: "§ 107.49(d): Visual observer briefed; operational area clear of uninvolved persons."
        )
    ]
}
