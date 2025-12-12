//
//  ACFeedback.swift
//  AudioCityPOC
//
//  Componentes de feedback y estados del sistema de diseño
//

import SwiftUI

// MARK: - Empty State

struct ACEmptyState: View {
    let icon: String
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: ACSpacing.xl) {
            // Icono con fondo
            ZStack {
                Circle()
                    .fill(ACColors.primaryLight)
                    .frame(width: 120, height: 120)

                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundColor(ACColors.primary.opacity(0.6))
            }

            // Texto
            VStack(spacing: ACSpacing.sm) {
                Text(title)
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ACSpacing.xl)
            }

            // Acción opcional
            if let actionTitle = actionTitle, let action = action {
                ACButton(actionTitle, icon: "plus.circle.fill", style: .primary, action: action)
            }
        }
        .padding(ACSpacing.xxl)
    }
}

// MARK: - Loading State

struct ACLoadingState: View {
    let message: String

    var body: some View {
        VStack(spacing: ACSpacing.lg) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: ACColors.primary))
                .scaleEffect(1.5)

            Text(message)
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error State

struct ACErrorState: View {
    let title: String
    let description: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: ACSpacing.xl) {
            ZStack {
                Circle()
                    .fill(ACColors.errorLight)
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(ACColors.error)
            }

            VStack(spacing: ACSpacing.sm) {
                Text(title)
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text(description)
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ACSpacing.xl)
            }

            if let retryAction = retryAction {
                ACButton("Reintentar", icon: "arrow.clockwise", style: .primary, action: retryAction)
            }
        }
        .padding(ACSpacing.xxl)
    }
}

// MARK: - Success State

struct ACSuccessState: View {
    let title: String
    let description: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: ACSpacing.xl) {
            ZStack {
                Circle()
                    .fill(ACColors.successLight)
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(ACColors.success)
            }

            VStack(spacing: ACSpacing.sm) {
                Text(title)
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text(description)
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle = actionTitle, let action = action {
                ACButton(actionTitle, style: .primary, action: action)
            }
        }
        .padding(ACSpacing.xxl)
    }
}

// MARK: - Toast

struct ACToast: View {
    enum ToastType {
        case success
        case error
        case warning
        case info

        var icon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .success: return ACColors.success
            case .error: return ACColors.error
            case .warning: return ACColors.warning
            case .info: return ACColors.info
            }
        }

        var backgroundColor: Color {
            switch self {
            case .success: return ACColors.successLight
            case .error: return ACColors.errorLight
            case .warning: return ACColors.warningLight
            case .info: return ACColors.infoLight
            }
        }
    }

    let message: String
    let type: ToastType

    var body: some View {
        HStack(spacing: ACSpacing.sm) {
            Image(systemName: type.icon)
                .font(.system(size: 18))
                .foregroundColor(type.color)

            Text(message)
                .font(ACTypography.bodyMedium)
                .foregroundColor(ACColors.textPrimary)

            Spacer()
        }
        .padding(ACSpacing.md)
        .background(type.backgroundColor)
        .cornerRadius(ACRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: ACRadius.md)
                .stroke(type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Alert Banner

struct ACAlertBanner: View {
    let title: String
    let message: String
    let type: ACToast.ToastType
    var action: (() -> Void)? = nil
    var actionTitle: String = "Ver más"

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.sm) {
            HStack(spacing: ACSpacing.sm) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.color)

                Text(title)
                    .font(ACTypography.titleSmall)
                    .foregroundColor(ACColors.textPrimary)

                Spacer()
            }

            Text(message)
                .font(ACTypography.bodySmall)
                .foregroundColor(ACColors.textSecondary)

            if let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(ACTypography.labelSmall)
                        .foregroundColor(type.color)
                }
            }
        }
        .padding(ACSpacing.md)
        .background(type.backgroundColor)
        .cornerRadius(ACRadius.md)
    }
}

// MARK: - Skeleton Loading

struct ACSkeleton: View {
    var width: CGFloat? = nil
    var height: CGFloat = 20
    var cornerRadius: CGFloat = ACRadius.sm

    @State private var isAnimating = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        ACColors.border,
                        ACColors.borderLight,
                        ACColors.border
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Card

struct ACSkeletonCard: View {
    var body: some View {
        HStack(spacing: ACSpacing.md) {
            ACSkeleton(width: 80, height: 80, cornerRadius: ACRadius.md)

            VStack(alignment: .leading, spacing: ACSpacing.sm) {
                ACSkeleton(height: 16)
                ACSkeleton(width: 120, height: 12)
                ACSkeleton(width: 80, height: 12)
            }

            Spacer()
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
    }
}

// MARK: - Tooltip

struct ACTooltip<Content: View>: View {
    let content: Content
    let message: String
    @State private var showTooltip = false

    init(message: String, @ViewBuilder content: () -> Content) {
        self.message = message
        self.content = content()
    }

