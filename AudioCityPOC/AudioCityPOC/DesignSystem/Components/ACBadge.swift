//
//  ACBadge.swift
//  AudioCityPOC
//
//  Componentes de badge/etiqueta del sistema de diseño
//  Chips, tags, contadores y badges de notificación
//

import SwiftUI

// MARK: - Badge Variants

enum ACBadgeVariant {
    case filled      // Fondo sólido
    case outlined    // Solo borde
    case soft        // Fondo suave con texto coloreado
}

enum ACBadgeSize {
    case small   // Para inline
    case medium  // Estándar
    case large   // Destacado
}

// MARK: - Badge Colors

enum ACBadgeColor {
    case primary
    case secondary
    case success
    case warning
    case error
    case info
    case neutral

    var main: Color {
        switch self {
        case .primary: return ACColors.primary
        case .secondary: return ACColors.secondary
        case .success: return ACColors.success
        case .warning: return ACColors.warning
        case .error: return ACColors.error
        case .info: return ACColors.info
        case .neutral: return ACColors.textSecondary
        }
    }

    var light: Color {
        switch self {
        case .primary: return ACColors.primaryLight
        case .secondary: return ACColors.secondaryLight
        case .success: return ACColors.successLight
        case .warning: return ACColors.warningLight
        case .error: return ACColors.errorLight
        case .info: return ACColors.infoLight
        case .neutral: return ACColors.borderLight
        }
    }
}

// MARK: - Badge

/// Badge genérico y flexible
struct ACBadge: View {
    let text: String
    let icon: String?
    let color: ACBadgeColor
    let variant: ACBadgeVariant
    let size: ACBadgeSize

    init(
        _ text: String,
        icon: String? = nil,
        color: ACBadgeColor = .primary,
        variant: ACBadgeVariant = .soft,
        size: ACBadgeSize = .medium
    ) {
        self.text = text
        self.icon = icon
        self.color = color
        self.variant = variant
        self.size = size
    }

    var body: some View {
        HStack(spacing: iconSpacing) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: iconSize))
            }

            Text(text)
                .font(textFont)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(borderColor, lineWidth: variant == .outlined ? 1 : 0)
        )
    }

    // MARK: - Style Properties

    private var textColor: Color {
        switch variant {
        case .filled: return .white
        case .outlined, .soft: return color.main
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .filled: return color.main
        case .outlined: return .clear
        case .soft: return color.light
        }
    }

    private var borderColor: Color {
        switch variant {
        case .outlined: return color.main
        default: return .clear
        }
    }

    private var textFont: Font {
        switch size {
        case .small: return ACTypography.captionSmall
        case .medium: return ACTypography.labelSmall
        case .large: return ACTypography.labelMedium
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }

    private var iconSpacing: CGFloat {
        switch size {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return ACSpacing.xs
        case .medium: return ACSpacing.sm
        case .large: return ACSpacing.md
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 2
        case .medium: return ACSpacing.xs
        case .large: return ACSpacing.sm
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return ACRadius.xs
        case .medium: return ACRadius.sm
        case .large: return ACRadius.md
        }
    }
}

// MARK: - Pill Badge (Completamente redondeado)

struct ACPillBadge: View {
    let text: String
    let icon: String?
    let color: ACBadgeColor
    let variant: ACBadgeVariant

    init(
        _ text: String,
        icon: String? = nil,
        color: ACBadgeColor = .primary,
        variant: ACBadgeVariant = .soft
    ) {
        self.text = text
        self.icon = icon
        self.color = color
        self.variant = variant
    }

    var body: some View {
        HStack(spacing: ACSpacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 12))
            }

            Text(text)
                .font(ACTypography.labelSmall)
        }
        .foregroundColor(textColor)
        .padding(.horizontal, ACSpacing.md)
        .padding(.vertical, ACSpacing.xs)
        .background(backgroundColor)
        .cornerRadius(ACRadius.full)
        .overlay(
            Capsule()
                .stroke(borderColor, lineWidth: variant == .outlined ? 1 : 0)
        )
    }

    private var textColor: Color {
        switch variant {
        case .filled: return .white
        case .outlined, .soft: return color.main
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .filled: return color.main
        case .outlined: return .clear
        case .soft: return color.light
        }
    }

    private var borderColor: Color {
        switch variant {
        case .outlined: return color.main
        default: return .clear
        }
    }
}

// MARK: - Count Badge (Para notificaciones)

struct ACCountBadge: View {
    let count: Int
    let maxCount: Int
    let color: Color

    init(
        count: Int,
        maxCount: Int = 99,
        color: Color = ACColors.error
    ) {
        self.count = count
        self.maxCount = maxCount
        self.color = color
    }

    var body: some View {
        if count > 0 {
            Text(displayText)
                .font(ACTypography.captionSmall)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(minWidth: minWidth, minHeight: 18)
                .padding(.horizontal, count > 9 ? 4 : 0)
                .background(color)
                .cornerRadius(9)
        }
    }

    private var displayText: String {
        if count > maxCount {
            return "\(maxCount)+"
        }
        return "\(count)"
    }

    private var minWidth: CGFloat {
        count > 9 ? 24 : 18
    }
}

// MARK: - Level Badge (Para gamificación)

