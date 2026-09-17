//
//  FlightMapView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import MapKit

/// Tactical airspace Map view conforming to human-designed Apple HIG:
/// - Semantic typography (Subheadline, Caption)
/// - Flat container with crisp 1pt hairline border (zero floating drop shadows)
/// - 44x44pt accessible interactive recenter target
/// - Native Apple MapKit standard styling
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
                    Text("TACTICAL AIRSPACE MAP")
                        .font(.caption.weight(.bold).monospaced())
                        .foregroundStyle(DesignTokens.textTertiary)
                } icon: {
                    Image(systemName: "map.fill")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.accent)
                }

                Spacer()

                if let ident = airspace?.airportIdent {
                    Text(ident)
                        .font(.caption2.weight(.bold).monospaced())
                        .foregroundStyle(DesignTokens.accent)
                        .padding(.horizontal, DesignTokens.space8)
                        .padding(.vertical, DesignTokens.space4)
                        .background(
                            Capsule().fill(DesignTokens.accentMuted)
                        )
                }
            }

            // Tactical Map Container
            ZStack(alignment: .bottomTrailing) {
                Map(position: $position) {
                    // Part 107 legal 400 ft (~122m) buffer radius
                    MapCircle(center: activeCoordinate, radius: 122)
                        .foregroundStyle(DesignTokens.accent.opacity(0.12))
                        .stroke(DesignTokens.accent, lineWidth: 1.5)

                    // Drone Pin Annotation
                    Annotation("Launch Site", coordinate: activeCoordinate) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.surfacePrimary)
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(DesignTokens.accent, lineWidth: 1.5)
                                )

                            Image(systemName: "airplane")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(DesignTokens.accent)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                        .stroke(DesignTokens.borderHairline, lineWidth: 1)
                )

                // Recenter Button with 44x44pt tap target & micro-interaction
                Button {
                    withAnimation(.snappy(duration: 0.3)) {
                        position = .camera(MapCamera(centerCoordinate: activeCoordinate, distance: 1200))
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                .fill(DesignTokens.surfaceSecondary)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                        .stroke(DesignTokens.borderHairline, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.interactivePress)
                .padding(DesignTokens.space8)
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
                        .stroke(DesignTokens.borderHairline, lineWidth: 1)
                )
        )
    }
}
