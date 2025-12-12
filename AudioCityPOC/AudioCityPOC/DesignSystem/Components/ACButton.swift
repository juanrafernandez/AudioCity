//
//  ACButton.swift
//  AudioCityPOC
//
//  Componentes de botón del sistema de diseño
//

import SwiftUI

// MARK: - Button Styles

enum ACButtonStyle {
    case primary      // Fondo coral, texto blanco
    case secondary    // Borde coral, texto coral
    case tertiary     // Solo texto coral
    case ghost        // Texto gris, sin fondo
    case destructive  // Rojo para acciones peligrosas
}

enum ACButtonSize {
    case small   // 32pt altura
    case medium  // 44pt altura (estándar iOS)
    case large   // 52pt altura
}

// MARK: - Primary Button

struct ACButton: View {
    let title: String
    let icon: String?
    let style: ACButtonStyle
    let size: ACButtonSize
    let isLoading: Bool
    let isFullWidth: Bool
    let action: () -> Void

    init(
        _ title: String,
        icon: String? = nil,
        style: ACButtonStyle = .primary,
        size: ACButtonSize = .medium,
        isLoading: Bool = false,
        isFullWidth: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: ACSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: iconSize, weight: .semibold))
                    }
                    Text(title)
                        .font(titleFont)
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .frame(height: height)
            .padding(.horizontal, horizontalPadding)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(isLoading)
        .animation(ACAnimation.spring, value: isLoading)
    }

    // MARK: - Style Properties

    private var height: CGFloat {
        switch size {
        case .small: return 32
        case .medium: return 44
        case .large: return 52
        }
    }

    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return ACSpacing.md
        case .medium: return ACSpacing.base
        case .large: return ACSpacing.xl
        }
    }

    private var cornerRadius: CGFloat {
        switch size {
        case .small: return ACRadius.sm
        case .medium: return ACRadius.md
        case .large: return ACRadius.lg
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }

    private var titleFont: Font {
        switch size {
        case .small: return ACTypography.labelSmall
        case .medium: return ACTypography.labelMedium
        case .large: return ACTypography.labelLarge
        }
    }

    private var textColor: Color {
        switch style {
        case .primary: return ACColors.textInverted
        case .secondary: return ACColors.primary
        case .tertiary: return ACColors.primary
        case .ghost: return ACColors.textSecondary
        case .destructive: return ACColors.textInverted
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return ACColors.primary
        case .secondary: return Color.clear
        case .tertiary: return Color.clear
        case .ghost: return Color.clear
        case .destructive: return ACColors.error
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return Color.clear
        case .secondary: return ACColors.primary
        case .tertiary: return Color.clear
        case .ghost: return Color.clear
        case .destructive: return Color.clear
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .secondary: return ACBorder.medium
        default: return 0
        }
    }
}

// MARK: - Icon Button

struct ACIconButton: View {
    let icon: String
    let style: ACButtonStyle
    let size: ACButtonSize
    let action: () -> Void

    init(
        icon: String,
        style: ACButtonStyle = .ghost,
        size: ACButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.style = style
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: buttonSize, height: buttonSize)
                .background(backgroundColor)
                .cornerRadius(buttonSize / 2)
        }
    }

    private var buttonSize: CGFloat {
        switch size {
        case .small: return 32
        case .medium: return 44
        case .large: return 52
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }

    private var iconColor: Color {
        switch style {
        case .primary: return ACColors.textInverted
        case .secondary, .tertiary: return ACColors.primary
        case .ghost: return ACColors.textSecondary
        case .destructive: return ACColors.error
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return ACColors.primary
        case .secondary: return ACColors.primaryLight
        case .tertiary, .ghost: return Color.clear
        case .destructive: return ACColors.errorLight
        }
    }
}

// MARK: - Floating Action Button

struct ACFloatingButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(ACColors.textInverted)
                .frame(width: 56, height: 56)
                .background(ACColors.primary)
                .cornerRadius(28)
                .acShadow(ACShadow.lg)
        }
    }
}

// MARK: - Preview

#Preview("Buttons") {
    VStack(spacing: ACSpacing.lg) {
        // Primary
        ACButton("Comenzar Ruta", icon: "play.fill", style: .primary) {}

        // Secondary
        ACButton("Ver en mapa", icon: "map", style: .secondary) {}

        // Tertiary
        ACButton("Más información", style: .tertiary) {}

        // Ghost
        ACButton("Cancelar", style: .ghost) {}

        // Full width
        ACButton("Guardar cambios", style: .primary, isFullWidth: true) {}

        // Loading
        ACButton("Cargando...", style: .primary, isLoading: true) {}

        // Sizes
        HStack(spacing: ACSpacing.md) {
            ACButton("S", size: .small) {}
            ACButton("M", size: .medium) {}
            ACButton("L", size: .large) {}
        }

        // Icon buttons
        HStack(spacing: ACSpacing.md) {
            ACIconButton(icon: "heart.fill", style: .primary) {}
            ACIconButton(icon: "heart", style: .secondary) {}
            ACIconButton(icon: "xmark", style: .ghost) {}
        }

        // FAB
        ACFloatingButton(icon: "plus") {}
    }
    .padding()
}