struct ACLevelBadge: View {
    let level: Int
    let name: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: ACSpacing.sm) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }

            // Level info
            VStack(alignment: .leading, spacing: 0) {
                Text("Nivel \(level)")
                    .font(ACTypography.captionSmall)
                    .foregroundColor(ACColors.textTertiary)

                Text(name)
                    .font(ACTypography.titleSmall)
                    .foregroundColor(color)
            }
        }
        .padding(ACSpacing.sm)
        .background(color.opacity(0.05))
        .cornerRadius(ACRadius.md)
    }
}

// MARK: - Points Badge

struct ACPointsBadge: View {
    let points: Int
    let showIcon: Bool

    init(points: Int, showIcon: Bool = true) {
        self.points = points
        self.showIcon = showIcon
    }

    var body: some View {
        HStack(spacing: ACSpacing.xs) {
            if showIcon {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(ACColors.gold)
            }

            Text(formattedPoints)
                .font(ACTypography.labelMedium)
                .foregroundColor(ACColors.gold)
        }
        .padding(.horizontal, ACSpacing.sm)
        .padding(.vertical, ACSpacing.xs)
        .background(ACColors.goldLight)
        .cornerRadius(ACRadius.full)
    }

    private var formattedPoints: String {
        if points >= 1000 {
            return String(format: "%.1fk", Double(points) / 1000)
        }
        return "\(points) pts"
    }
}

// MARK: - Tag (Con opción de eliminar)
// Note: ACChip is defined in ACInput.swift

struct ACTag: View {
    let text: String
    let color: ACBadgeColor
    let onDelete: (() -> Void)?

    init(
        _ text: String,
        color: ACBadgeColor = .neutral,
        onDelete: (() -> Void)? = nil
    ) {
        self.text = text
        self.color = color
        self.onDelete = onDelete
    }

    var body: some View {
        HStack(spacing: ACSpacing.xs) {
            Text(text)
                .font(ACTypography.labelSmall)
                .foregroundColor(color.main)

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(color.main.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, ACSpacing.sm)
        .padding(.vertical, ACSpacing.xs)
        .background(color.light)
        .cornerRadius(ACRadius.sm)
    }
}

// MARK: - Preview

#Preview("Badges") {
    ScrollView {
        VStack(spacing: ACSpacing.xl) {
            // Basic Badges
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Basic Badges")
                    .font(ACTypography.headlineSmall)

                HStack(spacing: ACSpacing.sm) {
                    ACBadge("Primary", color: .primary, variant: .filled)
                    ACBadge("Success", color: .success, variant: .filled)
                    ACBadge("Warning", color: .warning, variant: .filled)
                    ACBadge("Error", color: .error, variant: .filled)
                }

                HStack(spacing: ACSpacing.sm) {
                    ACBadge("Outlined", color: .primary, variant: .outlined)
                    ACBadge("Soft", color: .primary, variant: .soft)
                }

                HStack(spacing: ACSpacing.sm) {
                    ACBadge("Small", icon: "star.fill", size: .small)
                    ACBadge("Medium", icon: "star.fill", size: .medium)
                    ACBadge("Large", icon: "star.fill", size: .large)
                }
            }
            .padding()

            SwiftUI.Divider()

            // Pill Badges
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Pill Badges")
                    .font(ACTypography.headlineSmall)

                HStack(spacing: ACSpacing.sm) {
                    ACPillBadge("Nuevo", icon: "sparkles", color: .primary)
                    ACPillBadge("Popular", icon: "flame.fill", color: .warning)
                    ACPillBadge("Verificado", icon: "checkmark.seal.fill", color: .success)
                }
            }
            .padding()

            SwiftUI.Divider()

            // Count Badges
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Count Badges")
                    .font(ACTypography.headlineSmall)

                HStack(spacing: ACSpacing.xl) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ACColors.textSecondary)
                        ACCountBadge(count: 3)
                            .offset(x: 8, y: -8)
                    }

                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ACColors.textSecondary)
                        ACCountBadge(count: 42)
                            .offset(x: 8, y: -8)
                    }

                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cart.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ACColors.textSecondary)
                        ACCountBadge(count: 150)
                            .offset(x: 8, y: -8)
                    }
                }
            }
            .padding()

            SwiftUI.Divider()

            // Level & Points
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Gamification Badges")
                    .font(ACTypography.headlineSmall)

                ACLevelBadge(
                    level: 3,
                    name: "Guía Local",
                    icon: "map",
                    color: ACColors.Levels.localGuide
                )

                HStack(spacing: ACSpacing.md) {
                    ACPointsBadge(points: 350)
                    ACPointsBadge(points: 1250)
                }
            }
            .padding()

            SwiftUI.Divider()

            // Chips
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Chips (Selectable)")
                    .font(ACTypography.headlineSmall)

                HStack(spacing: ACSpacing.sm) {
                    ACChip(text: "Madrid", isSelected: true) {}
                    ACChip(text: "Barcelona", isSelected: false) {}
                    ACChip(text: "Sevilla", isSelected: false) {}
                }
            }
            .padding()

            SwiftUI.Divider()

            // Tags
            VStack(alignment: .leading, spacing: ACSpacing.md) {
                Text("Tags")
                    .font(ACTypography.headlineSmall)

                HStack(spacing: ACSpacing.sm) {
                    ACTag("Historia", color: .info)
                    ACTag("Gastronomía", color: .warning, onDelete: {})
                    ACTag("Arte", color: .secondary, onDelete: {})
                }
            }
            .padding()
        }
    }
    .background(ACColors.background)
}
