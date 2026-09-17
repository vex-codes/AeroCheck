//
//  PreFlightChecklistView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// FAA Part 107.49 Pre-Flight Inspection & Legal Sign-off modal.
public struct PreFlightChecklistView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding public var record: PreFlightSignOffRecord
    public let onCompleteAndGeneratePDF: () -> Void

    @State private var currentDrawingPath = Path()
    @State private var drawnPaths: [Path] = []
    @State private var validationWarning: String?

    public init(
        record: Binding<PreFlightSignOffRecord>,
        onCompleteAndGeneratePDF: @escaping () -> Void
    ) {
        self._record = record
        self.onCompleteAndGeneratePDF = onCompleteAndGeneratePDF
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.spaceM) {
                    // Header Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text("14 CFR § 107.49 COMPLIANCE CHECKLIST")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(DesignTokens.aeroBlue)

                        Text("Pre-Flight Inspection & Pilot Verification")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(DesignTokens.textPrimary)

                        Text("Before flight, the remote pilot in command must verify that each required condition is satisfied and sign off on safe airframe airworthiness.")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                    .padding(.bottom, DesignTokens.spaceXS)

                    // Checklist items
                    VStack(spacing: DesignTokens.spaceS) {
                        ForEach($record.checklistItems) { $item in
                            Button {
                                item.isCompleted.toggle()
                            } label: {
                                HStack(alignment: .top, spacing: DesignTokens.spaceM) {
                                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundStyle(item.isCompleted ? DesignTokens.verdictSafe : DesignTokens.textMuted)
                                        .frame(width: 32, height: 32)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.title)
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundStyle(DesignTokens.textPrimary)

                                        Text(item.regulatorySubtitle)
                                            .font(.system(size: 12, weight: .regular))
                                            .foregroundStyle(DesignTokens.textSecondary)
                                    }

                                    Spacer()
                                }
                                .padding(DesignTokens.spaceM)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                        .fill(DesignTokens.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                                .stroke(item.isCompleted ? DesignTokens.verdictSafe.opacity(0.4) : DesignTokens.cardBorder, lineWidth: 1)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Pilot Credentials Form
                    VStack(alignment: .leading, spacing: DesignTokens.spaceM) {
                        Text("REMOTE PILOT IN COMMAND (PIC) CREDENTIALS")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(DesignTokens.textMuted)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Full Legal Name")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DesignTokens.textSecondary)
                            TextField("e.g. Johnathan Doe", text: $record.pilotName)
                                .textFieldStyle(.plain)
                                .padding(DesignTokens.spaceS)
                                .background(DesignTokens.cardBackgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("FAA Remote Pilot Certificate #")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DesignTokens.textSecondary)
                            TextField("e.g. 4819204", text: $record.remotePilotCertificateNumber)
                                .textFieldStyle(.plain)
                                .padding(DesignTokens.spaceS)
                                .background(DesignTokens.cardBackgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mission Purpose / Operation Description")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(DesignTokens.textSecondary)
                            TextField("e.g. Commercial Roof Survey & Video", text: $record.missionPurpose)
                                .textFieldStyle(.plain)
                                .padding(DesignTokens.spaceS)
                                .background(DesignTokens.cardBackgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }
                    }
                    .padding(DesignTokens.spaceM)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                            .fill(DesignTokens.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                    .stroke(DesignTokens.cardBorder, lineWidth: 1)
                            )
                    )

                    // Digital Signature Canvas
                    VStack(alignment: .leading, spacing: DesignTokens.spaceS) {
                        HStack {
                            Text("DIGITAL SIGNATURE TRACE")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(DesignTokens.textMuted)

                            Spacer()

                            if !drawnPaths.isEmpty {
                                Button("Clear Signature") {
                                    drawnPaths.removeAll()
                                    currentDrawingPath = Path()
                                    record.signatureImageData = nil
                                }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(DesignTokens.verdictNoGo)
                            }
                        }

                        ZStack {
                            RoundedRectangle(cornerRadius: DesignTokens.radiusS)
                                .fill(DesignTokens.cardBackgroundSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusS)
                                        .stroke(DesignTokens.cardBorder, lineWidth: 1)
                                )

                            // Signature Canvas View
                            Canvas { context, _ in
                                for path in drawnPaths {
                                    context.stroke(path, with: .color(DesignTokens.textPrimary), lineWidth: 2.5)
                                }
                                context.stroke(currentDrawingPath, with: .color(DesignTokens.textPrimary), lineWidth: 2.5)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0.1)
                                    .onChanged { value in
                                        let pt = value.location
                                        if currentDrawingPath.isEmpty {
                                            currentDrawingPath.move(to: pt)
                                        } else {
                                            currentDrawingPath.addLine(to: pt)
                                        }
                                    }
                                    .onEnded { _ in
                                        drawnPaths.append(currentDrawingPath)
                                        currentDrawingPath = Path()
                                        snapshotSignature()
                                    }
                            )

                            if drawnPaths.isEmpty && currentDrawingPath.isEmpty {
                                Text("Sign with finger or stylus here")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(DesignTokens.textMuted)
                            }
                        }
                        .frame(height: 120)
                    }
                    .padding(DesignTokens.spaceM)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                            .fill(DesignTokens.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                    .stroke(DesignTokens.cardBorder, lineWidth: 1)
                            )
                    )

                    if let warning = validationWarning {
                        HStack(spacing: DesignTokens.spaceS) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(DesignTokens.verdictCaution)
                            Text(warning)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(DesignTokens.verdictCaution)
                        }
                        .padding(.horizontal, DesignTokens.spaceS)
                    }

                    // Complete & Export PDF Action
                    Button {
                        validateAndSubmit()
                    } label: {
                        HStack(spacing: DesignTokens.spaceS) {
                            Image(systemName: "doc.badge.arrow.up.fill")
                                .font(.system(size: 16))
                            Text("Sign & Generate Audit PDF")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                .fill(DesignTokens.aeroBlue)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, DesignTokens.spaceS)
                }
                .padding(DesignTokens.spaceM)
            }
            .background(DesignTokens.canvasBackground.ignoresSafeArea())
            .navigationTitle("Pre-Flight Sign-Off")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func snapshotSignature() {
        // Render drawn signature to UIImage Data
        let size = CGSize(width: 250, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setStroke()
            for path in drawnPaths {
                let uiPath = UIBezierPath(cgPath: path.cgPath)
                uiPath.lineWidth = 2.5
                uiPath.stroke()
            }
        }
        record.signatureImageData = image.pngData()
    }

    private func validateAndSubmit() {
        guard record.isAllChecked else {
            validationWarning = "Please verify and complete all 4 mandatory § 107.49 inspection items."
            return
        }

        guard !record.pilotName.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationWarning = "Pilot name is required for legal FAA compliance."
            return
        }

        guard !record.remotePilotCertificateNumber.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationWarning = "Remote Pilot Certificate Number is required."
            return
        }

        record.signedAt = Date()
        validationWarning = nil
        dismiss()
        onCompleteAndGeneratePDF()
    }
}
