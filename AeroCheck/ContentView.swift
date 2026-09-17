//
//  ContentView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @State private var viewModel = FlightDashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: DesignTokens.spaceM) {
                        // Top Flight Header: Location & Drone Selector Pill
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

                        // Padding for sticky bottom CTA
                        Color.clear.frame(height: 72)
                    }
                    .padding(.horizontal, DesignTokens.spaceM)
                    .padding(.top, DesignTokens.spaceS)
                }
                .refreshable {
                    await viewModel.refreshData()
                }

                // Sticky Bottom Action Bar
                bottomActionBar
            }
            .background(DesignTokens.canvasBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(DesignTokens.aeroBlue)
                        Text("AeroCheck")
                            .font(.system(size: 17, weight: .black, design: .monospaced))
                            .foregroundStyle(DesignTokens.textPrimary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DesignTokens.spaceS) {
                        Button {
                            viewModel.showCoordinateSheet = true
                        } label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(DesignTokens.textSecondary)
                                .frame(minWidth: 44, minHeight: 44)
                        }

                        Button {
                            Task {
                                await viewModel.refreshData()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(DesignTokens.aeroBlue)
                                .frame(minWidth: 44, minHeight: 44)
                        }
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
                // Initial data load when location is established
                try? await Task.sleep(nanoseconds: 600_000_000)
                await viewModel.refreshData()
            }
        }
    }

    // MARK: - Subviews

    private var flightHeaderView: some View {
        HStack(alignment: .center, spacing: DesignTokens.spaceS) {
            // Location Badge
            Button {
                viewModel.showCoordinateSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 12))
                        .foregroundStyle(DesignTokens.aeroBlue)

                    Text(viewModel.locationManager.placemarkName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(DesignTokens.cardBackground)
                        .overlay(Capsule().stroke(DesignTokens.cardBorder, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)

            Spacer()

            // Drone Profile Pill
            Button {
                viewModel.showDronePickerSheet = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "airplane")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(DesignTokens.aeroBlue)

                    Text(viewModel.selectedDrone.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DesignTokens.textPrimary)
                        .lineLimit(1)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundStyle(DesignTokens.textMuted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(DesignTokens.cardBackground)
                        .overlay(Capsule().stroke(DesignTokens.cardBorder, lineWidth: 1))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [DesignTokens.canvasBackground.opacity(0), DesignTokens.canvasBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 18)

            HStack(spacing: DesignTokens.spaceM) {
                Button {
                    viewModel.showChecklistSheet = true
                } label: {
                    HStack(spacing: DesignTokens.spaceS) {
                        Image(systemName: "checklist.checked")
                            .font(.system(size: 16, weight: .bold))
                        Text("Pre-Flight Check & PDF Sign-Off")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                            .fill(DesignTokens.aeroBlue)
                            .shadow(color: DesignTokens.aeroBlue.opacity(0.3), radius: 8, y: 3)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DesignTokens.spaceM)
            .padding(.bottom, DesignTokens.spaceM)
            .background(DesignTokens.canvasBackground)
        }
    }
}

#Preview {
    ContentView()
}
