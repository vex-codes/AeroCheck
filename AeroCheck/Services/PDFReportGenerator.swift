//
//  PDFReportGenerator.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import Foundation
import UIKit
import PDFKit
import CoreLocation

/// High-fidelity PDF generator creating audit-ready FAA Part 107 Risk Assessment Matrix (RAM) records.
public enum PDFReportGenerator {

    /// Generates a single-page US Letter PDF data document.
    public static func generateComplianceReport(
        airspace: AirspaceEvaluation,
        weather: AviationWeatherReport,
        drone: DroneProfile,
        risk: RiskAssessmentResult,
        signOff: PreFlightSignOffRecord,
        locationCoordinate: CLLocationCoordinate2D,
        locationAddress: String
    ) -> Data {
        // Standard US Letter page bounds: 612 x 792 points (8.5 x 11 inches)
        let pageWidth: CGFloat = 612.0
        let pageHeight: CGFloat = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()
            let cgContext = context.cgContext

            let margin: CGFloat = 36.0
            let contentWidth = pageWidth - (margin * 2)
            var currentY: CGFloat = margin

            // 1. Top Header Banner (AeroCheck Aviation Compliance)
            let headerRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 48)
            cgContext.setFillColor(UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.0).cgColor)
            cgContext.fill(headerRect)

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 15, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: UIColor(red: 0.75, green: 0.85, blue: 0.95, alpha: 1.0)
            ]

            let titleStr = "FAA 14 CFR PART 107 PRE-FLIGHT RISK ASSESSMENT MATRIX (RAM)"
            titleStr.draw(at: CGPoint(x: margin + 12, y: currentY + 8), withAttributes: titleAttrs)

            let dateFormatted = ISO8601DateFormatter().string(from: risk.generatedAt)
            let subTitleStr = "AUDIT LOG #AC-\(abs(dateFormatted.hashValue % 900000) + 100000) • GENERATED: \(dateFormatted)"
            subTitleStr.draw(at: CGPoint(x: margin + 12, y: currentY + 28), withAttributes: subtitleAttrs)

            currentY += 56

            // 2. Verdict Banner Box
            let verdictColor: UIColor
            let verdictText: String
            switch risk.overallVerdict {
            case .safe:
                verdictColor = UIColor(red: 0.13, green: 0.58, blue: 0.28, alpha: 1.0) // Green
                verdictText = "VERDICT: APPROVED FOR FLIGHT (GO)"
            case .caution:
                verdictColor = UIColor(red: 0.85, green: 0.55, blue: 0.08, alpha: 1.0) // Amber
                verdictText = "VERDICT: CAUTION / RESTRICTIONS ACTIVE"
            case .noGo:
                verdictColor = UIColor(red: 0.80, green: 0.15, blue: 0.15, alpha: 1.0) // Red
                verdictText = "VERDICT: FLIGHT PROHIBITED (NO-GO)"
            }

            let verdictRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 32)
            cgContext.setFillColor(verdictColor.cgColor)
            cgContext.fill(verdictRect)

            let verdictAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .black),
                .foregroundColor: UIColor.white
            ]
            verdictText.draw(at: CGPoint(x: margin + 12, y: currentY + 9), withAttributes: verdictAttrs)

            currentY += 40

            // 3. Grid: Pilot / Mission & Aircraft Information
            let colWidth = (contentWidth - 12) / 2
            let infoBoxHeight: CGFloat = 80

            // Left Col: Pilot & Location
            let leftBoxRect = CGRect(x: margin, y: currentY, width: colWidth, height: infoBoxHeight)
            drawBorderedBox(context: cgContext, rect: leftBoxRect)
            drawSectionHeader("PILOT & MISSION IDENTIFICATION", in: leftBoxRect, context: cgContext)

            let labelFont = UIFont.systemFont(ofSize: 8, weight: .bold)
            let valFont = UIFont.systemFont(ofSize: 8, weight: .regular)
            let boldAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.black]
            let valAttrs: [NSAttributedString.Key: Any] = [.font: valFont, .foregroundColor: UIColor.darkGray]

            var pilotY = currentY + 22
            "Remote Pilot: ".draw(at: CGPoint(x: margin + 8, y: pilotY), withAttributes: boldAttrs)
            (signOff.pilotName.isEmpty ? "Self-Certified Operator" : signOff.pilotName).draw(at: CGPoint(x: margin + 76, y: pilotY), withAttributes: valAttrs)

            pilotY += 12
            "Certificate #: ".draw(at: CGPoint(x: margin + 8, y: pilotY), withAttributes: boldAttrs)
            (signOff.remotePilotCertificateNumber.isEmpty ? "PENDING ENTRY" : signOff.remotePilotCertificateNumber).draw(at: CGPoint(x: margin + 76, y: pilotY), withAttributes: valAttrs)

            pilotY += 12
            "Launch Site: ".draw(at: CGPoint(x: margin + 8, y: pilotY), withAttributes: boldAttrs)
            let locStr = String(format: "%.4f, %.4f (%@)", locationCoordinate.latitude, locationCoordinate.longitude, String(locationAddress.prefix(25)))
            locStr.draw(at: CGPoint(x: margin + 76, y: pilotY), withAttributes: valAttrs)

            pilotY += 12
            "Mission: ".draw(at: CGPoint(x: margin + 8, y: pilotY), withAttributes: boldAttrs)
            String(signOff.missionPurpose.prefix(32)).draw(at: CGPoint(x: margin + 76, y: pilotY), withAttributes: valAttrs)

            // Right Col: Aircraft Specs
            let rightBoxRect = CGRect(x: margin + colWidth + 12, y: currentY, width: colWidth, height: infoBoxHeight)
            drawBorderedBox(context: cgContext, rect: rightBoxRect)
            drawSectionHeader("AIRCRAFT SPECIFICATION & LIMITS", in: rightBoxRect, context: cgContext)

            var droneY = currentY + 22
            "Model / Setup: ".draw(at: CGPoint(x: rightBoxRect.origin.x + 8, y: droneY), withAttributes: boldAttrs)
            drone.name.draw(at: CGPoint(x: rightBoxRect.origin.x + 80, y: droneY), withAttributes: valAttrs)

            droneY += 12
            "Takeoff Weight: ".draw(at: CGPoint(x: rightBoxRect.origin.x + 8, y: droneY), withAttributes: boldAttrs)
            String(format: "%.0f grams (%@)", drone.weightGrams, drone.category).draw(at: CGPoint(x: rightBoxRect.origin.x + 80, y: droneY), withAttributes: valAttrs)

            droneY += 12
            "Max Wind Limit: ".draw(at: CGPoint(x: rightBoxRect.origin.x + 8, y: droneY), withAttributes: boldAttrs)
            String(format: "%.1f mph (%.1f knots)", drone.maxWindResistanceMph, AviationMath.mphToKnots(drone.maxWindResistanceMph)).draw(at: CGPoint(x: rightBoxRect.origin.x + 80, y: droneY), withAttributes: valAttrs)

            droneY += 12
            "Temp Range: ".draw(at: CGPoint(x: rightBoxRect.origin.x + 8, y: droneY), withAttributes: boldAttrs)
            String(format: "%.0f°C to %.0f°C", drone.minOperatingTempC, drone.maxOperatingTempC).draw(at: CGPoint(x: rightBoxRect.origin.x + 80, y: droneY), withAttributes: valAttrs)

            currentY += infoBoxHeight + 10

            // 4. Airspace & LAANC Compliance Box
            let airspaceHeight: CGFloat = 65
            let airspaceRect = CGRect(x: margin, y: currentY, width: contentWidth, height: airspaceHeight)
            drawBorderedBox(context: cgContext, rect: airspaceRect)
            drawSectionHeader("FAA AIRSPACE CLASSIFICATION & UASFM AUTHORIZATION (§ 107.41)", in: airspaceRect, context: cgContext)

            var airY = currentY + 22
            "Airspace Class: ".draw(at: CGPoint(x: margin + 8, y: airY), withAttributes: boldAttrs)
            airspace.airspaceClass.title.draw(at: CGPoint(x: margin + 95, y: airY), withAttributes: valAttrs)

            "UASFM Max Grid: ".draw(at: CGPoint(x: margin + 280, y: airY), withAttributes: boldAttrs)
            let ceilingStr = airspace.uasfmCeilingFeet != nil ? "\(airspace.uasfmCeilingFeet!) ft AGL" : "400 ft AGL (Class G Unrestricted)"
            ceilingStr.draw(at: CGPoint(x: margin + 370, y: airY), withAttributes: valAttrs)

            airY += 14
            "LAANC Requirement: ".draw(at: CGPoint(x: margin + 8, y: airY), withAttributes: boldAttrs)
            let laancStr = airspace.requiresLAANC ? "MANDATORY AUTHORIZATION PRIOR TO OPERATION" : "NONE (Class G Operations up to 400 ft AGL)"
            laancStr.draw(at: CGPoint(x: margin + 115, y: airY), withAttributes: valAttrs)

            airY += 14
            "ArcGIS Note: ".draw(at: CGPoint(x: margin + 8, y: airY), withAttributes: boldAttrs)
            String(airspace.regulatoryNote.prefix(80)).draw(at: CGPoint(x: margin + 95, y: airY), withAttributes: valAttrs)

            currentY += airspaceHeight + 10

            // 5. Environmental & Aviation Weather Section
            let weatherHeight: CGFloat = 90
            let weatherRect = CGRect(x: margin, y: currentY, width: contentWidth, height: weatherHeight)
            drawBorderedBox(context: cgContext, rect: weatherRect)
            drawSectionHeader("ATMOSPHERIC SOUNDING & METAR WEATHER (§ 107.51)", in: weatherRect, context: cgContext)

            var wY = currentY + 22
            "Raw Station METAR: ".draw(at: CGPoint(x: margin + 8, y: wY), withAttributes: boldAttrs)
            String(weather.rawMetar.prefix(85)).draw(at: CGPoint(x: margin + 110, y: wY), withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 7.5, weight: .regular),
                .foregroundColor: UIColor.black
            ])

            wY += 14
            "Surface Wind: ".draw(at: CGPoint(x: margin + 8, y: wY), withAttributes: boldAttrs)
            let gustStr = weather.surfaceWindGustMph != nil ? " G \(weather.surfaceWindGustMph!) mph" : ""
            "\(weather.surfaceWindSpeedMph) mph\(gustStr) @ \(weather.windDirectionDegrees ?? 0)°".draw(at: CGPoint(x: margin + 80, y: wY), withAttributes: valAttrs)

            "Estimated 400ft Wind: ".draw(at: CGPoint(x: margin + 280, y: wY), withAttributes: boldAttrs)
            let gust400Str = weather.windGust400ftMph != nil ? " G \(weather.windGust400ftMph!) mph" : ""
            "\(weather.wind400ftMph) mph\(gust400Str)".draw(at: CGPoint(x: margin + 395, y: wY), withAttributes: valAttrs)

            wY += 14
            "Flight Visibility: ".draw(at: CGPoint(x: margin + 8, y: wY), withAttributes: boldAttrs)
            "\(weather.visibilityStatuteMiles) Statute Miles (\(weather.flightCategory.rawValue))".draw(at: CGPoint(x: margin + 80, y: wY), withAttributes: valAttrs)

            "Cloud Ceiling: ".draw(at: CGPoint(x: margin + 280, y: wY), withAttributes: boldAttrs)
            (weather.cloudCeilingFeet != nil ? "\(weather.cloudCeilingFeet!) ft AGL" : "Unlimited / Clear").draw(at: CGPoint(x: margin + 395, y: wY), withAttributes: valAttrs)

            wY += 14
            "Density Altitude (DA): ".draw(at: CGPoint(x: margin + 8, y: wY), withAttributes: boldAttrs)
            let daLossStr = risk.thrustEfficiencyLossPercent != nil ? " (-\(risk.thrustEfficiencyLossPercent!)% thrust)" : " (Nominal)"
            "\(Int(risk.densityAltitudeFeet)) ft\(daLossStr)".draw(at: CGPoint(x: margin + 115, y: wY), withAttributes: valAttrs)

            "Altimeter / Temp: ".draw(at: CGPoint(x: margin + 280, y: wY), withAttributes: boldAttrs)
            String(format: "%.2f inHg / %.1f°C", weather.altimeterInHg, weather.temperatureCelsius).draw(at: CGPoint(x: margin + 395, y: wY), withAttributes: valAttrs)

            currentY += weatherHeight + 10

            // 6. Evaluated Risk Matrix Breakdown Table
            let factorsHeight: CGFloat = 110
            let factorsRect = CGRect(x: margin, y: currentY, width: contentWidth, height: factorsHeight)
            drawBorderedBox(context: cgContext, rect: factorsRect)
            drawSectionHeader("RISK ASSESSMENT MATRIX (RAM) FACTOR AUDIT", in: factorsRect, context: cgContext)

            var fY = currentY + 22
            for factor in risk.factors.prefix(5) {
                let badgeColor: UIColor
                let badgeText: String
                switch factor.severity {
                case .safe:
                    badgeColor = UIColor(red: 0.13, green: 0.58, blue: 0.28, alpha: 1.0)
                    badgeText = " PASS "
                case .caution:
                    badgeColor = UIColor(red: 0.85, green: 0.55, blue: 0.08, alpha: 1.0)
                    badgeText = " WARN "
                case .noGo:
                    badgeColor = UIColor(red: 0.80, green: 0.15, blue: 0.15, alpha: 1.0)
                    badgeText = " FAIL "
                }

                // Small status pill
                let pillRect = CGRect(x: margin + 8, y: fY, width: 34, height: 12)
                cgContext.setFillColor(badgeColor.cgColor)
                cgContext.fill(pillRect)

                badgeText.draw(at: CGPoint(x: margin + 10, y: fY + 1), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 7, weight: .heavy),
                    .foregroundColor: UIColor.white
                ])

                "[\(factor.regulatoryReference)] ".draw(at: CGPoint(x: margin + 46, y: fY + 1), withAttributes: boldAttrs)
                String(factor.summary.prefix(85)).draw(at: CGPoint(x: margin + 160, y: fY + 1), withAttributes: valAttrs)

                fY += 16
            }

            currentY += factorsHeight + 10

            // 7. Part 107.49 Pre-Flight Checklist Table
            let checkHeight: CGFloat = 80
            let checkRect = CGRect(x: margin, y: currentY, width: contentWidth, height: checkHeight)
            drawBorderedBox(context: cgContext, rect: checkRect)
            drawSectionHeader("FAA § 107.49 MANDATORY PRE-FLIGHT VERIFICATION", in: checkRect, context: cgContext)

            var cY = currentY + 20
            for item in signOff.checklistItems {
                let statusMark = item.isCompleted ? "[X] VERIFIED" : "[ ] INCOMPLETE"
                let markAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 8, weight: .bold),
                    .foregroundColor: item.isCompleted ? UIColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 1.0) : UIColor.red
                ]
                statusMark.draw(at: CGPoint(x: margin + 8, y: cY), withAttributes: markAttrs)
                item.title.draw(at: CGPoint(x: margin + 90, y: cY), withAttributes: boldAttrs)
                String(item.regulatorySubtitle.prefix(45)).draw(at: CGPoint(x: margin + 300, y: cY), withAttributes: valAttrs)
                cY += 14
            }

            currentY += checkHeight + 10

            // 8. Sign-Off & Signature Block
            let signHeight: CGFloat = 85
            let signRect = CGRect(x: margin, y: currentY, width: contentWidth, height: signHeight)
            drawBorderedBox(context: cgContext, rect: signRect)
            drawSectionHeader("PILOT CERTIFICATION & LEGAL SIGN-OFF", in: signRect, context: cgContext)

            let legalDisclaimer = "I hereby certify under penalty of 14 CFR § 107.5 and 18 U.S.C. § 1001 that this pre-flight inspection was conducted prior to flight, the airspace and weather conditions were verified, and the aircraft is in condition for safe operation."
            let legalAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 7, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            legalDisclaimer.draw(in: CGRect(x: margin + 8, y: currentY + 20, width: contentWidth - 140, height: 26), withAttributes: legalAttrs)

            let signDateText = "Signed: \(ISO8601DateFormatter().string(from: signOff.signedAt ?? Date()))"
            signDateText.draw(at: CGPoint(x: margin + 8, y: currentY + 52), withAttributes: valAttrs)

            let certText = "Pilot Certificate: \(signOff.remotePilotCertificateNumber.isEmpty ? "N/A" : signOff.remotePilotCertificateNumber)"
            certText.draw(at: CGPoint(x: margin + 8, y: currentY + 64), withAttributes: boldAttrs)

            // Signature Image Box on the right
            let sigBoxRect = CGRect(x: margin + contentWidth - 120, y: currentY + 18, width: 112, height: 60)
            cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            cgContext.setLineWidth(0.5)
            cgContext.stroke(sigBoxRect)

            if let sigData = signOff.signatureImageData, let sigImage = UIImage(data: sigData) {
                sigImage.draw(in: sigBoxRect.insetBy(dx: 4, dy: 4))
            } else {
                "ELECTRONICALLY\nSIGNED".draw(in: sigBoxRect.insetBy(dx: 10, dy: 18), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 8, weight: .bold),
                    .foregroundColor: UIColor.gray
                ])
            }
        }
    }

    // MARK: - Drawing Helpers

    private static func drawBorderedBox(context: CGContext, rect: CGRect) {
        context.setFillColor(UIColor(white: 0.98, alpha: 1.0).cgColor)
        context.fill(rect)
        context.setStrokeColor(UIColor(white: 0.75, alpha: 1.0).cgColor)
        context.setLineWidth(0.8)
        context.stroke(rect)
    }

    private static func drawSectionHeader(_ title: String, in rect: CGRect, context: CGContext) {
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.5, weight: .black),
            .foregroundColor: UIColor(red: 0.1, green: 0.2, blue: 0.35, alpha: 1.0)
        ]
        title.draw(at: CGPoint(x: rect.origin.x + 8, y: rect.origin.y + 4), withAttributes: headerAttrs)
    }
}
