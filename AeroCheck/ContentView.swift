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

                        // 1. Master Verdict Hero Banner
                        VerdictBannerView(
                            result: viewModel.riskResult,
                            isLoading: viewModel.isLoading
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

                        // 4. Atmospheric Sounding & 400ft Wind Envelope
                        WindShearCardView(
                            weather: viewModel.weather,
                            drone: viewModel.selectedDrone,
                            densityAltitude: viewModel.riskResult?.densityAltitudeFeet ?? 0,
                            thrustLossPercent: viewModel.riskResult?.thrustEfficiencyLossPercent
                        )

                        // Clear padding so scroll view content clears the floating action capsule
                        Color.clear.frame(height: 76)
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
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: DesignTokens.space8) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DesignTokens.accent)

                        Text("AeroCheck")
                            .font(.headline.weight(.heavy))
                            .tracking(-0.3)
                            .foregroundStyle(DesignTokens.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(DesignTokens.accent)
                    }
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
        }
    }

    // MARK: - Subviews

    private var flightContextBar: some View {
        HStack(alignment: .center, spacing: DesignTokens.space8) {
            // Location Trigger Pill
            Button {
                viewModel.showCoordinateSheet = true
            } label: {
                HStack(spacing: DesignTokens.space4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(DesignTokens.accent)

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
                HStack(spacing: DesignTokens.space4) {
                    Image(systemName: "airplane")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DesignTokens.accent)

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

    /// Premium Floating Bottom Action Capsule
    private var floatingActionAnchor: some View {
        VStack(spacing: 0) {
            Button {
                viewModel.showChecklistSheet = true
            } label: {
                HStack(spacing: DesignTokens.space12) {
                    Image(systemName: "checklist.checked")
                        .font(.subheadline.weight(.heavy))

                    Text("Pre-Flight Verification & Sign-Off")
                        .font(.subheadline.weight(.bold))
                        .tracking(-0.2)

                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
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
            .padding(.bottom, DesignTokens.space8)
        }
        .background(
            LinearGradient(
                colors: [
                    DesignTokens.surfacePrimary.opacity(0.0),
                    DesignTokens.surfacePrimary.opacity(0.85),
                    DesignTokens.surfacePrimary
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea(edges: .bottom)
        )
    }
}

#Preview {
    ContentView()
}
