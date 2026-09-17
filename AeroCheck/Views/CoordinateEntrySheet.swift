//
//  CoordinateEntrySheet.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import CoreLocation

/// Clean location selector modal adhering to Apple HIG:
/// - Single primary action: Reset to device GPS
/// - Direct coordinate manual entry with validation
/// - Minimum 44x44pt touch targets
public struct CoordinateEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    public let currentCoordinate: CLLocationCoordinate2D?
    public let onResetToGPS: () -> Void
    public let onSelectCoordinate: (Double, Double, String?) -> Void

    @State private var latText: String = ""
    @State private var lonText: String = ""
    @State private var inputError: String?

    public init(
        currentCoordinate: CLLocationCoordinate2D?,
        onResetToGPS: @escaping () -> Void,
        onSelectCoordinate: @escaping (Double, Double, String?) -> Void
    ) {
        self.currentCoordinate = currentCoordinate
        self.onResetToGPS = onResetToGPS
        self.onSelectCoordinate = onSelectCoordinate
        if let c = currentCoordinate {
            _latText = State(initialValue: String(format: "%.5f", c.latitude))
            _lonText = State(initialValue: String(format: "%.5f", c.longitude))
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.space16) {
                    // Quick Action: Device GPS
                    Button {
                        onResetToGPS()
                        dismiss()
                    } label: {
                        HStack(spacing: DesignTokens.space12) {
                            Image(systemName: "location.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DesignTokens.accent)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Use Current Device Location")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DesignTokens.textPrimary)
                                Text("Acquire live GPS fix from device hardware")
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.textSecondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(DesignTokens.textTertiary)
                        }
                        .padding(DesignTokens.space16)
                        .frame(minHeight: 56)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                .fill(DesignTokens.surfaceSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                        .stroke(DesignTokens.borderHairline, lineWidth: 1)
                                )
                        )
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.interactivePress)

                    // Manual Coordinates Section
                    VStack(alignment: .leading, spacing: DesignTokens.space12) {
                        Text("MISSION COORDINATES")
                            .font(.caption2.weight(.semibold).monospaced())
                            .foregroundStyle(DesignTokens.textTertiary)

                        HStack(spacing: DesignTokens.space8) {
                            VStack(alignment: .leading, spacing: DesignTokens.space4) {
                                Text("Latitude")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(DesignTokens.textSecondary)
                                TextField("e.g. 37.7749", text: $latText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.body)
                                    .textFieldStyle(.plain)
                                    .padding(DesignTokens.space12)
                                    .background(DesignTokens.surfaceTertiary)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                    .foregroundStyle(DesignTokens.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: DesignTokens.space4) {
                                Text("Longitude")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(DesignTokens.textSecondary)
                                TextField("e.g. -122.4194", text: $lonText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.body)
                                    .textFieldStyle(.plain)
                                    .padding(DesignTokens.space12)
                                    .background(DesignTokens.surfaceTertiary)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                    .foregroundStyle(DesignTokens.textPrimary)
                            }
                        }

                        if let err = inputError {
                            Text(err)
                                .font(.caption)
                                .foregroundStyle(DesignTokens.statusAlert)
                        }

                        Button {
                            applyManual()
                        } label: {
                            Text("Apply Coordinates")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(DesignTokens.accent)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                        }
                        .buttonStyle(.interactivePress)
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
                }
                .padding(DesignTokens.space16)
            }
            .background(DesignTokens.surfacePrimary.ignoresSafeArea())
            .navigationTitle("Launch Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
    }

    private func applyManual() {
        guard let lat = Double(latText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(lonText.trimmingCharacters(in: .whitespaces)),
              (-90.0...90.0).contains(lat),
              (-180.0...180.0).contains(lon) else {
            inputError = "Enter valid GPS coordinates (Lat -90..90, Lon -180..180)."
            return
        }
        inputError = nil
        onSelectCoordinate(lat, lon, nil)
        dismiss()
    }
}
