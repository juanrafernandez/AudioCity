//
//  ACCitySearchField.swift
//  AudioCityPOC
//
//  Campo de autocompletado para selección de ciudad
//

import SwiftUI

// MARK: - City Search Field

/// Campo de búsqueda de ciudad con autocompletado
struct ACCitySearchField: View {
    @Binding var selectedCity: String
    let availableCities: [String]
    let nearestCity: String?
    let onCitySelected: (String) -> Void

    @State private var isEditing: Bool = false
    @State private var searchText: String = ""

    /// Máximo de sugerencias visibles
    private let maxVisibleSuggestions = 5

    /// Ciudad efectiva (seleccionada o cercana)
    private var effectiveCity: String {
        if !selectedCity.isEmpty {
            return selectedCity
        }
        return nearestCity ?? ""
    }

    /// Sugerencias filtradas
    private var suggestions: [String] {
        let filtered = searchText.isEmpty
            ? availableCities
            : availableCities.filter { $0.localizedCaseInsensitiveContains(searchText) }
        return Array(filtered.prefix(maxVisibleSuggestions))
    }

    /// Sugerencias restantes
    private var remainingCount: Int {
        let total = searchText.isEmpty
            ? availableCities.count
            : availableCities.filter { $0.localizedCaseInsensitiveContains(searchText) }.count
        return max(0, total - maxVisibleSuggestions)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Label
            Text("¿Qué ciudad quieres explorar?")
                .font(ACTypography.headlineMedium)
                .foregroundColor(ACColors.textPrimary)

            // Campo principal
            VStack(spacing: 0) {
                mainField

                // Sugerencias (solo cuando está editando)
                if isEditing {
                    suggestionsView
                }
            }
        }
    }

    // MARK: - Main Field

    private var mainField: some View {
        HStack(spacing: ACSpacing.sm) {
            if isEditing {
                // Modo edición: TextField
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(ACColors.primary)

                TextField("Buscar ciudad...", text: $searchText)
                    .font(ACTypography.bodyMedium)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                Button(action: cancelEditing) {
                    Text("Cancelar")
                        .font(ACTypography.labelSmall)
                        .foregroundColor(ACColors.primary)
                }
            } else {
                // Modo normal: muestra ciudad seleccionada
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ACColors.primary)

                Text(effectiveCity.isEmpty ? "Selecciona una ciudad" : effectiveCity)
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(effectiveCity.isEmpty ? ACColors.textTertiary : ACColors.textPrimary)

                Spacer()

                // Badge ciudad cercana
                if let nearest = nearestCity, effectiveCity == nearest {
                    HStack(spacing: ACSpacing.xxs) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 10))
                        Text("Cerca")
                            .font(ACTypography.captionSmall)
                    }
                    .foregroundColor(ACColors.success)
                    .padding(.horizontal, ACSpacing.sm)
                    .padding(.vertical, ACSpacing.xxs)
                    .background(ACColors.successLight)
                    .cornerRadius(ACRadius.full)
                }

                // Botón volver a cercana (si hay otra seleccionada)
                if let nearest = nearestCity, !selectedCity.isEmpty, selectedCity != nearest {
                    Button(action: { selectCity(nearest) }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ACColors.primary)
                    }
                }

                // Botón editar
                Button(action: startEditing) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ACColors.textTertiary)
                }
            }
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: ACRadius.lg)
                .stroke(
                    isEditing ? ACColors.primary : ACColors.border,
                    lineWidth: isEditing ? ACBorder.thick : ACBorder.thin
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing {
                startEditing()
            }
        }
    }

    // MARK: - Suggestions View

    private var suggestionsView: some View {
        VStack(spacing: 0) {
            ForEach(suggestions, id: \.self) { city in
                VStack(spacing: 0) {
                    HStack(spacing: ACSpacing.md) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 14))
                            .foregroundColor(ACColors.textTertiary)

                        Text(city)
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textPrimary)

                        Spacer()

                        if city == nearestCity {
                            Text("Más cercana")
                                .font(ACTypography.captionSmall)
                                .foregroundColor(ACColors.success)
                        }

                        if city == effectiveCity {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ACColors.primary)
                        }
                    }
                    .padding(.horizontal, ACSpacing.md)
                    .padding(.vertical, ACSpacing.sm)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectCity(city)
                    }

                    if city != suggestions.last {
                        Divider()
                            .padding(.leading, ACSpacing.xl)
                    }
                }
            }

            // Indicador de más resultados
            if remainingCount > 0 {
                Divider()
                    .padding(.leading, ACSpacing.xl)

                HStack {
                    Text("y \(remainingCount) más...")
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textTertiary)
                        .italic()
                    Spacer()
                }
                .padding(.horizontal, ACSpacing.md)
                .padding(.vertical, ACSpacing.sm)
            }

            // Sin resultados
            if suggestions.isEmpty {
                HStack {
                    Text("No hay ciudades que coincidan")
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textTertiary)
                    Spacer()
                }
                .padding(.horizontal, ACSpacing.md)
                .padding(.vertical, ACSpacing.sm)
            }
        }
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.lg)
        .padding(.top, ACSpacing.xxs)
    }

    // MARK: - Actions

    private func startEditing() {
        withAnimation(ACAnimation.spring) {
            isEditing = true
            searchText = ""
        }
    }

    private func cancelEditing() {
        withAnimation(ACAnimation.spring) {
            isEditing = false
            searchText = ""
        }
    }

    private func selectCity(_ city: String) {
        withAnimation(ACAnimation.spring) {
            selectedCity = city
            isEditing = false
            searchText = ""
        }
        onCitySelected(city)
    }
}

// MARK: - Preview

#Preview("City Search Field") {
    VStack(spacing: ACSpacing.xl) {
        // Estado inicial - ciudad detectada
        ACCitySearchField(
            selectedCity: .constant(""),
            availableCities: ["Madrid", "Valladolid", "Zamora", "Barcelona", "Sevilla"],
            nearestCity: "Madrid"
        ) { city in
            print("Selected: \(city)")
        }

        // Con ciudad seleccionada
        ACCitySearchField(
            selectedCity: .constant("Valladolid"),
            availableCities: ["Madrid", "Valladolid", "Zamora", "Barcelona", "Sevilla"],
            nearestCity: "Madrid"
        ) { city in
            print("Selected: \(city)")
        }

        // Sin ciudad cercana detectada
        ACCitySearchField(
            selectedCity: .constant(""),
            availableCities: ["Madrid", "Valladolid", "Zamora"],
            nearestCity: nil
        ) { city in
            print("Selected: \(city)")
        }

        Spacer()
    }
    .padding()
    .background(ACColors.background)
}
