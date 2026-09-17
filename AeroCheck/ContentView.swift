//
//  ContentView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import CoreLocation

/// Primary Flight Dashboard conforming to Apple Human Interface Guidelines:
/// - Semantic typography (Headline, Subheadline, Footnote)
/// - Flat surfaces with precise 1pt hairline borders (zero floating gradients or glowing shadows)
/// - Single dominant interactive accent (aviation cobalt)
/// - Strict 8pt layout rhythm and 44x44pt minimum touch targets
/// - Explicit micro-interactions on all controls
struct ContentView: View {
    @State private var viewModel = FlightDashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: DesignTokens.space16) {
                        // Top Flight Header: Location & Drone Selector Pills
                        flightHeaderView

                        // 1. Hero Go / Caution / No-Go Verdict Banner
                        VerdictBannerView(
                            result: viewModel.riskResult,
                            isLoading: viewModel.isLoading
                        )

                        // 2. Tactical Airspace Map Card
                        FlightMapView(
                            coordinate: viewModel.locationManager.coordinate,
                            airspace: viewModel.airspace
                        )

                        // 3. Airspace & LAANC Authorization Card
                        AirspaceCardView(
                            airspace: viewModel.airspace,
                            onOpenLAANC: {
                                viewModel.openLAANCProvider()
                            }
                        )

                        // 4. Atmospheric Sounding & 400ft Wind Shear Profile Card
                        WindShearCardView(
                            weather: viewModel.weather,
                            drone: viewModel.selectedDrone,
                            densityAltitude: viewModel.riskResult?.densityAltitudeFeet ?? 0,
                            thrustLossPercent: viewModel.riskResult?.thrustEfficiencyLossPercent
                        )

                        // Bottom clearance for persistent action button
                        Color.clear.frame(height: 72)
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
                    HStack(spacing: DesignTokens.space8) {
                        Button {
                            viewModel.showCoordinateSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(DesignTokens.textSecondary)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.interactivePress)

                        Button {
                            Task {
                                await viewModel.refreshData()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(DesignTokens.accent)
                                .frame(width: 44, height: 44)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.interactivePress)
                    }
                }
            }
            // Sheet presentations
            .sheet(isPresented: $viewModel.showChecklistSheet) {
                PreFlightChecklistView(
                    record: $viewModel.signOffRecord,
                    onCompleteAndGeneratePDF: {
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

    private var flightHeaderView: some View {
        HStack(alignment: .center, spacing: DesignTokens.space8) {
            // Location Badge with 44pt tap target
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

            // Drone Fleet Selector Pill with 44pt tap target
            Button {
                viewModel.showDronePickerSheet = true
            } label: {
                HStack(spacing: DesignTokens.space4) {
                    Image(systemName: "airplane")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.accent)

                    Text(viewModel.selectedDrone.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
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
