//
//  ACList.swift
//  AudioCityPOC
//
//  Componentes de lista del sistema de diseño
//  Filas, secciones y estados vacíos estandarizados
//

import SwiftUI

// MARK: - List Row

/// Fila de lista estándar
struct ACListRow: View {
    let title: String
    let subtitle: String?
    let leadingIcon: String?
    let leadingIconColor: Color
    let trailingContent: TrailingContent
    let onTap: (() -> Void)?

    enum TrailingContent {
        case none
        case chevron
        case text(String)
        case badge(String, ACBadgeColor)
        case toggle(Binding<Bool>)
        case custom(AnyView)
    }

    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: String? = nil,
        leadingIconColor: Color = ACColors.primary,
        trailing: TrailingContent = .chevron,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.leadingIconColor = leadingIconColor
        self.trailingContent = trailing
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: ACSpacing.md) {
                // Leading icon
                if let icon = leadingIcon {
                    ZStack {
                        Circle()
                            .fill(leadingIconColor.opacity(0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(leadingIconColor)
                    }
                }

                // Content
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

                // Trailing content
                trailingView
            }
            .padding(.vertical, ACSpacing.md)
            .padding(.horizontal, ACSpacing.base)
            .background(ACColors.surface)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(onTap == nil)
    }

    @ViewBuilder
    private var trailingView: some View {
        switch trailingContent {
        case .none:
            EmptyView()

        case .chevron:
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(ACColors.textTertiary)

        case .text(let text):
            Text(text)
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textSecondary)

        case .badge(let text, let color):
            ACBadge(text, color: color, variant: .soft, size: .small)

        case .toggle(let binding):
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(ACColors.primary)

        case .custom(let view):
            view
        }
    }
}

// MARK: - List Section

/// Sección de lista con header
struct ACListSection<Content: View>: View {
    let title: String?
    let subtitle: String?
    let content: Content

    init(
        title: String? = nil,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            if title != nil || subtitle != nil {
                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    if let title = title {
                        Text(title)
                            .font(ACTypography.headlineSmall)
                            .foregroundColor(ACColors.textPrimary)
                    }

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(ACTypography.bodySmall)
                            .foregroundColor(ACColors.textSecondary)
                    }
                }
                .padding(.horizontal, ACSpacing.base)
                .padding(.top, ACSpacing.lg)
                .padding(.bottom, ACSpacing.sm)
            }

            // Content with dividers
            VStack(spacing: 0) {
                content
            }
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .padding(.horizontal, ACSpacing.base)
        }
    }
}

// MARK: - Divider Row

/// Divisor para listas
struct ACListDivider: View {
    let inset: CGFloat

    init(inset: CGFloat = 56) {
        self.inset = inset
    }

    var body: some View {
        Rectangle()
            .fill(ACColors.divider)
            .frame(height: 1)
            .padding(.leading, inset)
    }
}

// MARK: - Swipeable Row

/// Fila con acciones de swipe
struct ACSwipeableRow<Content: View>: View {
    let content: Content
    let leadingActions: [SwipeAction]
    let trailingActions: [SwipeAction]

    struct SwipeAction: Identifiable {
        let id = UUID()
        let icon: String
        let color: Color
        let action: () -> Void
    }

    init(
        leadingActions: [SwipeAction] = [],
        trailingActions: [SwipeAction] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
        self.content = content()
    }

    var body: some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: leadingActions.count == 1) {
                ForEach(leadingActions) { action in
                    Button(action: action.action) {
                        Image(systemName: action.icon)
                    }
                    .tint(action.color)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: trailingActions.count == 1) {
                ForEach(trailingActions) { action in
                    Button(action: action.action) {
                        Image(systemName: action.icon)
                    }
                    .tint(action.color)
                }
            }
    }
}

// MARK: - Grouped List Container

/// Contenedor para lista agrupada
struct ACGroupedList<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: ACSpacing.lg) {
                content
            }
            .padding(.vertical, ACSpacing.md)
        }
        .background(ACColors.background)
    }
}

// MARK: - Selectable Row

/// Fila seleccionable (radio/checkbox style)
struct ACSelectableRow: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let selectionStyle: SelectionStyle
    let onTap: () -> Void

    enum SelectionStyle {
        case checkmark
        case radio
        case checkbox
    }

    init(
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        style: SelectionStyle = .checkmark,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.selectionStyle = style
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.md) {
                // Selection indicator
                selectionIndicator

                // Content
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
            }
            .padding(.vertical, ACSpacing.md)
            .padding(.horizontal, ACSpacing.base)
            .background(isSelected ? ACColors.primarySurface : ACColors.surface)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(ACAnimation.spring, value: isSelected)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        switch selectionStyle {
        case .checkmark:
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22))
                .foregroundColor(isSelected ? ACColors.primary : ACColors.textTertiary)

        case .radio:
            ZStack {
                Circle()
                    .stroke(isSelected ? ACColors.primary : ACColors.border, lineWidth: 2)
                    .frame(width: 22, height: 22)

                if isSelected {
                    Circle()
                        .fill(ACColors.primary)
                        .frame(width: 12, height: 12)
                }
            }

        case .checkbox:
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(isSelected ? ACColors.primary : ACColors.border, lineWidth: 2)
                    .frame(width: 22, height: 22)

                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(ACColors.primary)
                        .frame(width: 22, height: 22)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("List Components") {
    ACGroupedList {
        // Settings section
        ACListSection(title: "Configuración", subtitle: "Ajustes de la aplicación") {
            ACListRow(
                title: "Notificaciones",
                subtitle: "Gestionar alertas",
                leadingIcon: "bell.fill",
                onTap: {}
            )
            ACListDivider()
            ACListRow(
                title: "Sonido",
                leadingIcon: "speaker.wave.2.fill",
                leadingIconColor: ACColors.secondary,
                trailing: .toggle(.constant(true))
            )
            ACListDivider()
            ACListRow(
                title: "Idioma",
                leadingIcon: "globe",
                leadingIconColor: ACColors.info,
                trailing: .text("Español")
            )
        }

        // Account section
        ACListSection(title: "Cuenta") {
            ACListRow(
                title: "Nivel actual",
                leadingIcon: "star.fill",
                leadingIconColor: ACColors.gold,
                trailing: .badge("Guía Local", .success),
                onTap: {}
            )
            ACListDivider()
            ACListRow(
                title: "Cerrar sesión",
                leadingIcon: "rectangle.portrait.and.arrow.right",
                leadingIconColor: ACColors.error,
                trailing: .none,
                onTap: {}
            )
        }

        // Selectable section
        ACListSection(title: "Dificultad") {
            ACSelectableRow(
                title: "Fácil",
                subtitle: "Rutas cortas y accesibles",
                isSelected: false,
                style: .radio,
                onTap: {}
            )
            ACListDivider(inset: 0)
            ACSelectableRow(
                title: "Media",
                subtitle: "Rutas de duración moderada",
                isSelected: true,
                style: .radio,
                onTap: {}
            )
            ACListDivider(inset: 0)
            ACSelectableRow(
                title: "Difícil",
                subtitle: "Rutas largas y exigentes",
                isSelected: false,
                style: .radio,
                onTap: {}
            )
        }
    }
}
