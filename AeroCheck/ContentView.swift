//
//  ContentView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import CoreLocation

/// AAA Tactical Flight Dashboard adhering to ForeFlight, DJI Fly, and Apple HIG:
/// - Pure OLED Black canvas (#000000) with Apple secondarySystemBackground cards (#1C1C1E).
/// - 0.5pt subtle hairline borders matching native Apple separators.
/// - Floating tactile action capsule anchored at bottom with haptic feedback and safe-area clearance.
/// - Native inline drone fleet switcher menu.
struct ContentView: View {
    @State private var viewModel = FlightDashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Scrollable Telemetry Surface
                ScrollView {
                    VStack(spacing: DesignTokens.space16) {
                        // Tactical Flight Context Bar (GPS Location + Fleet Menu)
                        flightContextBar

                        // Tactical Mission Altitude Selector (100ft - 400ft AGL)
                        missionAltitudeSelector

                        // 1. Master Verdict Hero Banner
                        VerdictBannerView(
                            result: viewModel.riskResult,
                            isLoading: viewModel.isLoading,
                            relativeTime: viewModel.relativeLastUpdatedString,
                            stationId: viewModel.weather?.stationId
                        )

                        // 2. Tactical Airspace & LAANC Authorization
                        AirspaceCardView(
                            airspace: viewModel.airspace,
                            onOpenLAANC: {
                                viewModel.openLAANCProvider()
                            }
                        )

                        // 3. Seamless Tactical Map
                        FlightMapView(
                            coordinate: viewModel.locationManager.coordinate,
                            airspace: viewModel.airspace
                        )

                        // 4. Atmospheric Sounding & Altitude-Specific Wind Envelope
                        WindShearCardView(
                            weather: viewModel.weather,
                            drone: viewModel.selectedDrone,
                            densityAltitude: viewModel.riskResult?.densityAltitudeFeet ?? 0,
                            thrustLossPercent: viewModel.riskResult?.thrustEfficiencyLossPercent,
                            plannedAltitude: viewModel.plannedAltitudeFeet
                        )

                        // Clear padding so scroll view content clears the floating action capsule
                        Color.clear.frame(height: 88)
                    }
                    .padding(.horizontal, DesignTokens.space16)
                    .padding(.top, DesignTokens.space8)
                }
                .refreshable {
                    await viewModel.refreshData()
                }

