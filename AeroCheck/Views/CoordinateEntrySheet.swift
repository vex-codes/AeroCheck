//
//  CoordinateEntrySheet.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import CoreLocation

/// Coordinate manual entry modal for off-site mission planning and location override.
public struct CoordinateEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    public let currentCoordinate: CLLocationCoordinate2D?
    public let onSelectCoordinate: (Double, Double, String?) -> Void

    @State private var latText: String = ""
    @State private var lonText: String = ""
    @State private var presetName: String = ""

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
                VStack(alignment: .leading, spacing: DesignTokens.spaceM) {
                    Text("MANUAL MISSION COORDINATES")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)

                    VStack(spacing: DesignTokens.spaceS) {
                        HStack(spacing: DesignTokens.spaceS) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Latitude")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(DesignTokens.textSecondary)
                                TextField("e.g. 37.7749", text: $latText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textFieldStyle(.plain)
                                    .padding(DesignTokens.spaceS)
                                    .background(DesignTokens.cardBackgroundSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                    .foregroundStyle(DesignTokens.textPrimary)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Longitude")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(DesignTokens.textSecondary)
                                TextField("e.g. -122.4194", text: $lonText)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textFieldStyle(.plain)
                                    .padding(DesignTokens.spaceS)
                                    .background(DesignTokens.cardBackgroundSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                    .foregroundStyle(DesignTokens.textPrimary)
                            }
                        }

                        Button {
                            applyManual()
                        } label: {
                            Text("Set Mission Coordinates")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(DesignTokens.aeroBlue)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                        }
                        .buttonStyle(.plain)
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

                    // Aviation Presets
                    Text("TEST & PLANNING PRESETS")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)

                    VStack(spacing: DesignTokens.spaceS) {
                        ForEach(quickPresets, id: \.name) { preset in
                            Button {
                                onSelectCoordinate(preset.lat, preset.lon, preset.name)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(preset.name)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(DesignTokens.textPrimary)

                                        Text(String(format: "%.4f, %.4f", preset.lat, preset.lon))
                                            .font(.system(size: 11, weight: .regular, design: .monospaced))
                                            .foregroundStyle(DesignTokens.textMuted)
                                    }

                                    Spacer()

                                    Image(systemName: "arrow.right.circle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(DesignTokens.aeroBlue)
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
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(DesignTokens.spaceM)
            }
            .background(DesignTokens.canvasBackground.ignoresSafeArea())
            .navigationTitle("Set Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
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
