//
//  ACCard.swift
//  AudioCityPOC
//
//  Componentes de tarjeta del sistema de diseño
//  Inspirado en Transit: ETA cards horizontales, información densa pero legible
//

import SwiftUI

// MARK: - Route Card (Estilo horizontal como Transit)

struct ACRouteCard: View {
    let title: String
    let subtitle: String
    let duration: String
    let distance: String
    let stopsCount: Int
    let imageUrl: String?
    let isFavorite: Bool
    let onTap: () -> Void
    let onFavorite: () -> Void

    init(
        title: String,
        subtitle: String,
        duration: String,
        distance: String,
        stopsCount: Int,
        imageUrl: String? = nil,
        isFavorite: Bool = false,
        onTap: @escaping () -> Void,
        onFavorite: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.duration = duration
        self.distance = distance
        self.stopsCount = stopsCount
        self.imageUrl = imageUrl
        self.isFavorite = isFavorite
        self.onTap = onTap
        self.onFavorite = onFavorite
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.md) {
                // Imagen o placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: ACRadius.md)
                        .fill(ACColors.primaryLight)
                        .frame(width: 80, height: 80)

                    Image(systemName: "map.fill")
                        .font(.system(size: 28))
                        .foregroundColor(ACColors.primary.opacity(0.6))
                }

                // Contenido
                VStack(alignment: .leading, spacing: ACSpacing.xs) {
                    // Título
                    Text(title)
                        .font(ACTypography.titleMedium)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Subtítulo (ciudad/barrio)
                    Text(subtitle)
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textSecondary)

                    Spacer(minLength: ACSpacing.xs)

                    // Metadatos
                    HStack(spacing: ACSpacing.md) {
                        ACMetaBadge(icon: "clock", text: duration)
                        ACMetaBadge(icon: "figure.walk", text: distance)
                        ACMetaBadge(icon: "mappin", text: "\(stopsCount)")
                    }
                }

                Spacer(minLength: 0)

                // Botón favorito
                Button(action: onFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorite ? ACColors.primary : ACColors.textTertiary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(ACSpacing.cardPadding)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .acShadow(ACShadow.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Route Card (Para carruseles)

struct ACCompactRouteCard: View {
    let title: String
    let subtitle: String
    let duration: String
    let stopsCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: ACSpacing.sm) {
                // Header con imagen
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: ACRadius.md)
                        .fill(
                            LinearGradient(
                                colors: [ACColors.primary.opacity(0.8), ACColors.primaryDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)

                    // Icono decorativo
                    Image(systemName: "headphones")
                        .font(.system(size: 40))
                        .foregroundColor(Color.white.opacity(0.3))
                        .offset(x: 100, y: -20)

                    // Badge de paradas
                    HStack(spacing: ACSpacing.xs) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 12))
                        Text("\(stopsCount) paradas")
                            .font(ACTypography.captionSmall)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, ACSpacing.sm)
                    .padding(.vertical, ACSpacing.xs)
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(ACRadius.sm)
                    .padding(ACSpacing.sm)
                }

                // Info
                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text(title)
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(2)
                        .frame(height: 40, alignment: .topLeading)

                    HStack(spacing: ACSpacing.sm) {
                        Text(subtitle)
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textSecondary)

                        Spacer()

                        Text(duration)
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textTertiary)
                    }
                }
                .padding(.horizontal, ACSpacing.xs)
                .padding(.bottom, ACSpacing.xs)
            }
            .frame(width: 180)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .acShadow(ACShadow.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ETA Card (Estilo Transit - Para tiempo/distancia)

struct ACETACard: View {
    let value: String
    let unit: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: ACSpacing.xs) {
            // Icono
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            // Valor grande
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(ACTypography.numberLarge)
                    .foregroundColor(ACColors.textPrimary)

                Text(unit)
                    .font(ACTypography.bodySmall)
                    .foregroundColor(ACColors.textSecondary)
            }

            // Label
            Text(label)
                .font(ACTypography.caption)
                .foregroundColor(ACColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(ACSpacing.base)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }
}