                // Floating Tactical Action Capsule (Bottom Anchor)
                floatingActionAnchor
            }
            .background(DesignTokens.surfacePrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Top-Left App / Fleet Icon Button
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        viewModel.showDronePickerSheet = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.16), lineWidth: 0.5)
                                )

                            Image(systemName: "drone.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(DesignTokens.accent)
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.interactivePress)
                    .accessibilityLabel("Active Aircraft Fleet")
                }

                // Centered App Identity
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 6) {
                        Text("AEROCHECK")
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .tracking(1.4)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }
                }

                // Top-Right Sync / Refresh Button
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .medium)
                        impact.impactOccurred()
                        Task {
                            await viewModel.refreshData()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.16), lineWidth: 0.5)
                                )

                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(DesignTokens.accent)
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(DesignTokens.accent)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                    }
                    .buttonStyle(.interactivePress)
                    .disabled(viewModel.isLoading)
                    .accessibilityLabel("Refresh and Resync Telemetry")
                }
            }
            // Sheets
            .sheet(isPresented: $viewModel.showChecklistSheet) {
                PreFlightChecklistView(
                    record: $viewModel.signOffRecord,
                    onCompleteAndGeneratePDF: {
                        viewModel.savePilotCredentials()
                        viewModel.generateAuditPDF()
                    }
                )
            }
            .sheet(isPresented: $viewModel.showPDFShareSheet) {
                PDFPreviewSheet(pdfData: viewModel.generatedPDFData)
            }
            .sheet(isPresented: $viewModel.showDronePickerSheet) {
                DroneProfilePickerView(
                    profiles: viewModel.droneProfiles,
                    selectedProfile: viewModel.selectedDrone,
                    onSelect: { profile in
                        viewModel.selectDrone(profile)
                    },
                    onAddCustom: { custom in
                        viewModel.addCustomDrone(custom)
                    },
                    onUpdate: { updated in
                        viewModel.updateDrone(updated)
                    },
                    onDelete: { toDelete in
                        viewModel.deleteDrone(toDelete)
                    },
                    onResetDefaults: {
                        viewModel.resetDroneFleetToDefaults()
                    }
                )
            }
            .sheet(isPresented: $viewModel.showCoordinateSheet) {
                CoordinateEntrySheet(
                    currentCoordinate: viewModel.locationManager.coordinate,
                    onResetToGPS: {
                        viewModel.locationManager.requestCurrentLocation()
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            await viewModel.refreshData()
                        }
                    },
                    onSelectCoordinate: { lat, lon, name in
                        viewModel.locationManager.setManualCoordinate(latitude: lat, longitude: lon, name: name)
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                )
            }
            .task {
                viewModel.onAppear()
                try? await Task.sleep(nanoseconds: 600_000_000)
                await viewModel.refreshData()
            }
            .onChange(of: viewModel.locationManager.coordinate?.latitude) { _, _ in
                Task {
                    await viewModel.refreshData()
                }
            }
        }
    }

    // MARK: - Subviews

    private var flightContextBar: some View {
        HStack(alignment: .center, spacing: DesignTokens.space8) {
            // Location Trigger Pill
            Button {
                viewModel.showCoordinateSheet = true
            } label: {
                HStack(spacing: DesignTokens.space6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.accent)
                        .frame(width: 16, height: 16, alignment: .center)

                    Text(viewModel.locationManager.placemarkName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.horizontal, DesignTokens.space12)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                        .fill(DesignTokens.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                .stroke(DesignTokens.borderHairline.opacity(0.8), lineWidth: 0.5)
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.interactivePress)

            Spacer()

            // Native Drone Fleet Menu
            Menu {
                Section("Active Airframe") {
                    ForEach(viewModel.droneProfiles) { profile in
                        Button {
                            viewModel.selectDrone(profile)
                        } label: {
                            HStack {
                                Text(profile.name)
                                if profile.id == viewModel.selectedDrone.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Section {
                    Button {
                        viewModel.showDronePickerSheet = true
                    } label: {
                        Label("Manage Fleet...", systemImage: "slider.horizontal.3")
                    }
                }
            } label: {
                HStack(spacing: DesignTokens.space6) {
                    Image(systemName: "drone.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DesignTokens.accent)
                        .frame(width: 16, height: 16, alignment: .center)

                    Text(viewModel.selectedDrone.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.horizontal, DesignTokens.space12)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                        .fill(DesignTokens.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                .stroke(DesignTokens.borderHairline.opacity(0.8), lineWidth: 0.5)
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.interactivePress)
        }
    }

    /// Tactical Planned Mission Altitude Selector (100ft, 200ft, 300ft, 400ft AGL)
    /// Allows pilot to specify target flight altitude so low-altitude operations are not blocked
    /// by high-altitude wind shear at 400ft.
    private var missionAltitudeSelector: some View {
        VStack(spacing: 6) {
            // Instrument Subtitle Row
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.2.square")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DesignTokens.accent)

                    Text("TARGET MISSION ALTITUDE")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .tracking(0.6)
                        .foregroundStyle(DesignTokens.textTertiary)
                }

                Spacer()

                Text(viewModel.plannedAltitudeFeet == 400 ? "400 FT AGL (FAA MAX)" : "\(viewModel.plannedAltitudeFeet) FT AGL TARGET")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(DesignTokens.accent)
            }
            .padding(.horizontal, 2)

            // Equal-Width Segmented Flight Ceiling Bar
            HStack(spacing: 4) {
                ForEach([100, 200, 300, 400], id: \.self) { alt in
                    let isSelected = viewModel.plannedAltitudeFeet == alt
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        withAnimation(.snappy(duration: 0.2)) {
                            viewModel.setPlannedAltitude(alt)
                        }
                    } label: {
                        Text("\(alt) FT")
                            .font(.system(size: 12, weight: isSelected ? .heavy : .semibold, design: .monospaced))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                            .foregroundStyle(isSelected ? .white : DesignTokens.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isSelected ? DesignTokens.accent : Color.white.opacity(0.04))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Set planned altitude to \(alt) feet AGL")
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(DesignTokens.surfaceSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(DesignTokens.borderHairline, lineWidth: 0.5)
                    )
            )
        }
    }

    /// Premium Native Sticky Bottom Bar with Translucent Backdrop Blur
    private var floatingActionAnchor: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(DesignTokens.borderHairline)
                .frame(height: 0.5)

            Button {
                viewModel.showChecklistSheet = true
            } label: {
                HStack(spacing: DesignTokens.space12) {
                    Image(systemName: "checklist.checked")
                        .font(.headline.weight(.heavy))

                    Text("Pre-Flight Verification & Sign-Off")
                        .font(.subheadline.weight(.bold))
                        .tracking(-0.2)

                    Spacer()

                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 52)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule(style: .continuous)
                        .fill(DesignTokens.accent)
                        .overlay(
                            Capsule(style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                )
            }
            .buttonStyle(.interactivePress)
            .padding(.horizontal, DesignTokens.space16)
            .padding(.top, 10)
            .padding(.bottom, 6)
        }
        .background(.ultraThinMaterial)
    }
}

#Preview {
    ContentView()
}