    var body: some View {
        content
            .onTapGesture {
                withAnimation(ACAnimation.spring) {
                    showTooltip.toggle()
                }
            }
            .overlay(alignment: .top) {
                if showTooltip {
                    Text(message)
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textInverted)
                        .padding(.horizontal, ACSpacing.sm)
                        .padding(.vertical, ACSpacing.xs)
                        .background(ACColors.textPrimary)
                        .cornerRadius(ACRadius.sm)
                        .offset(y: -40)
                        .transition(.opacity.combined(with: .scale))
                }
            }
    }
}

// MARK: - Badge (Notification)

struct ACNotificationBadge: View {
    let count: Int
    var maxCount: Int = 99

    var body: some View {
        if count > 0 {
            Text(count > maxCount ? "\(maxCount)+" : "\(count)")
                .font(ACTypography.captionSmall)
                .fontWeight(.bold)
                .foregroundColor(ACColors.textInverted)
                .padding(.horizontal, count > 9 ? ACSpacing.xs : 0)
                .frame(minWidth: 18, minHeight: 18)
                .background(ACColors.primary)
                .cornerRadius(9)
        }
    }
}

// MARK: - Compact Empty State

/// Estado vacío compacto para listas
struct ACEmptyStateCompact: View {
    let icon: String
    let title: String
    let description: String?

    init(
        icon: String,
        title: String,
        description: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
    }

    var body: some View {
        VStack(spacing: ACSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(ACColors.textTertiary)

            VStack(spacing: ACSpacing.xs) {
                Text(title)
                    .font(ACTypography.titleMedium)
                    .foregroundColor(ACColors.textSecondary)

                if let description = description {
                    Text(description)
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textTertiary)
                }
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(ACSpacing.xxl)
    }
}

// MARK: - No Results State

/// Estado sin resultados de búsqueda
struct ACNoResultsState: View {
    let searchTerm: String
    let onClearSearch: (() -> Void)?

    init(searchTerm: String, onClearSearch: (() -> Void)? = nil) {
        self.searchTerm = searchTerm
        self.onClearSearch = onClearSearch
    }

    var body: some View {
        VStack(spacing: ACSpacing.lg) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(ACColors.textTertiary)

            VStack(spacing: ACSpacing.sm) {
                Text("Sin resultados")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text("No encontramos nada para \"\(searchTerm)\"")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let onClearSearch = onClearSearch {
                ACButton("Limpiar búsqueda", style: .tertiary) {
                    onClearSearch()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ACSpacing.xl)
    }
}

// MARK: - Offline State

/// Estado sin conexión
struct ACOfflineState: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: ACSpacing.lg) {
            ZStack {
                Circle()
                    .fill(ACColors.warningLight)
                    .frame(width: 80, height: 80)

                Image(systemName: "wifi.slash")
                    .font(.system(size: 32))
                    .foregroundColor(ACColors.warning)
            }

            VStack(spacing: ACSpacing.sm) {
                Text("Sin conexión")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text("Parece que no tienes conexión a internet. Revisa tu conexión e inténtalo de nuevo.")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ACSpacing.xl)
            }

            ACButton("Reintentar", icon: "arrow.clockwise", style: .secondary) {
                onRetry()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(ACSpacing.xl)
    }
}

// MARK: - Loading Dots Animation

struct ACLoadingDots: View {
    @State private var animating = false

    var body: some View {
        HStack(spacing: ACSpacing.sm) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(ACColors.primary)
                    .frame(width: 10, height: 10)
                    .scaleEffect(animating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animating
                    )
            }
        }
        .onAppear { animating = true }
    }
}

// MARK: - Preview

#Preview("Feedback") {
    ScrollView {
        VStack(spacing: ACSpacing.xxl) {
            // Empty state
            ACEmptyState(
                icon: "map",
                title: "No hay rutas",
                description: "Crea tu primera ruta y compártela con otros viajeros",
                actionTitle: "Crear ruta",
                action: {}
            )

            SwiftUI.Divider()

            // Error state
            ACErrorState(
                title: "Error de conexión",
                description: "No pudimos cargar las rutas. Verifica tu conexión.",
                retryAction: {}
            )

            SwiftUI.Divider()

            // Toasts
            VStack(spacing: ACSpacing.md) {
                ACToast(message: "Ruta guardada correctamente", type: .success)
                ACToast(message: "Error al cargar datos", type: .error)
                ACToast(message: "Sin conexión a internet", type: .warning)
                ACToast(message: "Nueva actualización disponible", type: .info)
            }
            .padding(.horizontal)

            // Alert banner
            ACAlertBanner(
                title: "Actualización disponible",
                message: "Hay nuevas rutas en tu zona. Descárgalas ahora.",
                type: .info,
                action: {}
            )
            .padding(.horizontal)

            // Skeleton
            VStack(spacing: ACSpacing.md) {
                ACSkeletonCard()
                ACSkeletonCard()
            }
            .padding(.horizontal)

            // Badge
            HStack(spacing: ACSpacing.xl) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell")
                        .font(.system(size: 24))
                    ACNotificationBadge(count: 3)
                        .offset(x: 8, y: -8)
                }

                ZStack(alignment: .topTrailing) {
                    Image(systemName: "envelope")
                        .font(.system(size: 24))
                    ACNotificationBadge(count: 125)
                        .offset(x: 12, y: -8)
                }
            }
        }
        .padding(.vertical)
    }
    .background(ACColors.background)
}
