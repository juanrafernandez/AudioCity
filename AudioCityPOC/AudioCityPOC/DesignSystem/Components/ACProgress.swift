//
//  ACProgress.swift
//  AudioCityPOC
//
//  Componentes de progreso del sistema de diseño
//  Barras de progreso, indicadores circulares y steps
//

import SwiftUI

// MARK: - Linear Progress Bar

/// Barra de progreso lineal
struct ACProgressBar: View {
    let progress: Double  // 0.0 - 1.0
    let height: CGFloat
    let showLabel: Bool
    let color: Color
    let backgroundColor: Color

    init(
        progress: Double,
        height: CGFloat = 8,
        showLabel: Bool = false,
        color: Color = ACColors.primary,
        backgroundColor: Color = ACColors.borderLight
    ) {
        self.progress = min(max(progress, 0), 1)  // Clamp entre 0 y 1
        self.height = height
        self.showLabel = showLabel
        self.color = color
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: ACSpacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(backgroundColor)
                        .frame(height: height)

                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: height)
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

// MARK: - Circular Progress

/// Indicador de progreso circular
struct ACCircularProgress: View {
    let progress: Double  // 0.0 - 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    let showLabel: Bool
    let color: Color
    let backgroundColor: Color

    init(
        progress: Double,
        size: CGFloat = 60,
        lineWidth: CGFloat = 6,
        showLabel: Bool = true,
        color: Color = ACColors.primary,
        backgroundColor: Color = ACColors.borderLight
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.showLabel = showLabel
        self.color = color
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(ACAnimation.spring, value: progress)

            // Label
            if showLabel {
                Text("\(Int(progress * 100))%")
                    .font(size > 50 ? ACTypography.titleMedium : ACTypography.caption)
                    .foregroundColor(ACColors.textPrimary)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Progress with Icon

/// Progreso circular con icono en el centro
struct ACCircularProgressWithIcon: View {
    let progress: Double
    let icon: String
    let size: CGFloat
    let color: Color

    init(
        progress: Double,
        icon: String,
        size: CGFloat = 80,
        color: Color = ACColors.primary
    ) {
        self.progress = min(max(progress, 0), 1)
        self.icon = icon
        self.size = size
        self.color = color
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 8,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(ACAnimation.spring, value: progress)

            // Icon
            Image(systemName: icon)
                .font(.system(size: size * 0.35))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Steps Progress

/// Indicador de pasos/etapas
struct ACStepsProgress: View {
    let steps: [String]
    let currentStep: Int  // 0-based index
    let orientation: Orientation

    enum Orientation {
        case horizontal
        case vertical
    }

    init(
        steps: [String],
        currentStep: Int,
        orientation: Orientation = .horizontal
    ) {
        self.steps = steps
        self.currentStep = min(max(currentStep, 0), steps.count - 1)
        self.orientation = orientation
    }

    var body: some View {
        Group {
            if orientation == .horizontal {
                horizontalSteps
            } else {
                verticalSteps
            }
        }
    }

    private var horizontalSteps: some View {
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack(spacing: 0) {
                    // Step circle
                    stepCircle(index: index)

                    // Connector line (except last)
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? ACColors.primary : ACColors.borderLight)
                            .frame(height: 2)
                            .animation(ACAnimation.spring, value: currentStep)
                    }
                }
                .frame(maxWidth: index < steps.count - 1 ? .infinity : nil)
            }
        }
    }

    private var verticalSteps: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                HStack(alignment: .top, spacing: ACSpacing.md) {
                    VStack(spacing: 0) {
                        // Step circle
                        stepCircle(index: index)

                        // Connector line (except last)
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? ACColors.primary : ACColors.borderLight)
                                .frame(width: 2, height: 40)
                                .animation(ACAnimation.spring, value: currentStep)
                        }
                    }

                    // Step label
                    VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                        Text(steps[index])
                            .font(index == currentStep ? ACTypography.titleSmall : ACTypography.bodyMedium)
                            .foregroundColor(index <= currentStep ? ACColors.textPrimary : ACColors.textTertiary)

