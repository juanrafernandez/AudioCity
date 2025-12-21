//
//  Theme.swift
//  AudioCityPOC
//
//  Sistema de diseño central de AudioCity
//  Inspirado en Transit App: interfaz limpia, colores bold, ETA cards horizontales
//

import SwiftUI

// MARK: - Design Tokens

/// Sistema de colores de AudioCity
/// Basado en principios de psicología del color:
/// - Coral: Energía, aventura, calidez (color primario)
/// - Neutros cálidos: Confort, legibilidad, profesionalismo
struct ACColors {

    // MARK: - Brand Colors

    /// Color primario - Coral vibrante
    /// Transmite: energía, aventura, emoción, calidez
    /// Uso: CTAs principales, elementos destacados, iconos activos
    static let primary = Color(hex: "FF5757")

    /// Color primario oscuro (para pressed states y acentos)
    static let primaryDark = Color(hex: "E04545")

    /// Color primario claro (para fondos sutiles)
    static let primaryLight = Color(hex: "FFE5E5")

    /// Color primario muy claro (para fondos de cards)
    static let primarySurface = Color(hex: "FFF5F5")

    // MARK: - Secondary Colors

    /// Turquesa - Complementario
    /// Transmite: frescura, confianza, tecnología
    /// Uso: Información secundaria, estados de éxito alternativos
    static let secondary = Color(hex: "00BFA6")
    static let secondaryDark = Color(hex: "00A08A")
    static let secondaryLight = Color(hex: "E0FBF7")

    // MARK: - Accent Colors

    /// Amarillo dorado - Puntos y recompensas
    /// Transmite: logro, valor, premium
    static let gold = Color(hex: "FFB800")
    static let goldLight = Color(hex: "FFF4CC")

    /// Azul información
    /// Transmite: confianza, información, navegación
    static let info = Color(hex: "2196F3")
    static let infoLight = Color(hex: "E3F2FD")

    // MARK: - Semantic Colors

    /// Verde éxito
    static let success = Color(hex: "4CAF50")
    static let successLight = Color(hex: "E8F5E9")

    /// Naranja advertencia
    static let warning = Color(hex: "FF9800")
    static let warningLight = Color(hex: "FFF3E0")

    /// Rojo error (diferente al primario para evitar confusión)
    static let error = Color(hex: "D32F2F")
    static let errorLight = Color(hex: "FFEBEE")

    // MARK: - Neutral Colors (Light Mode)

    /// Fondo principal
    static let background = Color(hex: "FAFAFA")

    /// Fondo de superficie (cards, sheets)
    static let surface = Color.white

    /// Fondo elevado (modals, popovers)
    static let surfaceElevated = Color.white

    /// Texto primario - Casi negro para mejor legibilidad
    /// El negro puro (#000) causa fatiga visual
    static let textPrimary = Color(hex: "1A1A1A")

    /// Texto secundario
    static let textSecondary = Color(hex: "6B6B6B")

    /// Texto terciario / placeholder
    static let textTertiary = Color(hex: "9E9E9E")

    /// Texto invertido (sobre fondos oscuros)
    static let textInverted = Color.white

    /// Bordes y divisores
    static let border = Color(hex: "E5E5E5")
    static let borderLight = Color(hex: "F0F0F0")

    /// Separadores sutiles
    static let divider = Color(hex: "EEEEEE")

    // MARK: - Dark Mode Colors

    struct Dark {
        static let background = Color(hex: "121212")
        static let surface = Color(hex: "1E1E1E")
        static let surfaceElevated = Color(hex: "2C2C2C")
        static let textPrimary = Color(hex: "F5F5F5")
        static let textSecondary = Color(hex: "B0B0B0")
        static let textTertiary = Color(hex: "757575")
        static let border = Color(hex: "3D3D3D")
        static let divider = Color(hex: "2D2D2D")

        /// Coral adaptado para dark mode (más saturado)
        static let primary = Color(hex: "FF6B6B")
        static let primarySurface = Color(hex: "2A1F1F")
    }

    // MARK: - Map Colors

