//
//  ACInput.swift
//  AudioCityPOC
//
//  Componentes de entrada del sistema de diseño
//

import SwiftUI

// MARK: - Text Field

struct ACTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String? = nil
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isError: Bool = false
    var errorMessage: String? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.xs) {
            HStack(spacing: ACSpacing.sm) {
                // Icono opcional
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                        .frame(width: 24)
                }

                // Campo de texto
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .keyboardType(keyboardType)
                            .textInputAutocapitalization(autocapitalization)
                    }
                }
                .font(ACTypography.bodyLarge)
                .foregroundColor(ACColors.textPrimary)
                .focused($isFocused)

                // Clear button
                if !text.isEmpty && isFocused {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ACColors.textTertiary)
                    }
                }
            }
            .padding(ACSpacing.md)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: ACRadius.md)
                    .stroke(borderColor, lineWidth: isFocused ? ACBorder.thick : ACBorder.thin)
            )

            // Mensaje de error
            if let errorMessage = errorMessage, isError {
                HStack(spacing: ACSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 12))
                    Text(errorMessage)
                        .font(ACTypography.caption)
                }
                .foregroundColor(ACColors.error)
            }
        }
        .animation(ACAnimation.easeOut, value: isFocused)
        .animation(ACAnimation.easeOut, value: isError)
    }

    private var borderColor: Color {
        if isError {
            return ACColors.error
        } else if isFocused {
            return ACColors.primary
        } else {
            return ACColors.border
        }
    }

    private var iconColor: Color {
        if isError {
            return ACColors.error
        } else if isFocused {
            return ACColors.primary
        } else {
            return ACColors.textTertiary
        }
    }
}

// MARK: - Search Field

struct ACSearchField: View {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: ACSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(isFocused ? ACColors.primary : ACColors.textTertiary)

            TextField(placeholder, text: $text)
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textPrimary)
                .focused($isFocused)
                .onSubmit { onSubmit?() }

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ACColors.textTertiary)
                }
            }
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.full)
        .overlay(
            RoundedRectangle(cornerRadius: ACRadius.full)
                .stroke(isFocused ? ACColors.primary : ACColors.border, lineWidth: isFocused ? ACBorder.thick : ACBorder.thin)
        )
        .animation(ACAnimation.easeOut, value: isFocused)
    }
}

// MARK: - Text Area

struct ACTextArea: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    var maxHeight: CGFloat = 200

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .font(ACTypography.bodyLarge)
                    .foregroundColor(ACColors.textTertiary)
                    .padding(.horizontal, ACSpacing.md + 4)
                    .padding(.vertical, ACSpacing.md + 8)
            }

            // Text editor
            TextEditor(text: $text)
                .font(ACTypography.bodyLarge)
                .foregroundColor(ACColors.textPrimary)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                .padding(ACSpacing.sm)
        }
        .background(ACColors.surface)
        .cornerRadius(ACRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ACRadius.md)
                .stroke(isFocused ? ACColors.primary : ACColors.border, lineWidth: isFocused ? 2 : 1)
        )
        .animation(ACAnimation.easeOut, value: isFocused)
    }
}

// MARK: - Selection Chip

struct ACChip: View {
    let text: String
    let isSelected: Bool
    var icon: String? = nil
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                }
                Text(text)
                    .font(ACTypography.labelSmall)
            }
            .foregroundColor(isSelected ? ACColors.textInverted : ACColors.textPrimary)
            .padding(.horizontal, ACSpacing.md)
            .padding(.vertical, ACSpacing.sm)
            .background(isSelected ? ACColors.primary : ACColors.surface)
            .cornerRadius(ACRadius.full)
            .overlay(
                RoundedRectangle(cornerRadius: ACRadius.full)
                    .stroke(isSelected ? Color.clear : ACColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(ACAnimation.spring, value: isSelected)
    }
}

// MARK: - Toggle

