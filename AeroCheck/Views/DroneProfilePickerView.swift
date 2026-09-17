//
//  DroneProfilePickerView.swift
//  AeroCheck
//
//  Created by Vedansh Kumar on 9/16/26.
//

import SwiftUI

/// Drone profile selection and custom airframe modal conforming to Apple HIG:
/// - Semantic typography (Headline, Subheadline, Caption)
/// - Flat card surfaces with hairline borders
/// - 44x44pt minimum touch targets with active press feedback
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
                VStack(spacing: DesignTokens.space16) {
                    // Profile List
                    VStack(spacing: DesignTokens.space8) {
                        ForEach(profiles) { profile in
                            Button {
                                onSelect(profile)
                                dismiss()
                            } label: {
                                HStack(spacing: DesignTokens.space12) {
                                    ZStack {
                                        Circle()
                                            .fill(profile.id == selectedProfile.id ? DesignTokens.accentMuted : DesignTokens.surfaceTertiary)
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "airplane")
                                            .font(.footnote.weight(.semibold))
                                            .foregroundStyle(profile.id == selectedProfile.id ? DesignTokens.accent : DesignTokens.textSecondary)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack {
                                            Text(profile.name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(DesignTokens.textPrimary)

                                            Spacer()

                                            if profile.id == selectedProfile.id {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.subheadline)
                                                    .foregroundStyle(DesignTokens.statusSafe)
                                            }
                                        }

                                        HStack(spacing: DesignTokens.space8) {
                                            Text("\(Int(profile.weightGrams))g")
                                                .font(.caption.monospaced())
                                                .foregroundStyle(DesignTokens.textTertiary)

                                            Text("•")
                                                .foregroundStyle(DesignTokens.textTertiary)

                                            Text("Max Wind: \(Int(profile.maxWindResistanceMph)) mph")
                                                .font(.caption)
                                                .foregroundStyle(DesignTokens.textSecondary)

                                            Text("•")
                                                .foregroundStyle(DesignTokens.textTertiary)

                                            Text(profile.category)
                                                .font(.caption)
                                                .foregroundStyle(DesignTokens.textTertiary)
                                        }
                                    }
                                }
                                .padding(DesignTokens.space16)
                                .frame(minHeight: 52)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                        .fill(DesignTokens.surfaceSecondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.radiusCard, style: .continuous)
                                                .stroke(profile.id == selectedProfile.id ? DesignTokens.accent : DesignTokens.borderHairline, lineWidth: 1)
                                        )
                                )
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.interactivePress)
                        }
                    }

                    // Add Custom Button / Form
                    if !isAddingCustom {
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                isAddingCustom = true
                            }
                        } label: {
                            HStack(spacing: DesignTokens.space8) {
                                Image(systemName: "plus.circle")
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
                                            .stroke(DesignTokens.borderHairline, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.interactivePress)
                    } else {
                        // Custom Airframe Form
                        VStack(alignment: .leading, spacing: DesignTokens.space12) {
                            Text("CUSTOM AIRFRAME SPECIFICATIONS")
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
                                        .stroke(DesignTokens.borderHairline, lineWidth: 1)
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