    struct Map {
        /// Pin de parada normal
        static let stopPin = Color(hex: "FF5757")
        /// Pin de parada visitada
        static let stopVisited = Color(hex: "4CAF50")
        /// Pin seleccionado
        static let stopSelected = Color(hex: "2196F3")
        /// Línea de ruta
        static let routeLine = Color(hex: "FF5757").opacity(0.8)
        /// Área de geofence
        static let geofenceArea = Color(hex: "FF5757").opacity(0.15)
    }

    // MARK: - Level Colors (Gamificación)

    struct Levels {
        static let explorer = Color(hex: "9E9E9E")    // Gris - Inicio
        static let traveler = Color(hex: "2196F3")    // Azul - Progreso
        static let localGuide = Color(hex: "4CAF50")  // Verde - Intermedio
        static let expert = Color(hex: "9C27B0")      // Púrpura - Avanzado
        static let master = Color(hex: "FF5757")      // Coral - Maestro
    }
}

// MARK: - Typography

/// Sistema tipográfico de AudioCity
/// Basado en principios de legibilidad y jerarquía visual:
/// - SF Pro como fuente del sistema (nativa iOS)
/// - Escala modular para consistencia
/// - Line heights optimizados para lectura
struct ACTypography {

    // MARK: - Display (Títulos grandes, héroes)

    /// Display Large - Splash, héroes
    static let displayLarge = Font.system(size: 40, weight: .bold, design: .rounded)

    /// Display Medium - Títulos de sección principales
    static let displayMedium = Font.system(size: 32, weight: .bold, design: .rounded)

    /// Display Small - Subtítulos destacados
    static let displaySmall = Font.system(size: 28, weight: .semibold, design: .rounded)

    // MARK: - Headlines (Títulos de pantalla y secciones)

    /// Headline Large - Título de pantalla
    static let headlineLarge = Font.system(size: 24, weight: .bold, design: .default)

    /// Headline Medium - Título de sección
    static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .default)

    /// Headline Small - Subtítulos
    static let headlineSmall = Font.system(size: 18, weight: .semibold, design: .default)

    // MARK: - Title (Títulos de cards y elementos)

    /// Title Large - Nombre de ruta en card
    static let titleLarge = Font.system(size: 18, weight: .semibold, design: .default)

    /// Title Medium - Título de elemento
    static let titleMedium = Font.system(size: 16, weight: .semibold, design: .default)

    /// Title Small - Título pequeño
    static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)

    // MARK: - Body (Texto de contenido)

    /// Body Large - Descripciones principales
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)

    /// Body Medium - Texto estándar
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)

    /// Body Small - Texto secundario
    static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Label (Etiquetas y badges)

    /// Label Large - Botones grandes
    static let labelLarge = Font.system(size: 16, weight: .medium, design: .default)

    /// Label Medium - Botones estándar, tabs
    static let labelMedium = Font.system(size: 14, weight: .medium, design: .default)

    /// Label Small - Badges, chips
    static let labelSmall = Font.system(size: 12, weight: .medium, design: .default)

    // MARK: - Caption (Texto auxiliar)

    /// Caption - Metadatos, timestamps
    static let caption = Font.system(size: 12, weight: .regular, design: .default)

    /// Caption Small - Texto muy pequeño
    static let captionSmall = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Numbers (Datos numéricos - Monospace)

    /// Número grande (ETA, puntos)
    static let numberLarge = Font.system(size: 32, weight: .bold, design: .monospaced)

    /// Número medio (tiempos, distancias)
    static let numberMedium = Font.system(size: 20, weight: .semibold, design: .monospaced)

    /// Número pequeño (badges)
    static let numberSmall = Font.system(size: 14, weight: .medium, design: .monospaced)
}

// MARK: - Spacing

/// Sistema de espaciado basado en múltiplos de 4
/// Proporciona ritmo visual y consistencia
struct ACSpacing {
    /// 2pt - Micro espaciado
    static let xxs: CGFloat = 2
    /// 4pt - Extra pequeño
    static let xs: CGFloat = 4
    /// 8pt - Pequeño
    static let sm: CGFloat = 8
    /// 12pt - Medio-pequeño
    static let md: CGFloat = 12
    /// 16pt - Medio (base)
    static let base: CGFloat = 16
    /// 20pt - Medio-grande
    static let lg: CGFloat = 20
    /// 24pt - Grande
    static let xl: CGFloat = 24
    /// 32pt - Extra grande
    static let xxl: CGFloat = 32
    /// 40pt - Jumbo
    static let xxxl: CGFloat = 40
    /// 48pt - Mega
    static let mega: CGFloat = 48

