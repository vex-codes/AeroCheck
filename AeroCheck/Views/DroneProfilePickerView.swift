//
//  DroneProfilePickerView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Tactical airframe fleet management modal conforming to Apple HIG:
/// - Full CRUD support: Select, Edit/Rename specs, Delete airframe, and Reset to DJI Factory Presets.
/// - Minimum 44x44pt touch targets with active press feedback.
/// - Inset cards with hairline borders.
public struct DroneProfilePickerView: View {
    @Environment(\.dismiss) private var dismiss

    public let profiles: [DroneProfile]
    public let selectedProfile: DroneProfile
    public let onSelect: (DroneProfile) -> Void
    public let onAddCustom: (DroneProfile) -> Void
    public let onUpdate: (DroneProfile) -> Void
    public let onDelete: (DroneProfile) -> Void
    public let onResetDefaults: () -> Void

    @State private var isAddingCustom: Bool = false
    @State private var droneToEdit: DroneProfile? = nil
    @State private var droneToDelete: DroneProfile? = nil
    @State private var showResetConfirm: Bool = false

    // Custom airframe fields
    @State private var customName: String = ""
    @State private var customWeight: String = "249"
    @State private var customMaxWind: String = "24"
    @State private var customMinTemp: String = "-10"
    @State private var customMaxTemp: String = "40"
    @State private var customCategory: String = "Commercial Custom"

