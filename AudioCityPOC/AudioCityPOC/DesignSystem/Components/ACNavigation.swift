//
//  ACNavigation.swift
//  AudioCityPOC
//
//  Componentes de navegación del sistema de diseño
//

import SwiftUI

// MARK: - Section Header

struct ACSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionTitle: String = "Ver todo"

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                Text(title)
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textSecondary)
                }
            }

            Spacer()

            if let action = action {
                Button(action: action) {
                    HStack(spacing: ACSpacing.xs) {
                        Text(actionTitle)
                            .font(ACTypography.labelMedium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(ACColors.primary)
                }
            }
        }
    }
}

// MARK: - Tab Bar Item

struct ACTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: ACSpacing.xxs) {
            Image(systemName: isSelected ? icon + ".fill" : icon)
                .font(.system(size: 22))
                .foregroundColor(isSelected ? ACColors.primary : ACColors.textTertiary)

            Text(title)
                .font(ACTypography.captionSmall)
                .foregroundColor(isSelected ? ACColors.primary : ACColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Tab Bar

struct ACTabBar: View {
    @Binding var selectedIndex: Int
    let items: [(icon: String, title: String)]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                Button(action: { selectedIndex = index }) {
                    ACTabItem(
                        icon: items[index].icon,
                        title: items[index].title,
                        isSelected: selectedIndex == index
                    )
                }
            }
        }
        .padding(.top, ACSpacing.sm)
        .padding(.bottom, ACSpacing.xs)
        .background(
            ACColors.surface
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: -4)
        )
    }
}

// MARK: - Navigation Bar

struct ACNavigationBar: View {
    let title: String
    var subtitle: String? = nil
    var leadingAction: (() -> Void)? = nil
    var leadingIcon: String = "chevron.left"
    var trailingActions: [(icon: String, action: () -> Void)] = []

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            // Leading button
            if let leadingAction = leadingAction {
                Button(action: leadingAction) {
                    Image(systemName: leadingIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ACColors.textPrimary)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }

            Spacer()

            // Title
            VStack(spacing: 0) {
                Text(title)
                    .font(ACTypography.titleMedium)
                    .foregroundColor(ACColors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)
                }
            }

            Spacer()

            // Trailing actions
            if trailingActions.isEmpty {
                Spacer()
                    .frame(width: 44)
            } else {
                HStack(spacing: ACSpacing.xs) {
                    ForEach(trailingActions.indices, id: \.self) { index in
                        Button(action: trailingActions[index].action) {
                            Image(systemName: trailingActions[index].icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(ACColors.textPrimary)
                                .frame(width: 44, height: 44)
                        }
                    }
                }
            }
        }
        .frame(height: 56)
        .padding(.horizontal, ACSpacing.sm)
        .background(ACColors.surface)
    }
}

// MARK: - Segmented Control

struct ACSegmentedControl: View {
    @Binding var selectedIndex: Int
    let segments: [String]

    var body: some View {
        HStack(spacing: ACSpacing.xs) {
            ForEach(segments.indices, id: \.self) { index in
                Button(action: { selectedIndex = index }) {
                    Text(segments[index])
                        .font(ACTypography.labelMedium)
                        .foregroundColor(selectedIndex == index ? ACColors.textInverted : ACColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, ACSpacing.sm)
                        .background(
                            selectedIndex == index
                                ? ACColors.primary
                                : Color.clear
                        )
                        .cornerRadius(ACRadius.sm)
                }
            }
        }
        .padding(ACSpacing.xs)
        .background(ACColors.borderLight)
        .cornerRadius(ACRadius.md)
        .animation(ACAnimation.spring, value: selectedIndex)
    }
}

// MARK: - Breadcrumb

struct ACBreadcrumb: View {
    let items: [String]

    var body: some View {
        HStack(spacing: ACSpacing.xs) {
            ForEach(items.indices, id: \.self) { index in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(ACColors.textTertiary)
                }

                Text(items[index])
                    .font(ACTypography.caption)
                    .foregroundColor(
                        index == items.count - 1
                            ? ACColors.textPrimary
                            : ACColors.textSecondary
                    )
            }
        }
    }
}

// MARK: - Progress Indicator

struct ACProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var backgroundColor: Color = ACColors.borderLight
    var foregroundColor: Color = ACColors.primary
    var showLabel: Bool = false

    var body: some View {
        VStack(alignment: .trailing, spacing: ACSpacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(foregroundColor)
                        .frame(width: max(0, geometry.size.width * min(1, progress)), height: height)
                        .animation(ACAnimation.spring, value: progress)
                }
            }
            .frame(height: height)

            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textSecondary)
            }
        }
    }
}

// MARK: - Step Indicator

struct ACStepIndicator: View {
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        HStack(spacing: ACSpacing.sm) {
            ForEach(1...totalSteps, id: \.self) { step in
                if step > 1 {
                    Rectangle()
                        .fill(step <= currentStep ? ACColors.primary : ACColors.border)
                        .frame(height: 2)
                }

                ZStack {
                    Circle()
                        .fill(step <= currentStep ? ACColors.primary : ACColors.surface)
                        .frame(width: 28, height: 28)

                    Circle()
                        .stroke(step <= currentStep ? ACColors.primary : ACColors.border, lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if step < currentStep {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(ACColors.textInverted)
                    } else {
                        Text("\(step)")
                            .font(ACTypography.labelSmall)
                            .foregroundColor(step == currentStep ? ACColors.textInverted : ACColors.textSecondary)
                    }
                }
            }
        }
        .animation(ACAnimation.spring, value: currentStep)
    }
}

// MARK: - Preview

#Preview("Navigation") {
    VStack(spacing: ACSpacing.xl) {
        // Navigation bar
        ACNavigationBar(
            title: "Detalle de Ruta",
            subtitle: "Madrid",
            leadingAction: {},
            trailingActions: [
                (icon: "heart", action: {}),
                (icon: "square.and.arrow.up", action: {})
            ]
        )

        // Section headers
        VStack(spacing: ACSpacing.md) {
            ACSectionHeader(title: "Top Rutas", action: {})
            ACSectionHeader(
                title: "Mis Viajes",
                subtitle: "2 de 5 viajes",
                action: {}
            )
        }
        .padding(.horizontal)

        // Segmented control
        ACSegmentedControl(
            selectedIndex: .constant(0),
            segments: ["Todos", "Activos", "Completados"]
        )
        .padding(.horizontal)

        // Breadcrumb
        ACBreadcrumb(items: ["Inicio", "Madrid", "Barrio de las Letras"])
            .padding(.horizontal)

        // Progress bar
        VStack(spacing: ACSpacing.md) {
            ACProgressBar(progress: 0.65, showLabel: true)
            ACProgressBar(progress: 0.3, foregroundColor: ACColors.secondary)
        }
        .padding(.horizontal)

        // Step indicator
        ACStepIndicator(totalSteps: 4, currentStep: 2)
            .padding(.horizontal)

        // Tab bar
        Spacer()
        ACTabBar(
            selectedIndex: .constant(0),
            items: [
                (icon: "map", title: "Explorar"),
                (icon: "list.bullet", title: "Rutas"),
                (icon: "pencil", title: "Mis Rutas"),
                (icon: "clock", title: "Historial"),
                (icon: "person", title: "Perfil")
            ]
        )
    }
    .background(ACColors.background)
}
