//
//  PreFlightChecklistView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// FAA Part 107.49 Pre-Flight Inspection & Pilot Verification modal adhering to Apple HIG:
/// - Semantic typography (Title3, Headline, Subheadline, Footnote, Monospaced Caption)
/// - Flat card surfaces with precise hairline borders (zero floating gradients or heavy shadows)
/// - Single dominant interactive accent with 44x44pt minimum touch targets
/// - Native tactile button press feedback
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
                VStack(alignment: .leading, spacing: DesignTokens.space16) {
                    // Header Description
                    VStack(alignment: .leading, spacing: DesignTokens.space4) {
                        Text("14 CFR § 107.49 COMPLIANCE")
                            .font(.caption2.weight(.bold).monospaced())
                            .foregroundStyle(DesignTokens.accent)

                        Text("Pre-Flight Inspection & Sign-Off")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DesignTokens.textPrimary)

                        Text("Verify all conditions prior to flight. Completed inspection record will be embedded in the official PDF audit log.")
                            .font(.footnote)
                            .foregroundStyle(DesignTokens.textSecondary)
                    }
                    .padding(.bottom, DesignTokens.space4)

                    // Checklist items
                    VStack(spacing: DesignTokens.space8) {
                        ForEach($record.checklistItems) { $item in
                            Button {
                                item.isCompleted.toggle()
                            } label: {
                                HStack(alignment: .top, spacing: DesignTokens.space12) {
                                    Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                        .font(.title3)
                                        .foregroundStyle(item.isCompleted ? DesignTokens.statusSafe : DesignTokens.textTertiary)
                                        .frame(width: 24, height: 24)

                                    VStack(alignment: .leading, spacing: DesignTokens.space4) {
                                        Text(item.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(DesignTokens.textPrimary)

                                        Text(item.regulatorySubtitle)
                                            .font(.footnote)
                                            .foregroundStyle(DesignTokens.textSecondary)
                                            .lineSpacing(2)
                                    }

                                    Spacer()
                                }
                                .padding(DesignTokens.space16)
                                .frame(minHeight: 54)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                        .fill(DesignTokens.surfaceSecondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                                .stroke(item.isCompleted ? DesignTokens.statusSafe.opacity(0.35) : DesignTokens.borderHairline, lineWidth: 1)
                                        )
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.interactivePress)
                        }
                    }

                    // Pilot Credentials Form
                    VStack(alignment: .leading, spacing: DesignTokens.space12) {
                        Text("REMOTE PILOT IN COMMAND (PIC)")
                            .font(.caption2.weight(.semibold).monospaced())
                            .foregroundStyle(DesignTokens.textTertiary)

                        VStack(alignment: .leading, spacing: DesignTokens.space4) {
                            Text("Full Legal Name")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(DesignTokens.textSecondary)
                            TextField("e.g. Johnathan Doe", text: $record.pilotName)
                                .font(.body)
                                .textFieldStyle(.plain)
                                .padding(DesignTokens.space12)
                                .background(DesignTokens.surfaceTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: DesignTokens.space4) {
                            Text("FAA Remote Pilot Certificate Number")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(DesignTokens.textSecondary)
                            TextField("e.g. 4819204", text: $record.remotePilotCertificateNumber)
                                .font(.body)
                                .textFieldStyle(.plain)
                                .padding(DesignTokens.space12)
                                .background(DesignTokens.surfaceTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: DesignTokens.space4) {
                            Text("Mission Purpose")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(DesignTokens.textSecondary)
                            TextField("e.g. Commercial Roof Survey", text: $record.missionPurpose)
                                .font(.body)
                                .textFieldStyle(.plain)
                                .padding(DesignTokens.space12)
                                .background(DesignTokens.surfaceTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                .foregroundStyle(DesignTokens.textPrimary)
                        }
                    }
                    .padding(DesignTokens.space16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                            .fill(DesignTokens.surfaceSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                    .stroke(DesignTokens.borderHairline, lineWidth: 1)
                            )
                    )

                    // Digital Signature Canvas
                    VStack(alignment: .leading, spacing: DesignTokens.space8) {
                        HStack {
                            Text("DIGITAL SIGNATURE TRACE")
                                .font(.caption2.weight(.semibold).monospaced())
                                .foregroundStyle(DesignTokens.textTertiary)

                            Spacer()

                            if !drawnPaths.isEmpty {
                                Button("Clear") {
                                    drawnPaths.removeAll()
                                    currentDrawingPath = Path()
                                    record.signatureImageData = nil
                                }
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(DesignTokens.statusAlert)
                                .frame(minWidth: 44, minHeight: 44)
                                .contentShape(Rectangle())
                            }
                        }

                        ZStack {
                            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                .fill(DesignTokens.surfaceTertiary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                        .stroke(DesignTokens.borderHairline, lineWidth: 1)
                                )

                            Canvas { context, _ in
                                for path in drawnPaths {
                                    context.stroke(path, with: .color(DesignTokens.textPrimary), lineWidth: 2)
                                }
                                context.stroke(currentDrawingPath, with: .color(DesignTokens.textPrimary), lineWidth: 2)
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
                                    .font(.footnote)
                                    .foregroundStyle(DesignTokens.textTertiary)
                            }
                        }
                        .frame(height: 110)
                    }
                    .padding(DesignTokens.space16)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                            .fill(DesignTokens.surfaceSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                    .stroke(DesignTokens.borderHairline, lineWidth: 1)
                            )
                    )

                    // Validation Warning
                    if let warning = validationWarning {
                        HStack(spacing: DesignTokens.space8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(DesignTokens.statusCaution)
                            Text(warning)
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(DesignTokens.statusCaution)
                        }
                        .padding(.horizontal, DesignTokens.space8)
                    }

                    // Primary Submit Button with 44pt+ height & press feedback
                    Button {
                        validateAndSubmit()
                    } label: {
                        HStack(spacing: DesignTokens.space8) {
                            Image(systemName: "doc.badge.arrow.up.fill")
                                .font(.subheadline)
                            Text("Sign & Generate Audit PDF")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 48)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                .fill(DesignTokens.accent)
                        )
                    }
                    .buttonStyle(.interactivePress)
                    .padding(.top, DesignTokens.space8)
                }
                .padding(DesignTokens.space16)
            }
            .background(DesignTokens.surfacePrimary.ignoresSafeArea())
            .navigationTitle("Pre-Flight Sign-Off")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private func snapshotSignature() {
        let size = CGSize(width: 250, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            UIColor.clear.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setStroke()
            for path in drawnPaths {
                let uiPath = UIBezierPath(cgPath: path.cgPath)
                uiPath.lineWidth = 2.0
                uiPath.stroke()
            }
        }
        record.signatureImageData = image.pngData()
    }

    private func validateAndSubmit() {
        guard record.isAllChecked else {
            validationWarning = "Complete all 4 mandatory § 107.49 inspection items."
            return
        }

        guard !record.pilotName.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationWarning = "Pilot name is required for FAA compliance."
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