    public init(
        profiles: [DroneProfile],
        selectedProfile: DroneProfile,
        onSelect: @escaping (DroneProfile) -> Void,
        onAddCustom: @escaping (DroneProfile) -> Void,
        onUpdate: @escaping (DroneProfile) -> Void,
        onDelete: @escaping (DroneProfile) -> Void,
        onResetDefaults: @escaping () -> Void
    ) {
        self.profiles = profiles
        self.selectedProfile = selectedProfile
        self.onSelect = onSelect
        self.onAddCustom = onAddCustom
        self.onUpdate = onUpdate
        self.onDelete = onDelete
        self.onResetDefaults = onResetDefaults
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.space16) {
                    // Fleet List Header with Count
                    HStack {
                        Text("ACTIVE AIRFRAME FLEET (\(profiles.count))")
                            .font(.caption2.weight(.heavy).monospaced())
                            .tracking(0.6)
                            .foregroundStyle(DesignTokens.textTertiary)

                        Spacer()

                        Button {
                            showResetConfirm = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 10, weight: .bold))
                                Text("DJI Factory Reset")
                                    .font(.caption2.weight(.semibold))
                            }
                            .foregroundStyle(DesignTokens.textSecondary)
                        }
                    }
                    .padding(.horizontal, 4)

                    // Profile Cards
                    VStack(spacing: DesignTokens.space8) {
                        ForEach(profiles) { profile in
                            let isSelected = profile.id == selectedProfile.id
                            HStack(spacing: DesignTokens.space12) {
                                // Selectable Aircraft Area
                                Button {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    onSelect(profile)
                                    dismiss()
                                } label: {
                                    HStack(spacing: DesignTokens.space12) {
                                        ZStack {
                                            Circle()
                                                .fill(isSelected ? DesignTokens.accentMuted : DesignTokens.surfaceTertiary)
                                                .frame(width: 38, height: 38)

                                            Image(systemName: "drone.fill")
                                                .font(.subheadline.weight(.bold))
                                                .foregroundStyle(isSelected ? DesignTokens.accent : DesignTokens.textSecondary)
                                        }

                                        VStack(alignment: .leading, spacing: 3) {
                                            HStack {
                                                Text(profile.name)
                                                    .font(.subheadline.weight(.bold))
                                                    .foregroundStyle(DesignTokens.textPrimary)
                                                    .lineLimit(1)

                                                if isSelected {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.caption.weight(.bold))
                                                        .foregroundStyle(DesignTokens.statusSafe)
                                                }
                                            }

                                            HStack(spacing: DesignTokens.space6) {
                                                // Weight badge
                                                Text("\(Int(profile.weightGrams))g")
                                                    .font(.caption2.weight(.heavy).monospaced())
                                                    .foregroundStyle(profile.weightGrams < 250 ? DesignTokens.statusSafe : DesignTokens.textSecondary)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(
                                                        Capsule().fill(profile.weightGrams < 250 ? DesignTokens.statusSafeMuted : DesignTokens.surfaceTertiary)
                                                    )

                                                // Wind limit
                                                HStack(spacing: 2) {
                                                    Image(systemName: "wind")
                                                        .font(.system(size: 9))
                                                    Text("\(Int(profile.maxWindResistanceMph)) mph")
                                                        .font(.caption2.weight(.medium))
                                                }
                                                .foregroundStyle(DesignTokens.textSecondary)

                                                Text("•")
                                                    .font(.caption2)
                                                    .foregroundStyle(DesignTokens.textTertiary)

                                                Text(profile.category)
                                                    .font(.caption2)
                                                    .foregroundStyle(DesignTokens.textTertiary)
                                                    .lineLimit(1)
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                // Management Action Menu (Edit/Rename, Delete)
                                Menu {
                                    Button {
                                        droneToEdit = profile
                                    } label: {
                                        Label("Edit / Rename Drone", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        droneToDelete = profile
                                    } label: {
                                        Label("Delete Airframe", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(.system(size: 20))
                                        .foregroundStyle(DesignTokens.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .contentShape(Rectangle())
                                }
                            }
                            .padding(DesignTokens.space12)
                            .frame(minHeight: 56)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                    .fill(DesignTokens.surfaceSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                            .stroke(isSelected ? DesignTokens.accent : DesignTokens.borderHairline, lineWidth: isSelected ? 1.5 : 0.5)
                                    )
                            )
                        }
                    }

                    // Add Custom Airframe Trigger / Form
                    if !isAddingCustom {
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                isAddingCustom = true
                            }
                        } label: {
                            HStack(spacing: DesignTokens.space8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.subheadline)
                                Text("Add Custom Airframe Configuration")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .foregroundStyle(DesignTokens.accent)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                    .fill(DesignTokens.surfaceSecondary)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                            .stroke(DesignTokens.borderHairline, lineWidth: 0.5)
                                    )
                            )
                        }
                        .buttonStyle(.interactivePress)
                    } else {
                        // Custom Airframe Entry Form
                        VStack(alignment: .leading, spacing: DesignTokens.space12) {
                            Text("NEW AIRFRAME SPECIFICATIONS")
                                .font(.caption2.weight(.semibold).monospaced())
                                .foregroundStyle(DesignTokens.textTertiary)

                            TextField("Airframe Name (e.g. Freefly Astro)", text: $customName)
                                .font(.body)
                                .textFieldStyle(.plain)
                                .padding(DesignTokens.space12)
                                .background(DesignTokens.surfaceTertiary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                .foregroundStyle(DesignTokens.textPrimary)

                            HStack(spacing: DesignTokens.space8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weight (g)")
                                        .font(.caption)
                                        .foregroundStyle(DesignTokens.textSecondary)
                                    TextField("Grams", text: $customWeight)
                                        .keyboardType(.numberPad)
                                        .font(.body)
                                        .textFieldStyle(.plain)
                                        .padding(DesignTokens.space12)
                                        .background(DesignTokens.surfaceTertiary)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Max Wind (mph)")
                                        .font(.caption)
                                        .foregroundStyle(DesignTokens.textSecondary)
                                    TextField("MPH", text: $customMaxWind)
                                        .keyboardType(.decimalPad)
                                        .font(.body)
                                        .textFieldStyle(.plain)
                                        .padding(DesignTokens.space12)
                                        .background(DesignTokens.surfaceTertiary)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                }
                            }

                            HStack(spacing: DesignTokens.space8) {
                                Button("Cancel") {
                                    withAnimation(.snappy(duration: 0.25)) { isAddingCustom = false }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .foregroundStyle(DesignTokens.textSecondary)
                                .font(.subheadline)

                                Button("Save Airframe") {
                                    saveCustom()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(DesignTokens.accent)
                                .foregroundStyle(.white)
                                .font(.subheadline.weight(.semibold))
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusInner, style: .continuous))
                                .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
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
                .padding(DesignTokens.space16)
            }
            .background(DesignTokens.surfacePrimary.ignoresSafeArea())
            .navigationTitle("Airframe Fleet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DesignTokens.accent)
                }
            }
            // Edit Sheet
            .sheet(item: $droneToEdit) { drone in
                EditDroneSheet(
                    drone: drone,
                    onSave: { updated in
                        onUpdate(updated)
                        droneToEdit = nil
                    }
                )
            }
            // Delete Confirmation
            .alert("Delete Airframe?", isPresented: Binding(
                get: { droneToDelete != nil },
                set: { if !$0 { droneToDelete = nil } }
            )) {
                Button("Cancel", role: .cancel) { droneToDelete = nil }
                Button("Delete", role: .destructive) {
                    if let toDelete = droneToDelete {
                        onDelete(toDelete)
                        droneToDelete = nil
                    }
                }
            } message: {
                if let d = droneToDelete {
                    Text("Are you sure you want to remove \"\(d.name)\" from your active fleet?")
                }
            }
            // Reset to Factory Presets Confirmation
            .alert("Reset Fleet to DJI Factory Defaults?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset All", role: .destructive) {
                    onResetDefaults()
                }
            } message: {
                Text("This will restore all standard DJI drone specifications (Mini 4, Air 3, Mavic 3, Avata 2, Inspire 3, M350 RTK, etc.) and remove customized airframes.")
            }
        }
    }

    private func saveCustom() {
        guard !customName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let profile = DroneProfile(
            name: customName.trimmingCharacters(in: .whitespaces),
            weightGrams: Double(customWeight) ?? 500,
            maxWindResistanceMph: Double(customMaxWind) ?? 25,
            maxOperatingTempC: Double(customMaxTemp) ?? 40,
            minOperatingTempC: Double(customMinTemp) ?? -10,
            category: customCategory
        )
        onAddCustom(profile)
        customName = ""
        isAddingCustom = false
    }
}