struct ACToggle: View {
    let title: String
    @Binding var isOn: Bool
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                Text(title)
                    .font(ACTypography.bodyLarge)
                    .foregroundColor(ACColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textSecondary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(ACColors.primary)
                .labelsHidden()
        }
    }
}

// MARK: - Stepper

struct ACStepper: View {
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...100
    var step: Int = 1

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            Text(title)
                .font(ACTypography.bodyLarge)
                .foregroundColor(ACColors.textPrimary)

            Spacer()

            HStack(spacing: ACSpacing.sm) {
                Button(action: { decrease() }) {
                    Image(systemName: "minus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(canDecrease ? ACColors.primary : ACColors.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(canDecrease ? ACColors.primaryLight : ACColors.borderLight)
                        .cornerRadius(ACRadius.sm)
                }
                .disabled(!canDecrease)

                Text("\(value)")
                    .font(ACTypography.numberMedium)
                    .foregroundColor(ACColors.textPrimary)
                    .frame(minWidth: 40)

                Button(action: { increase() }) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(canIncrease ? ACColors.primary : ACColors.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(canIncrease ? ACColors.primaryLight : ACColors.borderLight)
                        .cornerRadius(ACRadius.sm)
                }
                .disabled(!canIncrease)
            }
        }
    }

    private var canDecrease: Bool { value > range.lowerBound }
    private var canIncrease: Bool { value < range.upperBound }

    private func decrease() {
        let newValue = value - step
        if newValue >= range.lowerBound {
            value = newValue
        }
    }

    private func increase() {
        let newValue = value + step
        if newValue <= range.upperBound {
            value = newValue
        }
    }
}

// MARK: - Preview

#Preview("Inputs") {
    ScrollView {
        VStack(spacing: ACSpacing.xl) {
            // Text field
            VStack(alignment: .leading, spacing: ACSpacing.sm) {
                Text("Text Field")
                    .font(ACTypography.labelMedium)
                ACTextField(
                    placeholder: "Nombre de la ruta",
                    text: .constant(""),
                    icon: "map"
                )
                ACTextField(
                    placeholder: "Con error",
                    text: .constant("Texto inválido"),
                    icon: "exclamationmark.triangle",
                    isError: true,
                    errorMessage: "Este campo es requerido"
                )
            }

            // Search
            VStack(alignment: .leading, spacing: ACSpacing.sm) {
                Text("Search")
                    .font(ACTypography.labelMedium)
                ACSearchField(
                    placeholder: "Buscar rutas...",
                    text: .constant("")
                )
            }

            // Text area
            VStack(alignment: .leading, spacing: ACSpacing.sm) {
                Text("Text Area")
                    .font(ACTypography.labelMedium)
                ACTextArea(
                    placeholder: "Escribe una descripción...",
                    text: .constant("")
                )
            }

            // Chips
            VStack(alignment: .leading, spacing: ACSpacing.sm) {
                Text("Chips")
                    .font(ACTypography.labelMedium)
                HStack(spacing: ACSpacing.sm) {
                    ACChip(text: "Madrid", isSelected: true, icon: "mappin") {}
                    ACChip(text: "Zamora", isSelected: false) {}
                    ACChip(text: "Valladolid", isSelected: false) {}
                }
            }

            // Toggle
            VStack(alignment: .leading, spacing: ACSpacing.sm) {
                Text("Toggle")
                    .font(ACTypography.labelMedium)
                ACToggle(
                    title: "Descarga offline",
                    isOn: .constant(true),
                    subtitle: "Disponible sin conexión"
                )
            }

            // Stepper
            VStack(alignment: .leading, spacing: ACSpacing.sm) {
                Text("Stepper")
                    .font(ACTypography.labelMedium)
                ACStepper(
                    title: "Número de paradas",
                    value: .constant(5),
                    range: 1...20
                )
            }
        }
        .padding()
    }
    .background(ACColors.background)
}
