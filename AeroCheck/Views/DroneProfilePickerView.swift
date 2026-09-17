//
//  DroneProfilePickerView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Drone profile selection and custom airframe management sheet.
public struct DroneProfilePickerView: View {
    @Environment(\.dismiss) private var dismiss

    public let profiles: [DroneProfile]
    public let selectedProfile: DroneProfile
    public let onSelect: (DroneProfile) -> Void
    public let onAddCustom: (DroneProfile) -> Void

    @State private var isAddingCustom: Bool = false
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
        onAddCustom: @escaping (DroneProfile) -> Void
    ) {
        self.profiles = profiles
        self.selectedProfile = selectedProfile
        self.onSelect = onSelect
        self.onAddCustom = onAddCustom
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignTokens.spaceM) {
                    // Profile List
                    VStack(spacing: DesignTokens.spaceS) {
                        ForEach(profiles) { profile in
                            Button {
                                onSelect(profile)
                                dismiss()
                            } label: {
                                HStack(spacing: DesignTokens.spaceM) {
                                    ZStack {
                                        Circle()
                                            .fill(profile.id == selectedProfile.id ? DesignTokens.aeroBlue.opacity(0.2) : DesignTokens.cardBackgroundSecondary)
                                            .frame(width: 42, height: 42)

                                        Image(systemName: "airplane")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(profile.id == selectedProfile.id ? DesignTokens.aeroBlue : DesignTokens.textSecondary)
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        HStack {
                                            Text(profile.name)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundStyle(DesignTokens.textPrimary)

                                            Spacer()

                                            if profile.id == selectedProfile.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(DesignTokens.verdictSafe)
                                            }
                                        }

                                        HStack(spacing: DesignTokens.spaceS) {
                                            Text("\(Int(profile.weightGrams))g")
                                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                                .foregroundStyle(DesignTokens.textMuted)

                                            Text("•")
                                                .foregroundStyle(DesignTokens.textMuted)

                                            Text("Max Wind: \(Int(profile.maxWindResistanceMph)) mph")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(DesignTokens.textSecondary)

                                            Text("•")
                                                .foregroundStyle(DesignTokens.textMuted)

                                            Text(profile.category)
                                                .font(.system(size: 11, weight: .regular))
                                                .foregroundStyle(DesignTokens.textMuted)
                                        }
                                    }
                                }
                                .padding(DesignTokens.spaceM)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                        .fill(DesignTokens.cardBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                                .stroke(profile.id == selectedProfile.id ? DesignTokens.aeroBlue : DesignTokens.cardBorder, lineWidth: 1.2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Add Custom Button / Form
                    if !isAddingCustom {
                        Button {
                            withAnimation {
                                isAddingCustom = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("Add Custom Airframe Configuration")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(DesignTokens.aeroBlue)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 48)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                    .fill(DesignTokens.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.radiusM)
                                            .stroke(DesignTokens.aeroBlue.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    } else {
                        // Custom Drone Form
                        VStack(alignment: .leading, spacing: DesignTokens.spaceM) {
                            Text("CUSTOM AIRFRAME SPECIFICATIONS")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(DesignTokens.textMuted)

                            TextField("Airframe Name (e.g. Freefly Astro)", text: $customName)
                                .textFieldStyle(.plain)
                                .padding(DesignTokens.spaceS)
                                .background(DesignTokens.cardBackgroundSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                .foregroundStyle(DesignTokens.textPrimary)

                            HStack(spacing: DesignTokens.spaceS) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Weight (g)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(DesignTokens.textSecondary)
                                    TextField("Grams", text: $customWeight)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(.plain)
                                        .padding(DesignTokens.spaceS)
                                        .background(DesignTokens.cardBackgroundSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Max Wind (mph)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(DesignTokens.textSecondary)
                                    TextField("MPH", text: $customMaxWind)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(.plain)
                                        .padding(DesignTokens.spaceS)
                                        .background(DesignTokens.cardBackgroundSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                }
                            }

                            HStack(spacing: DesignTokens.spaceS) {
                                Button("Cancel") {
                                    withAnimation { isAddingCustom = false }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .foregroundStyle(DesignTokens.textSecondary)

                                Button("Save Airframe") {
                                    saveCustom()
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .background(DesignTokens.aeroBlue)
                                .foregroundStyle(.black)
                                .font(.system(size: 14, weight: .bold))
                                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.radiusS))
                                .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty)
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
                .padding(DesignTokens.spaceM)
            }
            .background(DesignTokens.canvasBackground.ignoresSafeArea())
            .navigationTitle("Select Airframe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DesignTokens.aeroBlue)
                }
            }
        }
    }

    private func saveCustom() {
        guard !customName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let profile = DroneProfile(
            name: customName,
            weightGrams: Double(customWeight) ?? 500,
            maxWindResistanceMph: Double(customMaxWind) ?? 25,
            maxOperatingTempC: Double(customMaxTemp) ?? 40,
            minOperatingTempC: Double(customMinTemp) ?? -10,
            category: customCategory
        )
        onAddCustom(profile)
        dismiss()
    }
}