/// Modal for renaming and editing airframe performance parameters.
private struct EditDroneSheet: View {
    @Environment(\.dismiss) private var dismiss

    let drone: DroneProfile
    let onSave: (DroneProfile) -> Void

    @State private var name: String
    @State private var weight: String
    @State private var maxWind: String
    @State private var category: String

    init(drone: DroneProfile, onSave: @escaping (DroneProfile) -> Void) {
        self.drone = drone
        self.onSave = onSave
        _name = State(initialValue: drone.name)
        _weight = State(initialValue: String(format: "%.0f", drone.weightGrams))
        _maxWind = State(initialValue: String(format: "%.0f", drone.maxWindResistanceMph))
        _category = State(initialValue: drone.category)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Airframe Identification") {
                    TextField("Drone Name", text: $name)
                    TextField("Category (e.g. Sub-250g, Commercial)", text: $category)
                }

                Section("Performance Envelope") {
                    HStack {
                        Text("Weight (Grams)")
                        Spacer()
                        TextField("Grams", text: $weight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Max Wind Resistance (MPH)")
                        Spacer()
                        TextField("MPH", text: $maxWind)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Edit Airframe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let updated = DroneProfile(
                            id: drone.id,
                            name: name.trimmingCharacters(in: .whitespaces),
                            weightGrams: Double(weight) ?? drone.weightGrams,
                            maxWindResistanceMph: Double(maxWind) ?? drone.maxWindResistanceMph,
                            maxOperatingTempC: drone.maxOperatingTempC,
                            minOperatingTempC: drone.minOperatingTempC,
                            category: category.trimmingCharacters(in: .whitespaces)
                        )
                        onSave(updated)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
