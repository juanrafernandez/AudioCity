//
//  ACMap.swift
//  AudioCityPOC
//
//  Componentes de mapa del sistema de diseño
//

import SwiftUI
import MapKit

// MARK: - Custom Map Marker

struct ACMapPin: View {
    enum PinState {
        case normal
        case selected
        case visited
        case upcoming

        var color: Color {
            switch self {
            case .normal: return ACColors.primary
            case .selected: return ACColors.info
            case .visited: return ACColors.success
            case .upcoming: return ACColors.warning
            }
        }

        var icon: String {
            switch self {
            case .normal: return "headphones"
            case .selected: return "headphones"
            case .visited: return "checkmark"
            case .upcoming: return "arrow.right"
            }
        }
    }

    let state: PinState
    let number: Int?

    init(state: PinState = .normal, number: Int? = nil) {
        self.state = state
        self.number = number
    }

    var body: some View {
        VStack(spacing: 0) {
            // Pin head
            ZStack {
                // Outer glow for selected
                if state == .selected {
                    Circle()
                        .fill(state.color.opacity(0.3))
                        .frame(width: 52, height: 52)
                }

                // Main circle
                Circle()
                    .fill(state.color)
                    .frame(width: 40, height: 40)
                    .shadow(color: state.color.opacity(0.4), radius: 4, y: 2)

                // Inner content
                if let number = number {
                    Text("\(number)")
                        .font(ACTypography.labelMedium)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                } else {
                    Image(systemName: state.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            // Pin tail
            Triangle()
                .fill(state.color)
                .frame(width: 16, height: 10)
                .offset(y: -2)
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Map Info Card (Floating)

struct ACMapInfoCard: View {
    let title: String
    let subtitle: String
    let distance: String?
    let duration: String?
    var onTap: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: ACSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(ACColors.primaryLight)
                        .frame(width: 48, height: 48)

                    Image(systemName: "headphones")
                        .font(.system(size: 20))
                        .foregroundColor(ACColors.primary)
                }

                // Content
                VStack(alignment: .leading, spacing: ACSpacing.xs) {
                    Text(title)
                        .font(ACTypography.titleMedium)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textSecondary)

                    if distance != nil || duration != nil {
                        HStack(spacing: ACSpacing.md) {
                            if let distance = distance {
                                ACMetaBadge(icon: "figure.walk", text: distance)
                            }
                            if let duration = duration {
                                ACMetaBadge(icon: "clock", text: duration)
                            }
                        }
                        .padding(.top, ACSpacing.xxs)
                    }
                }

                Spacer(minLength: 0)

                // Close button
                if let onClose = onClose {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ACColors.textTertiary)
                            .frame(width: 28, height: 28)
                            .background(ACColors.borderLight)
                            .cornerRadius(14)
                    }
                }
            }

            // Action button
            if let onTap = onTap {
                Button(action: onTap) {
                    HStack {
                        Text("Ver detalles")
                            .font(ACTypography.labelMedium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(ACColors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ACSpacing.sm)
                    .background(ACColors.primaryLight)
                    .cornerRadius(ACRadius.sm)
                }
                .padding(.top, ACSpacing.md)
            }
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.xl)
        .acShadow(ACShadow.lg)
    }
}

// MARK: - Route Path Indicator

struct ACRoutePathIndicator: View {
    let stops: Int
    let currentStop: Int
    let isActive: Bool

    var body: some View {
        HStack(spacing: ACSpacing.xs) {
            ForEach(0..<stops, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(index <= currentStop ? ACColors.primary : ACColors.border)
                        .frame(height: 3)
                }

                Circle()
                    .fill(dotColor(for: index))
                    .frame(width: dotSize(for: index), height: dotSize(for: index))
                    .overlay {
                        if index < currentStop {
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                        } else if index == currentStop && isActive {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                        }
                    }
            }
        }
        .animation(ACAnimation.spring, value: currentStop)
    }

    private func dotColor(for index: Int) -> Color {
        if index < currentStop {
            return ACColors.success
        } else if index == currentStop {
            return isActive ? ACColors.primary : ACColors.warning
        } else {
            return ACColors.border
        }
    }

    private func dotSize(for index: Int) -> CGFloat {
        index == currentStop ? 20 : 14
    }
}

// MARK: - Location Permission Card

