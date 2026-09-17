//
//  FlightMapView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import MapKit

/// Interactive tactical Map card showing drone position, 400ft radius buffer, and airspace boundary markers.
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
        VStack(alignment: .leading, spacing: DesignTokens.spaceS) {
            HStack {
                Label {
                    Text("TACTICAL AIRSPACE MAP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(DesignTokens.textMuted)
                } icon: {
                    Image(systemName: "map.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(DesignTokens.aeroBlue)
                }

                Spacer()

                if let ident = airspace?.airportIdent {
                    Text("REF: \(ident)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(DesignTokens.aeroBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(DesignTokens.aeroBlue.opacity(0.12))
                        )
                }
            }

            ZStack(alignment: .bottomTrailing) {
                Map(position: $position) {
                    // Operational 400 ft (~122m) buffer circle around pilot launch point
                    MapCircle(center: activeCoordinate, radius: 122)
                        .foregroundStyle(DesignTokens.aeroBlue.opacity(0.15))
                        .stroke(DesignTokens.aeroBlue, lineWidth: 1.5)

                    // Drone Pin Annotation
                    Annotation("Launch Point", coordinate: activeCoordinate) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.canvasBackground)
                                .frame(width: 38, height: 38)
                                .shadow(color: .black.opacity(0.5), radius: 4)

                            Circle()
                                .stroke(DesignTokens.aeroBlue, lineWidth: 2)
                                .frame(width: 36, height: 36)

                            Image(systemName: "airplane")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(DesignTokens.aeroBlue)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
                .mapStyle(.hybrid(elevation: .realistic))
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusM))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                        .stroke(DesignTokens.cardBorder, lineWidth: 1)
                )

                // Recenter Button
                Button {
                    withAnimation {
                        position = .camera(MapCamera(centerCoordinate: activeCoordinate, distance: 1200))
                    }
                } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(DesignTokens.cardBackground.opacity(0.9))
                                .overlay(Circle().stroke(DesignTokens.cardBorder, lineWidth: 1))
                        )
                }
                .padding(DesignTokens.spaceS)
            }
            .onChange(of: coordinate?.latitude) { _, _ in
                withAnimation {
                    position = .camera(MapCamera(centerCoordinate: activeCoordinate, distance: 1200))
                }
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
    }
}
