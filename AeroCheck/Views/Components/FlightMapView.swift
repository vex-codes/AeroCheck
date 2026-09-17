//
//  FlightMapView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import MapKit

/// Tactical airspace Map view adhering to ForeFlight/DJI Fly aesthetic:
/// - Seamless embedded map matching the 16pt card curvature.
/// - Floating location button with native ultraThinMaterial vibrancy and circular stroke.
/// - Crisp tactical Part 107 operational radius overlay.
public struct FlightMapView: View {
    public let coordinate: CLLocationCoordinate2D?
    public let airspace: AirspaceEvaluation?

    @State private var position: MapCameraPosition = .automatic

    public init(coordinate: CLLocationCoordinate2D?, airspace: AirspaceEvaluation?) {
        self.coordinate = coordinate
        self.airspace = airspace
    }

    private var activeCoordinate: CLLocationCoordinate2D {
        coordinate ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space12) {
            // Header Row
            HStack {
                Label {
                    Text("TACTICAL MAP & BUFFER RADIUS")
                        .font(.caption2.weight(.bold).monospaced())
                        .tracking(0.6)
                        .foregroundStyle(DesignTokens.textTertiary)
                } icon: {
                    Image(systemName: "map.fill")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                Text("400 FT AGL RADIUS")
                    .font(.caption2.weight(.bold).monospaced())
                    .foregroundStyle(DesignTokens.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(DesignTokens.accentMuted)
                    )
            }

            // Embedded Tactical Map
            ZStack(alignment: .bottomTrailing) {
                Map(position: $position) {
                    // Part 107 legal 400 ft (~122m) buffer radius
                    MapCircle(center: activeCoordinate, radius: 122)
                        .foregroundStyle(DesignTokens.accent.opacity(0.14))
                        .stroke(DesignTokens.accent, lineWidth: 1.5)

                    // Drone Pin Annotation
                    Annotation("Launch Site", coordinate: activeCoordinate) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.surfacePrimary)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(DesignTokens.accent, lineWidth: 2)
                                )

                            Image(systemName: "airplane")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(DesignTokens.accent)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                        .stroke(DesignTokens.borderHairline.opacity(0.8), lineWidth: 0.5)
                )

                // Floating Recenter Button with ultraThinMaterial blur vibrancy
                Button {
                    withAnimation(.snappy(duration: 0.3)) {
                        position = .camera(MapCamera(centerCoordinate: activeCoordinate, distance: 1200))
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                                )
                        )
                }
                .buttonStyle(.interactivePress)
                .padding(DesignTokens.space12)
            }
            .onChange(of: coordinate?.latitude) { _, _ in
                withAnimation(.snappy(duration: 0.3)) {
                    position = .camera(MapCamera(centerCoordinate: activeCoordinate, distance: 1200))
                }
            }
        }
        .padding(DesignTokens.space16)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                .fill(DesignTokens.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                        .stroke(DesignTokens.borderHairline.opacity(0.8), lineWidth: 0.5)
                )
        )
    }
}
