//
//  ContentView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import CoreLocation

/// 10x Native iOS Flight Dashboard adhering strictly to Apple HIG:
/// - Zero toolbar clutter: Native pull-to-refresh replaces manual refresh buttons.
/// - Inline native iOS Menu for drone fleet switching (no redundant full-screen modals).
/// - Pure 44x44pt minimum tap targets with subtle tactile press feedback.
/// - Flat surfaces with 1pt hairline borders (zero artificial drop shadows or floating gradients).
struct ContentView: View {
    @State private var viewModel = FlightDashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: DesignTokens.space16) {
                        // Top Context Bar: Location & Drone Fleet Quick Menu
                        flightContextBar

                        // 1. Master Verdict Hero
                        VerdictBannerView(
                            result: viewModel.riskResult,
                            isLoading: viewModel.isLoading
                        )

                        // 2. Airspace Authorization & LAANC Direct Action
                        AirspaceCardView(
                            airspace: viewModel.airspace,
                            onOpenLAANC: {
                                viewModel.openLAANCProvider()
                            }
                        )

                        // 3. Tactical Map
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

                        // Spacing for persistent bottom CTA
                        Color.clear.frame(height: 64)
                    }
                    .padding(.horizontal, DesignTokens.space16)
                    .padding(.top, DesignTokens.space8)
                }
                .refreshable {
                    await viewModel.refreshData()
                }

                // Persistent Bottom Action Bar
                bottomActionBar
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
                            .font(.headline.weight(.bold))
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
            // Dedicated sheets
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
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.caption2)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.horizontal, DesignTokens.space12)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                        .fill(DesignTokens.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                .stroke(DesignTokens.borderHairline, lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.interactivePress)

            Spacer()

            // Native iOS Drone Selection Menu
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
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.accent)

                    Text(viewModel.selectedDrone.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(.horizontal, DesignTokens.space12)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                        .fill(DesignTokens.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                                .stroke(DesignTokens.borderHairline, lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.interactivePress)
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(DesignTokens.borderHairline)

            HStack(spacing: DesignTokens.space16) {
                Button {
                    viewModel.showChecklistSheet = true
                } label: {
                    HStack(spacing: DesignTokens.space8) {
                        Image(systemName: "checklist.checked")
                            .font(.subheadline.weight(.semibold))
                        Text("Pre-Flight Verification & Sign-Off")
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
            }
            .padding(.horizontal, DesignTokens.space16)
            .padding(.vertical, DesignTokens.space12)
            .background(DesignTokens.surfacePrimary)
        }
    }
}

#Preview {
    ContentView()
}
