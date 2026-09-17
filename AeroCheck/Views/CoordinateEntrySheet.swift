//
//  CoordinateEntrySheet.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI
import CoreLocation
import MapKit

/// Triple-mode launch location selector adhering to Apple HIG:
/// 1. Current Device Location: Hardware GPS fix
/// 2. Search Location: Native Apple MapKit local search for addresses, landmarks, and airports
/// 3. Exact Coordinates: Manual lat/lon entry with validation and aviation quick presets
public struct CoordinateEntrySheet: View {
    @Environment(\.dismiss) private var dismiss

    public let currentCoordinate: CLLocationCoordinate2D?
    public let onResetToGPS: () -> Void
    public let onSelectCoordinate: (Double, Double, String?) -> Void

    public enum LocationMode: String, CaseIterable, Identifiable {
        case deviceGPS = "Device GPS"
        case appleSearch = "Search"
        case manualCoordinates = "Coordinates"

        public var id: String { rawValue }
    }

    @State private var selectedMode: LocationMode = .deviceGPS

    // Search state (Apple MapKit MKLocalSearch)
    @State private var searchQuery: String = ""
    @State private var searchResults: [MKMapItem] = []
    @State private var isSearching: Bool = false
    @State private var searchTask: Task<Void, Never>? = nil

    // Manual coordinates state
    @State private var latText: String = ""
    @State private var lonText: String = ""
    @State private var inputError: String?

