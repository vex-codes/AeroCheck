//
//  CoordinateEntrySheet.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import CoreLocation

/// Coordinate manual entry modal for off-site mission planning and location override adhering to Apple HIG:
/// - Semantic typography (Subheadline, Footnote, Monospaced Caption)
/// - Flat card surfaces with hairline borders
/// - 44x44pt minimum touch targets with active press feedback
public struct CoordinateEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    public let currentCoordinate: CLLocationCoordinate2D?
    public let onSelectCoordinate: (Double, Double, String?) -> Void

    @State private var latText: String = ""
    @State private var lonText: String = ""

    public init(
        currentCoordinate: CLLocationCoordinate2D?,
        onSelectCoordinate: @escaping (Double, Double, String?) -> Void
    ) {
        self.currentCoordinate = currentCoordinate
        self.onSelectCoordinate = onSelectCoordinate
        if let c = currentCoordinate {
            _latText = State(initialValue: String(format: "%.4f", c.latitude))
            _lonText = State(initialValue: String(format: "%.4f", c.longitude))
        }
    }

    private let quickPresets: [(name: String, lat: Double, lon: Double)] = [
        ("San Francisco (Class B Surface)", 37.6213, -122.3790),
        ("San Jose Intl (Class C)", 37.3639, -121.9289),
        ("Palo Alto Airport (Class D)", 37.4611, -122.1150),
        ("Half Moon Bay (Class G Open)", 37.5134, -122.5011),
        ("Austin-Bergstrom (Class C)", 30.1975, -97.6664),
        ("Denver Intl (High Density Alt)", 39.8561, -104.6737)
    ]

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.space16) {
                    Text("MANUAL MISSION COORDINATES")
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)

                    VStack(spacing: DesignTokens.space12) {
                        HStack(spacing: DesignTokens.space8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Latitude")
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.textSecondary)
                                TextField("37.7749", text: $latText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.body)
                                    .textFieldStyle(.plain)
                                    .padding(DesignTokens.space12)
                                    .background(DesignTokens.surfaceTertiary)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                    .foregroundStyle(DesignTokens.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Longitude")
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.textSecondary)
                                TextField("-122.4194", text: $lonText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .font(.body)
                                    .textFieldStyle(.plain)
                                    .padding(DesignTokens.space12)
                                    .background(DesignTokens.surfaceTertiary)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                    .foregroundStyle(DesignTokens.textPrimary)
                            }
                        }

                        Button {
                            applyManual()
                        } label: {
                            Text("Set Mission Coordinates")
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

                    // Aviation Test Presets
                    Text("PLANNING & AIRSPACE PRESETS")
                        .font(.caption2.weight(.semibold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)

                    VStack(spacing: DesignTokens.space8) {
                        ForEach(quickPresets, id: \.name) { preset in
                            Button {
                                onSelectCoordinate(preset.lat, preset.lon, preset.name)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.name)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(DesignTokens.textPrimary)

                                        Text(String(format: "%.4f, %.4f", preset.lat, preset.lon))
                                            .font(.caption.monospaced())
                                            .foregroundStyle(DesignTokens.textTertiary)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right")
                                        .font(.footnote.weight(.semibold))
                                        .foregroundStyle(DesignTokens.accent)
                                }
                                .padding(DesignTokens.space16)
                                .frame(minHeight: 48)
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
                        }
                    }
                }
                .padding(DesignTokens.space16)
            }
            .background(DesignTokens.surfacePrimary.ignoresSafeArea())
            .navigationTitle("Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.textSecondary)
                }
            }
        }
    }

    private func applyManual() {
        guard let lat = Double(latText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(lonText.trimmingCharacters(in: .whitespaces)) else {
            return
        }
        onSelectCoordinate(lat, lon, nil)
        dismiss()
    }
}