    /// Padding de contenedor estándar
    static let containerPadding: CGFloat = 16

    /// Padding de card
    static let cardPadding: CGFloat = 16

    /// Espacio entre secciones
    static let sectionSpacing: CGFloat = 24
}

// MARK: - Radius

/// Radios de esquina para consistencia visual
struct ACRadius {
    /// Sin radio
    static let none: CGFloat = 0
    /// 4pt - Muy sutil (inputs pequeños)
    static let xs: CGFloat = 4
    /// 8pt - Sutil (chips, tags)
    static let sm: CGFloat = 8
    /// 12pt - Medio (cards pequeñas)
    static let md: CGFloat = 12
    /// 16pt - Grande (cards principales)
    static let lg: CGFloat = 16
    /// 20pt - Extra grande (modales)
    static let xl: CGFloat = 20
    /// 24pt - Jumbo (sheets)
    static let xxl: CGFloat = 24
    /// Circular (avatares, badges)
    static let full: CGFloat = 9999
}

// MARK: - Shadows

/// Sistema de sombras para jerarquía visual
struct ACShadow {

    /// Sombra sutil - cards en reposo
    static let sm = ShadowStyle(
        color: Color.black.opacity(0.04),
        radius: 4,
        x: 0,
        y: 2
    )

    /// Sombra media - cards hover/pressed
    static let md = ShadowStyle(
        color: Color.black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
    )

    /// Sombra grande - elementos flotantes
    static let lg = ShadowStyle(
        color: Color.black.opacity(0.12),
        radius: 16,
        x: 0,
        y: 8
    )

    /// Sombra extra grande - modales
    static let xl = ShadowStyle(
        color: Color.black.opacity(0.16),
        radius: 24,
        x: 0,
        y: 12
    )

    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Animation

/// Duraciones y curvas de animación
struct ACAnimation {
    /// Rápida - feedback inmediato (100ms)
    static let fast: Double = 0.1
    /// Normal - transiciones estándar (200ms)
    static let normal: Double = 0.2
    /// Lenta - transiciones complejas (300ms)
    static let slow: Double = 0.3
    /// Muy lenta - animaciones de entrada (400ms)
    static let slower: Double = 0.4

    /// Spring suave para elementos interactivos
    static let spring = Animation.spring(response: 0.3, dampingFraction: 0.7)

    /// Spring bouncy para celebraciones
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Ease out para entradas
    static let easeOut = Animation.easeOut(duration: normal)

    /// Ease in out para transiciones
    static let easeInOut = Animation.easeInOut(duration: normal)
}

// MARK: - Icon Sizes

/// Tamaños de iconos estandarizados
struct ACIconSize {
    /// 16pt - Inline con texto
    static let xs: CGFloat = 16
    /// 20pt - Botones pequeños
    static let sm: CGFloat = 20
    /// 24pt - Estándar
    static let md: CGFloat = 24
    /// 28pt - Destacado
    static let lg: CGFloat = 28
    /// 32pt - Grande
    static let xl: CGFloat = 32
    /// 48pt - Hero
    static let xxl: CGFloat = 48
    /// 64pt - Ilustración
    static let hero: CGFloat = 64
}

// MARK: - Border Widths

/// Anchos de borde estandarizados
struct ACBorder {
    /// 1pt - Bordes sutiles, divisores
    static let thin: CGFloat = 1.0
    /// 1.5pt - Bordes de botones secundarios
    static let medium: CGFloat = 1.5
    /// 2pt - Bordes de focus, elementos destacados
    static let thick: CGFloat = 2.0
    /// 3pt - Bordes muy destacados
    static let heavy: CGFloat = 3.0
}

// MARK: - Opacities

/// Opacidades estandarizadas para estados y overlays
struct ACOpacity {
    /// 5% - Hover states sutiles
    static let hover: Double = 0.05
    /// 10% - Backgrounds sutiles
    static let subtle: Double = 0.1
    /// 20% - Overlays ligeros
    static let light: Double = 0.2
    /// 40% - Overlays medios (dimmed backgrounds)
    static let medium: Double = 0.4
    /// 50% - Estados disabled
    static let disabled: Double = 0.5
    /// 60% - Overlays pronunciados
    static let heavy: Double = 0.6
    /// 80% - Overlays casi opacos
    static let overlay: Double = 0.8
}

// MARK: - Shadow Elevation Presets

/// Presets de elevación para casos de uso comunes
struct ACShadowElevation {
    /// Sombra para cards en reposo
    static let card = ACShadow.sm
    /// Sombra para cards en hover/pressed
    static let cardHover = ACShadow.md
    /// Sombra para botones flotantes (FAB)
    static let fab = ACShadow.lg
    /// Sombra para modals y sheets
    static let modal = ACShadow.xl
    /// Sombra para elementos de navegación
    static let navigation = ACShadow.md
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

extension View {
    /// Aplica sombra del sistema de diseño
    func acShadow(_ style: ACShadow.ShadowStyle) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }

    /// Card estándar con fondo y sombra
    func acCard() -> some View {
        self
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .acShadow(ACShadow.sm)
    }

    /// Card elevada
    func acCardElevated() -> some View {
        self
            .background(ACColors.surfaceElevated)
            .cornerRadius(ACRadius.lg)
            .acShadow(ACShadow.md)
    }

    /// Padding de contenedor estándar
    func acContainerPadding() -> some View {
        self.padding(.horizontal, ACSpacing.containerPadding)
    }

    /// Padding de sección
    func acSectionPadding() -> some View {
        self.padding(.vertical, ACSpacing.sectionSpacing)
    }

    /// Borde redondeado
    func acBorder(_ color: Color = ACColors.border, radius: CGFloat = ACRadius.md) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color, lineWidth: ACBorder.thin)
            )
    }

    /// Fondo con color primario suave
    func acPrimarySurface() -> some View {
        self
            .background(ACColors.primarySurface)
            .cornerRadius(ACRadius.md)
    }

    /// Estilo de texto primario
    func acTextPrimary() -> some View {
        self.foregroundColor(ACColors.textPrimary)
    }

    /// Estilo de texto secundario
    func acTextSecondary() -> some View {
        self.foregroundColor(ACColors.textSecondary)
    }

    /// Estilo de texto terciario
    func acTextTertiary() -> some View {
        self.foregroundColor(ACColors.textTertiary)
    }
}

// MARK: - Layout Helpers

/// Contenedor con ancho máximo (útil para iPad)
struct ACMaxWidthContainer<Content: View>: View {
    let maxWidth: CGFloat
    let content: Content

    init(maxWidth: CGFloat = 600, @ViewBuilder content: () -> Content) {
        self.maxWidth = maxWidth
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }
}

/// Spacer vertical estandarizado
struct ACVerticalSpacer: View {
    let size: SpacerSize

    enum SpacerSize {
        case small   // 8pt
        case medium  // 16pt
        case large   // 24pt
        case section // 32pt

        var value: CGFloat {
            switch self {
            case .small: return ACSpacing.sm
            case .medium: return ACSpacing.base
            case .large: return ACSpacing.xl
            case .section: return ACSpacing.xxl
            }
        }
    }

    init(_ size: SpacerSize = .medium) {
        self.size = size
    }

    var body: some View {
        Spacer()
            .frame(height: size.value)
    }
}

/// Divisor horizontal con padding
struct ACDivider: View {
    let color: Color
    let insets: EdgeInsets

    init(
        color: Color = ACColors.divider,
        horizontalInset: CGFloat = 0,
        verticalPadding: CGFloat = 0
    ) {
        self.color = color
        self.insets = EdgeInsets(
            top: verticalPadding,
            leading: horizontalInset,
            bottom: verticalPadding,
            trailing: horizontalInset
        )
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(height: 1)
            .padding(insets)
    }
}

// MARK: - Conditional Modifier

extension View {
    /// Aplica un modificador condicionalmente
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Aplica un modificador si el valor opcional existe
    @ViewBuilder
    func ifLet<T, Transform: View>(_ value: T?, transform: (Self, T) -> Transform) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }

    /// Aplica cornerRadius solo a esquinas específicas
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