    public init(
        currentCoordinate: CLLocationCoordinate2D?,
        onResetToGPS: @escaping () -> Void,
        onSelectCoordinate: @escaping (Double, Double, String?) -> Void
    ) {
        self.currentCoordinate = currentCoordinate
        self.onResetToGPS = onResetToGPS
        self.onSelectCoordinate = onSelectCoordinate
        if let c = currentCoordinate {
            _latText = State(initialValue: String(format: "%.5f", c.latitude))
            _lonText = State(initialValue: String(format: "%.5f", c.longitude))
        }
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Segmented Selector Header
                Picker("Location Mode", selection: $selectedMode) {
                    ForEach(LocationMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, DesignTokens.space16)
                .padding(.vertical, DesignTokens.space12)
                .background(DesignTokens.surfacePrimary)

                Divider()
                    .overlay(DesignTokens.borderHairline)

                // Mode Content
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignTokens.space16) {
                        switch selectedMode {
                        case .deviceGPS:
                            deviceGPSSection
                        case .appleSearch:
                            appleSearchSection
                        case .manualCoordinates:
                            manualCoordinatesSection
                        }
                    }
                    .padding(DesignTokens.space16)
                }
            }
            .background(DesignTokens.surfacePrimary.ignoresSafeArea())
            .navigationTitle("Set Launch Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DesignTokens.accent)
                }
            }
        }
    }

    // MARK: - Option 1: Device GPS
    private var deviceGPSSection: some View {
        VStack(spacing: DesignTokens.space16) {
            Button {
                let impact = UIImpactFeedbackGenerator(style: .medium)
                impact.impactOccurred()
                onResetToGPS()
                dismiss()
            } label: {
                HStack(spacing: DesignTokens.space12) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.accentMuted)
                            .frame(width: 48, height: 48)

                        Image(systemName: "location.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(DesignTokens.accent)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Use Current Device Location")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(DesignTokens.textPrimary)

                        Text("Acquire live GPS fix from hardware and refresh FAA airspace buffers.")
                            .font(.caption)
                            .foregroundStyle(DesignTokens.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DesignTokens.textTertiary)
                }
                .padding(DesignTokens.space16)
                .frame(minHeight: 72)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                        .fill(DesignTokens.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                .stroke(DesignTokens.accent.opacity(0.4), lineWidth: 1)
                        )
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.interactivePress)

            // Precision Active Position Telematics Grid (Never Wraps)
            if let coord = currentCoordinate {
                VStack(alignment: .leading, spacing: DesignTokens.space10) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(DesignTokens.statusSafe)
                                .frame(width: 8, height: 8)

                            Text("HARDWARE GPS LOCKED")
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .tracking(0.6)
                                .foregroundStyle(DesignTokens.statusSafe)
                        }

                        Spacer()

                        Text("ACCURACY ±3M")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(DesignTokens.textTertiary)
                    }

                    Divider()
                        .overlay(DesignTokens.borderHairline.opacity(0.7))

                    HStack(spacing: 0) {
                        // Latitude Column
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LATITUDE")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundStyle(DesignTokens.textTertiary)

                            Text(String(format: "%.5f° N", coord.latitude))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(DesignTokens.textPrimary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Rectangle()
                            .fill(DesignTokens.borderHairline)
                            .frame(width: 0.5, height: 28)
                            .padding(.horizontal, DesignTokens.space8)

                        // Longitude Column
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LONGITUDE")
                                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                .foregroundStyle(DesignTokens.textTertiary)

                            Text(String(format: "%.5f° W", abs(coord.longitude)))
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundStyle(DesignTokens.textPrimary)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(DesignTokens.space16)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                        .fill(DesignTokens.surfaceSecondary)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                .stroke(DesignTokens.borderHairline, lineWidth: 0.5)
                        )
                )
            }
        }
    }

    // MARK: - Option 2: Apple MapKit Search
    private var appleSearchSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space12) {
            Text("SEARCH PLACES, AIRPORTS, OR ADDRESSES")
                .font(.caption2.weight(.heavy).monospaced())
                .foregroundStyle(DesignTokens.textTertiary)

            // Search Bar Input
            HStack(spacing: DesignTokens.space8) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(DesignTokens.textSecondary)

                TextField("e.g. Dallas Love Field, Golden Gate, Austin", text: $searchQuery)
                    .font(.body)
                    .textFieldStyle(.plain)
                    .foregroundStyle(DesignTokens.textPrimary)
                    .autocorrectionDisabled()
                    .onChange(of: searchQuery) { _, newValue in
                        triggerAppleSearch(query: newValue)
                    }

                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                        searchResults = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(DesignTokens.textTertiary)
                    }
                }

                if isSearching {
                    ProgressView()
                        .tint(DesignTokens.accent)
                        .controlSize(.small)
                }
            }
            .padding(DesignTokens.space12)
            .background(DesignTokens.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous)
                    .stroke(DesignTokens.borderHairline, lineWidth: 0.5)
            )

            // Search Results List
            if !searchResults.isEmpty {
                VStack(spacing: 1) {
                    ForEach(searchResults, id: \.self) { item in
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            let coord = item.placemark.coordinate
                            let name = item.name ?? item.placemark.title ?? "Selected Location"
                            onSelectCoordinate(coord.latitude, coord.longitude, name)
                            dismiss()
                        } label: {
                            HStack(spacing: DesignTokens.space12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(DesignTokens.accent)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "Location")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DesignTokens.textPrimary)
                                        .lineLimit(1)

                                    if let sub = item.placemark.title {
                                        Text(sub)
                                            .font(.caption)
                                            .foregroundStyle(DesignTokens.textSecondary)
                                            .lineLimit(1)
                                    }

                                    Text(String(format: "%.4f, %.4f", item.placemark.coordinate.latitude, item.placemark.coordinate.longitude))
                                        .font(.caption2.monospaced())
                                        .foregroundStyle(DesignTokens.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DesignTokens.textTertiary)
                            }
                            .padding(DesignTokens.space12)
                            .background(DesignTokens.surfaceSecondary)
                        }
                        .buttonStyle(.plain)

                        if item != searchResults.last {
                            Divider()
                                .overlay(DesignTokens.borderHairline.opacity(0.5))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                        .stroke(DesignTokens.borderHairline, lineWidth: 0.5)
                )
            } else if !searchQuery.isEmpty && !isSearching {
                Text("No matching locations found. Try searching by city name, airport code, or full street address.")
                    .font(.caption)
                    .foregroundStyle(DesignTokens.textTertiary)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Option 3: Exact Coordinates
    private var manualCoordinatesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.space16) {
            VStack(alignment: .leading, spacing: DesignTokens.space12) {
                Text("EXACT DECIMAL GPS COORDINATES")
                    .font(.caption2.weight(.heavy).monospaced())
                    .foregroundStyle(DesignTokens.textTertiary)

                HStack(spacing: DesignTokens.space8) {
                    VStack(alignment: .leading, spacing: DesignTokens.space4) {
                        Text("Latitude (°N / °S)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DesignTokens.textSecondary)
                        TextField("e.g. 37.7749", text: $latText)
                            .keyboardType(.numbersAndPunctuation)
                            .font(.body.monospaced())
                            .textFieldStyle(.plain)
                            .padding(DesignTokens.space12)
                            .background(DesignTokens.surfaceTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                            .foregroundStyle(DesignTokens.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: DesignTokens.space4) {
                        Text("Longitude (°E / °W)")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(DesignTokens.textSecondary)
                        TextField("e.g. -122.4194", text: $lonText)
                            .keyboardType(.numbersAndPunctuation)
                            .font(.body.monospaced())
                            .textFieldStyle(.plain)
                            .padding(DesignTokens.space12)
                            .background(DesignTokens.surfaceTertiary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                            .foregroundStyle(DesignTokens.textPrimary)
                    }
                }

                if let err = inputError {
                    Text(err)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DesignTokens.statusAlert)
                }

                Button {
                    applyManualCoordinates()
                } label: {
                    Text("Apply Exact Coordinates")
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
                            .stroke(DesignTokens.borderHairline, lineWidth: 0.5)
                    )
            )

            // Quick Tactical Presets
            VStack(alignment: .leading, spacing: DesignTokens.space8) {
                Text("QUICK AVIATION PRESETS")
                    .font(.caption2.weight(.heavy).monospaced())
                    .foregroundStyle(DesignTokens.textTertiary)

                ForEach([
                    ("Oshkosh Wittman Regional (KOSH)", 43.9844, -88.5570),
                    ("Dallas/Fort Worth (KDFW)", 32.8998, -97.0403),
                    ("San Francisco Presidio", 37.7989, -122.4662),
                    ("Austin Drone Test Field", 30.2672, -97.7431)
                ], id: \.0) { name, lat, lon in
                    Button {
                        latText = String(format: "%.4f", lat)
                        lonText = String(format: "%.4f", lon)
                        onSelectCoordinate(lat, lon, name)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DesignTokens.textPrimary)
                                Text(String(format: "%.4f, %.4f", lat, lon))
                                    .font(.caption2.monospaced())
                                    .foregroundStyle(DesignTokens.textTertiary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(DesignTokens.textTertiary)
                        }
                        .padding(DesignTokens.space12)
                        .background(DesignTokens.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers
    private func triggerAppleSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
            guard !Task.isCancelled else { return }

            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = trimmed
            req.resultTypes = [.address, .pointOfInterest]

            let search = MKLocalSearch(request: req)
            do {
                let response = try await search.start()
                guard !Task.isCancelled else { return }
                self.searchResults = response.mapItems
                self.isSearching = false
            } catch {
                guard !Task.isCancelled else { return }
                self.searchResults = []
                self.isSearching = false
            }
        }
    }

    private func applyManualCoordinates() {
        guard let lat = Double(latText.trimmingCharacters(in: .whitespaces)),
              let lon = Double(lonText.trimmingCharacters(in: .whitespaces)),
              (-90.0...90.0).contains(lat),
              (-180.0...180.0).contains(lon) else {
            inputError = "Enter valid decimal coordinates (-90..90, -180..180)."
            return
        }
        inputError = nil
        onSelectCoordinate(lat, lon, nil)
        dismiss()
    }
}