// MARK: - Info Card

struct ACInfoCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color

    init(
        icon: String,
        title: String,
        description: String,
        accentColor: Color = ACColors.primary
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
    }

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            // Icono con fondo
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(accentColor)
            }

            // Texto
            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                Text(title)
                    .font(ACTypography.titleSmall)
                    .foregroundColor(ACColors.textPrimary)

                Text(description)
                    .font(ACTypography.bodySmall)
                    .foregroundColor(ACColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }
}

// MARK: - Meta Badge (Para metadatos)

struct ACMetaBadge: View {
    let icon: String
    let text: String
    var color: Color = ACColors.textSecondary

    var body: some View {
        HStack(spacing: ACSpacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(ACTypography.caption)
        }
        .foregroundColor(color)
    }
}

// MARK: - Status Badge

struct ACStatusBadge: View {
    enum BadgeStatus {
        case active
        case completed
        case draft
        case warning
        case error
        case inactive
        case pending

        var color: Color {
            switch self {
            case .active: return ACColors.success
            case .completed: return ACColors.info
            case .draft: return ACColors.warning
            case .warning: return ACColors.warning
            case .error: return ACColors.error
            case .inactive: return ACColors.textTertiary
            case .pending: return ACColors.warning
            }
        }

        var backgroundColor: Color {
            switch self {
            case .active: return ACColors.successLight
            case .completed: return ACColors.infoLight
            case .draft: return ACColors.warningLight
            case .warning: return ACColors.warningLight
            case .error: return ACColors.errorLight
            case .inactive: return ACColors.borderLight
            case .pending: return ACColors.warningLight
            }
        }
    }

    let text: String
    let status: BadgeStatus

    var body: some View {
        Text(text)
            .font(ACTypography.labelSmall)
            .foregroundColor(status.color)
            .padding(.horizontal, ACSpacing.sm)
            .padding(.vertical, ACSpacing.xs)
            .background(status.backgroundColor)
            .cornerRadius(ACRadius.full)
    }
}

// MARK: - Preview

#Preview("Cards") {
    ScrollView {
        VStack(spacing: ACSpacing.lg) {
            // Route Card
            ACRouteCard(
                title: "Barrio de las Letras",
                subtitle: "Madrid, Centro",
                duration: "45 min",
                distance: "2.3 km",
                stopsCount: 8,
                isFavorite: true,
                onTap: {},
                onFavorite: {}
            )

            // Compact cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ACSpacing.md) {
                    ACCompactRouteCard(
                        title: "Descubre Arganzuela",
                        subtitle: "Madrid",
                        duration: "30 min",
                        stopsCount: 6,
                        onTap: {}
                    )
                    ACCompactRouteCard(
                        title: "Zamora Románica",
                        subtitle: "Zamora",
                        duration: "90 min",
                        stopsCount: 15,
                        onTap: {}
                    )
                }
                .padding(.horizontal)
            }

            // ETA Cards
            HStack(spacing: ACSpacing.md) {
                ACETACard(
                    value: "12",
                    unit: "min",
                    label: "Duración",
                    icon: "clock.fill",
                    color: ACColors.primary
                )
                ACETACard(
                    value: "1.2",
                    unit: "km",
                    label: "Distancia",
                    icon: "figure.walk",
                    color: ACColors.secondary
                )
                ACETACard(
                    value: "5",
                    unit: "",
                    label: "Paradas",
                    icon: "mappin.circle.fill",
                    color: ACColors.info
                )
            }
            .padding(.horizontal)

            // Info Card
            ACInfoCard(
                icon: "headphones",
                title: "Audio automático",
                description: "La narración se reproduce al llegar a cada punto"
            )
            .padding(.horizontal)

            // Status badges
            HStack(spacing: ACSpacing.sm) {
                ACStatusBadge(text: "Activa", status: .active)
                ACStatusBadge(text: "Completada", status: .completed)
                ACStatusBadge(text: "Borrador", status: .draft)
            }
        }
        .padding(.vertical)
    }
    .background(ACColors.background)
}