struct ACLocationPermissionCard: View {
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: ACSpacing.lg) {
            ZStack {
                Circle()
                    .fill(ACColors.primaryLight)
                    .frame(width: 80, height: 80)

                Image(systemName: "location.fill")
                    .font(.system(size: 32))
                    .foregroundColor(ACColors.primary)
            }

            VStack(spacing: ACSpacing.sm) {
                Text("Activa tu ubicación")
                    .font(ACTypography.headlineSmall)
                    .foregroundColor(ACColors.textPrimary)

                Text("Necesitamos tu ubicación para reproducir el audio automáticamente cuando llegues a cada punto de interés.")
                    .font(ACTypography.bodySmall)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            ACButton("Activar ubicación", icon: "location.fill", style: .primary, isFullWidth: true, action: onRequestPermission)
        }
        .padding(ACSpacing.xl)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.xl)
        .acShadow(ACShadow.md)
    }
}

// MARK: - Now Playing Card (Para mapa activo)

struct ACNowPlayingCard: View {
    let stopName: String
    let stopNumber: Int
    let totalStops: Int
    let isPlaying: Bool
    let progress: Double
    var onPlayPause: () -> Void
    var onNext: () -> Void
    var onPrevious: () -> Void

    var body: some View {
        VStack(spacing: ACSpacing.md) {
            // Progress
            ACProgressBar(progress: progress, height: 4, foregroundColor: ACColors.primary)

            HStack(spacing: ACSpacing.md) {
                // Stop info
                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text("Parada \(stopNumber) de \(totalStops)")
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textTertiary)

                    Text(stopName)
                        .font(ACTypography.titleMedium)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(1)
                }

                Spacer()

                // Controls
                HStack(spacing: ACSpacing.sm) {
                    Button(action: onPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ACColors.textSecondary)
                            .frame(width: 40, height: 40)
                    }
                    .disabled(stopNumber <= 1)

                    Button(action: onPlayPause) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 48, height: 48)
                            .background(ACColors.primary)
                            .cornerRadius(24)
                    }

                    Button(action: onNext) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ACColors.textSecondary)
                            .frame(width: 40, height: 40)
                    }
                    .disabled(stopNumber >= totalStops)
                }
            }
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.xl)
        .acShadow(ACShadow.lg)
    }
}

// MARK: - Preview

#Preview("Map Components") {
    ScrollView {
        VStack(spacing: ACSpacing.xxl) {
            // Pins
            Text("Map Pins")
                .font(ACTypography.headlineSmall)

            HStack(spacing: ACSpacing.xxl) {
                VStack {
                    ACMapPin(state: .normal)
                    Text("Normal").font(ACTypography.caption)
                }
                VStack {
                    ACMapPin(state: .selected)
                    Text("Selected").font(ACTypography.caption)
                }
                VStack {
                    ACMapPin(state: .visited)
                    Text("Visited").font(ACTypography.caption)
                }
                VStack {
                    ACMapPin(state: .normal, number: 3)
                    Text("Numbered").font(ACTypography.caption)
                }
            }

            Divider()

            // Info Card
            Text("Map Info Card")
                .font(ACTypography.headlineSmall)

            ACMapInfoCard(
                title: "Puerta del Sol",
                subtitle: "El kilómetro cero de las carreteras radiales",
                distance: "150m",
                duration: "2 min",
                onTap: {},
                onClose: {}
            )
            .padding(.horizontal)

            Divider()

            // Route Path
            Text("Route Progress")
                .font(ACTypography.headlineSmall)

            ACRoutePathIndicator(stops: 6, currentStop: 2, isActive: true)
                .padding(.horizontal, ACSpacing.xl)

            Divider()

            // Now Playing
            Text("Now Playing")
                .font(ACTypography.headlineSmall)

            ACNowPlayingCard(
                stopName: "Museo del Prado",
                stopNumber: 3,
                totalStops: 8,
                isPlaying: true,
                progress: 0.45,
                onPlayPause: {},
                onNext: {},
                onPrevious: {}
            )
            .padding(.horizontal)

            Divider()

            // Location Permission
            Text("Location Permission")
                .font(ACTypography.headlineSmall)

            ACLocationPermissionCard(onRequestPermission: {})
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
    .background(ACColors.background)
}
