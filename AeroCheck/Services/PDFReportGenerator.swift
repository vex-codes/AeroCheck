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
/// Uses strict bounded-box typography rendering to prevent text overlap and clipping.
public enum PDFReportGenerator {

    /// Generates a single-page US Letter PDF data document.
    public static func generateComplianceReport(
        airspace: AirspaceEvaluation,
        weather: AviationWeatherReport,
        drone: DroneProfile,
        risk: RiskAssessmentResult,
        signOff: PreFlightSignOffRecord,
        locationCoordinate: CLLocationCoordinate2D,
        locationAddress: String,
        plannedAltitudeFeet: Int = 400
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
            let headerRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 46)
            cgContext.setFillColor(UIColor(red: 0.08, green: 0.12, blue: 0.18, alpha: 1.0).cgColor)
            cgContext.fill(headerRect)

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let subtitleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8.5, weight: .regular),
                .foregroundColor: UIColor(red: 0.75, green: 0.85, blue: 0.95, alpha: 1.0)
            ]

            let titleStr = "FAA 14 CFR PART 107 PRE-FLIGHT RISK ASSESSMENT MATRIX (RAM)"
            titleStr.draw(at: CGPoint(x: margin + 12, y: currentY + 8), withAttributes: titleAttrs)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss zzz"
            let dateFormatted = dateFormatter.string(from: risk.generatedAt)
            let subTitleStr = "AUDIT RECORD #AC-\(abs(dateFormatted.hashValue % 900000) + 100000)  •  TIMESTAMP: \(dateFormatted)"
            subTitleStr.draw(at: CGPoint(x: margin + 12, y: currentY + 26), withAttributes: subtitleAttrs)

            currentY += 52

            // 2. Verdict Banner Box
            let verdictColor: UIColor
            let verdictText: String
            switch risk.overallVerdict {
            case .safe:
                verdictColor = UIColor(red: 0.13, green: 0.58, blue: 0.28, alpha: 1.0) // Green
                verdictText = "VERDICT: APPROVED FOR FLIGHT (GO)"
            case .caution:
                verdictColor = UIColor(red: 0.85, green: 0.55, blue: 0.08, alpha: 1.0) // Amber
                verdictText = "VERDICT: CAUTION / RESTRICTIONS ACTIVE (CONDITIONAL GO)"
            case .noGo:
                verdictColor = UIColor(red: 0.80, green: 0.15, blue: 0.15, alpha: 1.0) // Red
                verdictText = "VERDICT: FLIGHT PROHIBITED (NO-GO)"
            }

            let verdictRect = CGRect(x: margin, y: currentY, width: contentWidth, height: 30)
            cgContext.setFillColor(verdictColor.cgColor)
            cgContext.fill(verdictRect)

            let verdictAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11.5, weight: .black),
                .foregroundColor: UIColor.white
            ]
            verdictText.draw(at: CGPoint(x: margin + 12, y: currentY + 8), withAttributes: verdictAttrs)

            currentY += 36

            // 3. Grid: Pilot / Mission & Aircraft Information
            let colGap: CGFloat = 10
            let colWidth = (contentWidth - colGap) / 2
            let infoBoxHeight: CGFloat = 82

            let labelFont = UIFont.systemFont(ofSize: 7.5, weight: .bold)
            let valFont = UIFont.systemFont(ofSize: 7.5, weight: .regular)
            let boldAttrs: [NSAttributedString.Key: Any] = [.font: labelFont, .foregroundColor: UIColor.black]
            let valAttrs: [NSAttributedString.Key: Any] = [.font: valFont, .foregroundColor: UIColor.darkGray]

            // Left Col: Pilot & Mission
            let leftBoxRect = CGRect(x: margin, y: currentY, width: colWidth, height: infoBoxHeight)
            drawBorderedBox(context: cgContext, rect: leftBoxRect)
            drawSectionHeader("PILOT & MISSION IDENTIFICATION", in: leftBoxRect, context: cgContext)

            var pilotY = currentY + 18
            drawKeyValue(label: "Remote Pilot:", value: signOff.pilotName.isEmpty ? "Self-Certified Operator" : signOff.pilotName, labelWidth: 70, in: leftBoxRect, y: pilotY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            pilotY += 12
            drawKeyValue(label: "Certificate #:", value: signOff.remotePilotCertificateNumber.isEmpty ? "PENDING ENTRY" : signOff.remotePilotCertificateNumber, labelWidth: 70, in: leftBoxRect, y: pilotY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            pilotY += 12
            let locShort = String(locationAddress.prefix(22))
            drawKeyValue(label: "Launch Site:", value: String(format: "%.4f, %.4f (%@)", locationCoordinate.latitude, locationCoordinate.longitude, locShort), labelWidth: 70, in: leftBoxRect, y: pilotY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            pilotY += 12
            drawKeyValue(label: "Mission Goal:", value: String(signOff.missionPurpose.prefix(28)), labelWidth: 70, in: leftBoxRect, y: pilotY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            pilotY += 12
            drawKeyValue(label: "Planned Alt:", value: "\(plannedAltitudeFeet) ft AGL (Operating Ceiling)", labelWidth: 70, in: leftBoxRect, y: pilotY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            // Right Col: Aircraft Specs
            let rightBoxRect = CGRect(x: margin + colWidth + colGap, y: currentY, width: colWidth, height: infoBoxHeight)
            drawBorderedBox(context: cgContext, rect: rightBoxRect)
            drawSectionHeader("AIRCRAFT SPECIFICATION & LIMITS", in: rightBoxRect, context: cgContext)

            var droneY = currentY + 18
            drawKeyValue(label: "Model / Setup:", value: drone.name, labelWidth: 75, in: rightBoxRect, y: droneY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            droneY += 12
            drawKeyValue(label: "Takeoff Weight:", value: String(format: "%.0fg (%@)", drone.weightGrams, drone.category), labelWidth: 75, in: rightBoxRect, y: droneY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            droneY += 12
            drawKeyValue(label: "Max Wind Limit:", value: String(format: "%.1f mph (%.1f kts)", drone.maxWindResistanceMph, AviationMath.mphToKnots(drone.maxWindResistanceMph)), labelWidth: 75, in: rightBoxRect, y: droneY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            droneY += 12
            drawKeyValue(label: "Temp Range:", value: String(format: "%.0f°C to %.0f°C", drone.minOperatingTempC, drone.maxOperatingTempC), labelWidth: 75, in: rightBoxRect, y: droneY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            droneY += 12
            drawKeyValue(label: "Classification:", value: drone.weightGrams < 250 ? "FAA Sub-250g Category 1" : "FAA Standard Remote ID", labelWidth: 75, in: rightBoxRect, y: droneY, boldAttrs: boldAttrs, valAttrs: valAttrs)

            currentY += infoBoxHeight + 8

            // 4. Airspace & LAANC Compliance Box
            let airspaceHeight: CGFloat = 62
            let airspaceRect = CGRect(x: margin, y: currentY, width: contentWidth, height: airspaceHeight)
            drawBorderedBox(context: cgContext, rect: airspaceRect)
            drawSectionHeader("FAA AIRSPACE CLASSIFICATION & UASFM AUTHORIZATION (§ 107.41)", in: airspaceRect, context: cgContext)

            var airY = currentY + 18
            let halfWidth = (contentWidth - 16) / 2

            // Row 1: Airspace Class (Left) + UASFM Ceiling (Right)
            let airClassRect = CGRect(x: margin + 8, y: airY, width: halfWidth, height: 12)
            drawInlineField(label: "Airspace Class: ", value: airspace.airspaceClass.title, in: airClassRect, boldAttrs: boldAttrs, valAttrs: valAttrs)

            let ceilingRect = CGRect(x: margin + 8 + halfWidth, y: airY, width: halfWidth, height: 12)
            let ceilingStr = airspace.uasfmCeilingFeet != nil ? "\(airspace.uasfmCeilingFeet!) ft AGL" : "400 ft AGL (Class G Surface)"
            drawInlineField(label: "UASFM Ceiling: ", value: ceilingStr, in: ceilingRect, boldAttrs: boldAttrs, valAttrs: valAttrs)

            airY += 13
            // Row 2: LAANC Requirement
            let laancRect = CGRect(x: margin + 8, y: airY, width: contentWidth - 16, height: 12)
            let laancStr = airspace.requiresLAANC ? "MANDATORY AUTHORIZATION PRIOR TO OPERATION" : "NONE (Class G Uncontrolled Airspace up to 400 ft AGL)"
            drawInlineField(label: "LAANC Requirement: ", value: laancStr, in: laancRect, boldAttrs: boldAttrs, valAttrs: valAttrs)

            airY += 13
            // Row 3: ArcGIS / Regulatory Note
            let noteRect = CGRect(x: margin + 8, y: airY, width: contentWidth - 16, height: 14)
            drawInlineField(label: "Regulatory Note: ", value: String(airspace.regulatoryNote.prefix(90)), in: noteRect, boldAttrs: boldAttrs, valAttrs: valAttrs)

            currentY += airspaceHeight + 8

            // 5. Environmental & Aviation Weather Section
            let weatherHeight: CGFloat = 86
            let weatherRect = CGRect(x: margin, y: currentY, width: contentWidth, height: weatherHeight)
            drawBorderedBox(context: cgContext, rect: weatherRect)
            drawSectionHeader("ATMOSPHERIC SOUNDING & METAR WEATHER (§ 107.51)", in: weatherRect, context: cgContext)

            var wY = currentY + 18

            // Row 1: Raw METAR String (Bounded)
            "Station METAR: ".draw(at: CGPoint(x: margin + 8, y: wY), withAttributes: boldAttrs)
            let metarRect = CGRect(x: margin + 82, y: wY, width: contentWidth - 90, height: 11)
            String(weather.rawMetar.prefix(88)).draw(in: metarRect, withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 7.0, weight: .regular),
                .foregroundColor: UIColor.black
            ])

            wY += 13
            // Row 2: Surface Wind (Left) + Estimated Wind Aloft (Right)
            let gustStr = weather.surfaceWindGustMph != nil ? " G \(Int(weather.surfaceWindGustMph!)) mph" : ""
            let sWindStr = "\(Int(weather.surfaceWindSpeedMph)) mph\(gustStr) @ \(weather.windDirectionDegrees ?? 0)°"
            drawInlineField(label: "Surface Wind: ", value: sWindStr, in: CGRect(x: margin + 8, y: wY, width: halfWidth, height: 12), boldAttrs: boldAttrs, valAttrs: valAttrs)

            let plannedWind = plannedAltitudeFeet <= 150 ? weather.wind100ftMph : (plannedAltitudeFeet <= 250 ? weather.wind200ftMph : weather.wind400ftMph)
            drawInlineField(label: "\(plannedAltitudeFeet)ft Wind Aloft: ", value: String(format: "%.1f mph (Shear: %+.1f)", plannedWind, plannedWind - weather.surfaceWindSpeedMph), in: CGRect(x: margin + 8 + halfWidth, y: wY, width: halfWidth, height: 12), boldAttrs: boldAttrs, valAttrs: valAttrs)

            wY += 13
            // Row 3: Visibility (Left) + Cloud Ceiling (Right)
            drawInlineField(label: "Flight Visibility: ", value: "\(weather.visibilityStatuteMiles) SM (\(weather.flightCategory.rawValue))", in: CGRect(x: margin + 8, y: wY, width: halfWidth, height: 12), boldAttrs: boldAttrs, valAttrs: valAttrs)

            let cloudStr = weather.cloudCeilingFeet != nil ? "\(weather.cloudCeilingFeet!) ft AGL" : "Unlimited / Clear"
            drawInlineField(label: "Cloud Ceiling: ", value: cloudStr, in: CGRect(x: margin + 8 + halfWidth, y: wY, width: halfWidth, height: 12), boldAttrs: boldAttrs, valAttrs: valAttrs)

            wY += 13
            // Row 4: Density Altitude (Left) + Altimeter / Temp (Right)
            let daLossStr = risk.thrustEfficiencyLossPercent != nil ? " (-\(risk.thrustEfficiencyLossPercent!)% thrust)" : " (Nominal)"
            drawInlineField(label: "Density Altitude: ", value: "\(Int(risk.densityAltitudeFeet)) ft\(daLossStr)", in: CGRect(x: margin + 8, y: wY, width: halfWidth, height: 12), boldAttrs: boldAttrs, valAttrs: valAttrs)

            let altTempStr = String(format: "%.2f inHg / %.1f°C", weather.altimeterInHg, weather.temperatureCelsius)
            drawInlineField(label: "Altimeter / Temp: ", value: altTempStr, in: CGRect(x: margin + 8 + halfWidth, y: wY, width: halfWidth, height: 12), boldAttrs: boldAttrs, valAttrs: valAttrs)

            currentY += weatherHeight + 8

            // 6. Evaluated Risk Matrix Breakdown Table
            let factorsHeight: CGFloat = 112
            let factorsRect = CGRect(x: margin, y: currentY, width: contentWidth, height: factorsHeight)
            drawBorderedBox(context: cgContext, rect: factorsRect)
            drawSectionHeader("RISK ASSESSMENT MATRIX (RAM) FACTOR AUDIT", in: factorsRect, context: cgContext)

            var fY = currentY + 18
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

                // Column 1: Status badge
                let pillRect = CGRect(x: margin + 8, y: fY, width: 32, height: 11)
                cgContext.setFillColor(badgeColor.cgColor)
                cgContext.fill(pillRect)

                badgeText.draw(at: CGPoint(x: margin + 9, y: fY + 1), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 6.5, weight: .heavy),
                    .foregroundColor: UIColor.white
                ])

                // Column 2: Reference tag (Bounded, never overflows into summary)
                let refRect = CGRect(x: margin + 44, y: fY, width: 105, height: 12)
                "[\(factor.regulatoryReference)]".draw(in: refRect, withAttributes: [
                    .font: UIFont.systemFont(ofSize: 7.0, weight: .bold),
                    .foregroundColor: UIColor.black
                ])

                // Column 3: Plain-English summary (Strictly bounded)
                let summaryRect = CGRect(x: margin + 152, y: fY, width: contentWidth - 160, height: 14)
                factor.summary.draw(in: summaryRect, withAttributes: valAttrs)

                fY += 18
            }

            currentY += factorsHeight + 8

            // 7. Part 107.49 Pre-Flight Checklist Table
            let checkHeight: CGFloat = 78
            let checkRect = CGRect(x: margin, y: currentY, width: contentWidth, height: checkHeight)
            drawBorderedBox(context: cgContext, rect: checkRect)
            drawSectionHeader("FAA § 107.49 MANDATORY PRE-FLIGHT VERIFICATION", in: checkRect, context: cgContext)

            var cY = currentY + 18
            for item in signOff.checklistItems {
                let statusMark = item.isCompleted ? "[X] VERIFIED" : "[ ] INCOMPLETE"
                let markAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedSystemFont(ofSize: 7.5, weight: .bold),
                    .foregroundColor: item.isCompleted ? UIColor(red: 0.1, green: 0.5, blue: 0.2, alpha: 1.0) : UIColor.red
                ]

                // Col 1: Checkbox status
                statusMark.draw(at: CGPoint(x: margin + 8, y: cY), withAttributes: markAttrs)

                // Col 2: Item title (Bounded)
                let itemTitleRect = CGRect(x: margin + 85, y: cY, width: 220, height: 12)
                item.title.draw(in: itemTitleRect, withAttributes: boldAttrs)

                // Col 3: Regulatory reference (Bounded)
                let subRect = CGRect(x: margin + 310, y: cY, width: contentWidth - 318, height: 12)
                item.regulatorySubtitle.draw(in: subRect, withAttributes: valAttrs)

                cY += 14
            }

            currentY += checkHeight + 8

            // 8. Sign-Off & Signature Block
            let signHeight: CGFloat = 74
            let signRect = CGRect(x: margin, y: currentY, width: contentWidth, height: signHeight)
            drawBorderedBox(context: cgContext, rect: signRect)
            drawSectionHeader("PILOT CERTIFICATION & LEGAL SIGN-OFF", in: signRect, context: cgContext)

            let legalDisclaimer = "I hereby certify under penalty of 14 CFR § 107.5 and 18 U.S.C. § 1001 that this pre-flight inspection was conducted prior to flight, the airspace and weather conditions were verified, and the aircraft is in condition for safe operation."
            let legalAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 6.8, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            legalDisclaimer.draw(in: CGRect(x: margin + 8, y: currentY + 18, width: contentWidth - 135, height: 24), withAttributes: legalAttrs)

            let signDateText = "Signed: \(dateFormatter.string(from: signOff.signedAt ?? Date()))"
            signDateText.draw(at: CGPoint(x: margin + 8, y: currentY + 44), withAttributes: valAttrs)

            let certText = "Pilot Certificate: \(signOff.remotePilotCertificateNumber.isEmpty ? "N/A" : signOff.remotePilotCertificateNumber)"
            certText.draw(at: CGPoint(x: margin + 8, y: currentY + 56), withAttributes: boldAttrs)

            // Signature Image Box on the right
            let sigBoxRect = CGRect(x: margin + contentWidth - 118, y: currentY + 16, width: 110, height: 50)
            cgContext.setStrokeColor(UIColor.lightGray.cgColor)
            cgContext.setLineWidth(0.5)
            cgContext.stroke(sigBoxRect)

            if let sigData = signOff.signatureImageData, let sigImage = UIImage(data: sigData) {
                sigImage.draw(in: sigBoxRect.insetBy(dx: 4, dy: 4))
            } else {
                "ELECTRONICALLY\nSIGNED".draw(in: sigBoxRect.insetBy(dx: 8, dy: 14), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 7.5, weight: .bold),
                    .foregroundColor: UIColor.gray
                ])
            }
        }
    }

    // MARK: - Drawing Helpers

    private static func drawBorderedBox(context: CGContext, rect: CGRect) {
        context.setFillColor(UIColor(white: 0.98, alpha: 1.0).cgColor)
        context.fill(rect)
        context.setStrokeColor(UIColor(white: 0.78, alpha: 1.0).cgColor)
        context.setLineWidth(0.6)
        context.stroke(rect)
    }

    private static func drawSectionHeader(_ title: String, in rect: CGRect, context: CGContext) {
        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 7.0, weight: .black),
            .foregroundColor: UIColor(red: 0.1, green: 0.2, blue: 0.35, alpha: 1.0)
        ]
        title.draw(at: CGPoint(x: rect.origin.x + 8, y: rect.origin.y + 4), withAttributes: headerAttrs)
    }

    private static func drawKeyValue(
        label: String,
        value: String,
        labelWidth: CGFloat,
        in box: CGRect,
        y: CGFloat,
        boldAttrs: [NSAttributedString.Key: Any],
        valAttrs: [NSAttributedString.Key: Any]
    ) {
        label.draw(at: CGPoint(x: box.origin.x + 8, y: y), withAttributes: boldAttrs)
        let valRect = CGRect(x: box.origin.x + 8 + labelWidth, y: y, width: box.width - labelWidth - 14, height: 12)
        value.draw(in: valRect, withAttributes: valAttrs)
    }

    private static func drawInlineField(
        label: String,
        value: String,
        in rect: CGRect,
        boldAttrs: [NSAttributedString.Key: Any],
        valAttrs: [NSAttributedString.Key: Any]
    ) {
        let labelSize = (label as NSString).size(withAttributes: boldAttrs)
        label.draw(at: rect.origin, withAttributes: boldAttrs)
        let valRect = CGRect(x: rect.origin.x + labelSize.width, y: rect.origin.y, width: max(10, rect.width - labelSize.width), height: rect.height)
        value.draw(in: valRect, withAttributes: valAttrs)
    }
}