                        if index < currentStep {
                            Text("Completado")
                                .font(ACTypography.caption)
                                .foregroundColor(ACColors.success)
                        } else if index == currentStep {
                            Text("En progreso")
                                .font(ACTypography.caption)
                                .foregroundColor(ACColors.primary)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func stepCircle(index: Int) -> some View {
        ZStack {
            Circle()
                .fill(stepBackgroundColor(index: index))
                .frame(width: 32, height: 32)

            if index < currentStep {
                // Completed
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else {
                // Current or future
                Text("\(index + 1)")
                    .font(ACTypography.labelSmall)
                    .foregroundColor(index == currentStep ? .white : ACColors.textTertiary)
            }
        }
    }

    private func stepBackgroundColor(index: Int) -> Color {
        if index < currentStep {
            return ACColors.success
        } else if index == currentStep {
            return ACColors.primary
        } else {
            return ACColors.borderLight
        }
    }
}

// MARK: - Route Progress (Específico para rutas)

/// Progreso de ruta con paradas
struct ACRouteProgress: View {
    let totalStops: Int
    let visitedStops: Int
    let showLabel: Bool

    init(
        totalStops: Int,
        visitedStops: Int,
        showLabel: Bool = true
    ) {
        self.totalStops = max(totalStops, 1)
        self.visitedStops = min(max(visitedStops, 0), totalStops)
        self.showLabel = showLabel
    }

    private var progress: Double {
        Double(visitedStops) / Double(totalStops)
    }

    var body: some View {
        VStack(spacing: ACSpacing.sm) {
            // Progress bar with stops
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ACColors.borderLight)
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ACColors.primary)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(ACAnimation.spring, value: progress)

                    // Stop markers
                    HStack(spacing: 0) {
                        ForEach(0..<totalStops, id: \.self) { index in
                            Circle()
                                .fill(index < visitedStops ? ACColors.primary : ACColors.border)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(ACColors.surface, lineWidth: 2)
                                )

                            if index < totalStops - 1 {
                                Spacer()
                            }
                        }
                    }
                }
            }
            .frame(height: 12)

            if showLabel {
                HStack {
                    Text("\(visitedStops)/\(totalStops) paradas")
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)

                    Spacer()

                    Text("\(Int(progress * 100))%")
                        .font(ACTypography.labelSmall)
                        .foregroundColor(ACColors.primary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Progress Components") {
    ScrollView {
        VStack(spacing: ACSpacing.xxl) {
            // Linear Progress
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Linear Progress")
                    .font(ACTypography.headlineSmall)

                ACProgressBar(progress: 0.3)
                ACProgressBar(progress: 0.6, showLabel: true)
                ACProgressBar(progress: 0.9, color: ACColors.success)
            }
            .padding()

            SwiftUI.Divider()

            // Circular Progress
            VStack(spacing: ACSpacing.md) {
                Text("Circular Progress")
                    .font(ACTypography.headlineSmall)

                HStack(spacing: ACSpacing.xl) {
                    ACCircularProgress(progress: 0.25, size: 50)
                    ACCircularProgress(progress: 0.5, size: 60)
                    ACCircularProgress(progress: 0.75, size: 70, color: ACColors.success)
                }

                ACCircularProgressWithIcon(
                    progress: 0.65,
                    icon: "figure.walk",
                    size: 100
                )
            }
            .padding()

            SwiftUI.Divider()

            // Steps Progress
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Steps Progress")
                    .font(ACTypography.headlineSmall)

                ACStepsProgress(
                    steps: ["Destino", "Rutas", "Fechas", "Confirmar"],
                    currentStep: 1
                )
                .padding(.horizontal)

                ACStepsProgress(
                    steps: ["Seleccionar", "Configurar", "Completar"],
                    currentStep: 2,
                    orientation: .vertical
                )
            }
            .padding()

            SwiftUI.Divider()

            // Route Progress
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Route Progress")
                    .font(ACTypography.headlineSmall)

                ACRouteProgress(totalStops: 6, visitedStops: 2)
                ACRouteProgress(totalStops: 8, visitedStops: 5)
                ACRouteProgress(totalStops: 5, visitedStops: 5)
            }
            .padding()
        }
    }
    .background(ACColors.background)
}
