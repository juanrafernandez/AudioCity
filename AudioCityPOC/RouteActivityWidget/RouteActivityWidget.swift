//
//  RouteActivityWidget.swift
//  RouteActivityWidget
//
//  Widget Extension para mostrar Live Activities en la Dynamic Island
//  Muestra la distancia al próximo punto de la ruta activa
//

import SwiftUI
import WidgetKit
import ActivityKit

// MARK: - Live Activity Configuration

struct RouteActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RouteActivityAttributes.self) { context in
            // Lock Screen / Banner presentation
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded presentation
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }

                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }

            } compactLeading: {
                // Compact leading (izquierda de la cámara)
                CompactLeadingView(context: context)

            } compactTrailing: {
                // Compact trailing (derecha de la cámara)
                CompactTrailingView(context: context)

            } minimal: {
                // Minimal (cuando hay múltiples Live Activities)
                MinimalView(context: context)
            }
            .widgetURL(URL(string: "audiocity://route/\(context.attributes.routeId)"))
            .keylineTint(Color.accentColor)
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<RouteActivityAttributes>

    private var accentColor: Color {
        Color(red: 1.0, green: 0.42, blue: 0.36) // Coral #FF6B5B
    }

    var body: some View {
        HStack(spacing: 16) {
            // Indicador de ruta
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 50, height: 50)

                Image(systemName: context.state.isPlaying ? "waveform" : "headphones")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Info de ruta
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.routeName)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    // Próxima parada
                    HStack(spacing: 4) {
                        Text("\(context.state.nextStopOrder)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(accentColor))

                        Text(context.state.nextStopName)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .foregroundColor(.gray)
                }

                // Progreso
                Text("\(context.state.visitedStops)/\(context.state.totalStops) paradas")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // Distancia grande
            VStack(alignment: .trailing, spacing: 2) {
                Text(context.state.formattedDistance)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(distanceColor)

                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.caption2)
                    Text("caminando")
                        .font(.caption2)
                }
                .foregroundColor(.gray)
            }
        }
        .padding(16)
    }

    private var distanceColor: Color {
        if context.state.distanceToNextStop < 50 {
            return .green
        } else if context.state.distanceToNextStop < 200 {
            return .orange
        } else {
            return accentColor
        }
    }
}

// MARK: - Compact Views (Dynamic Island collapsed)

struct CompactLeadingView: View {
    let context: ActivityViewContext<RouteActivityAttributes>

    private var accentColor: Color {
        Color(red: 1.0, green: 0.42, blue: 0.36)
    }

    var body: some View {
        // Solo número de parada (compacto)
        Text("\(context.state.nextStopOrder)")
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 22, height: 22)
            .background(Circle().fill(accentColor))
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<RouteActivityAttributes>

    private var accentColor: Color {
        Color(red: 1.0, green: 0.42, blue: 0.36)
    }

    var body: some View {
        HStack(spacing: 2) {
            // Distancia
            Text(context.state.formattedDistance)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(distanceColor)
                .contentTransition(.numericText())

            // Indicador de audio
            if context.state.isPlaying {
                Image(systemName: "waveform")
                    .font(.system(size: 10))
                    .foregroundColor(accentColor)
            }
        }
    }

    private var distanceColor: Color {
        if context.state.distanceToNextStop < 50 {
            return .green
        } else if context.state.distanceToNextStop < 200 {
            return .orange
        } else {
            return .white
        }
    }
}

// MARK: - Minimal View (cuando hay múltiples Live Activities)

struct MinimalView: View {
    let context: ActivityViewContext<RouteActivityAttributes>

    private var accentColor: Color {
        Color(red: 1.0, green: 0.42, blue: 0.36)
    }

    var body: some View {
        ZStack {
            // Fondo con color de distancia
            Circle()
                .fill(distanceColor.opacity(0.3))

            // Número de parada o icono de audio
            if context.state.isPlaying {
                Image(systemName: "waveform")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(distanceColor)
            } else {
                Text("\(context.state.nextStopOrder)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(distanceColor)
            }
        }
    }

    private var distanceColor: Color {
        if context.state.distanceToNextStop < 50 {
            return .green
        } else if context.state.distanceToNextStop < 200 {
            return .orange
        } else {
            return accentColor
        }
    }
}

// MARK: - Expanded Views (Dynamic Island expanded)

struct ExpandedLeadingView: View {
    let context: ActivityViewContext<RouteActivityAttributes>

    private var accentColor: Color {
        Color(red: 1.0, green: 0.42, blue: 0.36)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Número de parada grande
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 44, height: 44)

                Text("\(context.state.nextStopOrder)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<RouteActivityAttributes>

    private var accentColor: Color {
        Color(red: 1.0, green: 0.42, blue: 0.36)
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            // Distancia grande
            Text(context.state.formattedDistance)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(distanceColor)
                .contentTransition(.numericText())

            // Indicador caminando
            HStack(spacing: 4) {
                Image(systemName: "figure.walk")
                    .font(.caption2)
                if context.state.distanceToNextStop < 50 {
                    Text("Llegando")
                        .font(.caption2)
                }
            }
            .foregroundColor(.secondary)
        }
    }

    private var distanceColor: Color {
        if context.state.distanceToNextStop < 50 {
            return .green
        } else if context.state.distanceToNextStop < 200 {
            return .orange
        } else {
            return accentColor
        }
    }
}

struct ExpandedCenterView: View {
    let context: ActivityViewContext<RouteActivityAttributes>

    var body: some View {
        VStack(spacing: 2) {
            Text("PRÓXIMA")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)

            Text(context.state.nextStopName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<RouteActivityAttributes>

    private var accentColor: Color {
        Color(red: 1.0, green: 0.42, blue: 0.36)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Barra de progreso
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fondo
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)

                    // Progreso
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accentColor)
                        .frame(width: geometry.size.width * context.state.progressPercentage, height: 6)
                }
            }
            .frame(height: 6)

            // Info de ruta y progreso
            HStack {
                Text(context.attributes.routeName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Spacer()

                Text(context.state.progressText)
                    .font(.caption.bold())
                    .foregroundColor(accentColor)

                // Indicador de audio
                if context.state.isPlaying {
                    HStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(accentColor)
                                .frame(width: 2, height: 8)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Widget Bundle se define en RouteActivityWidgetBundle.swift

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: RouteActivityAttributes.preview) {
    RouteActivityLiveActivity()
} contentStates: {
    RouteActivityAttributes.ContentState.preview
    RouteActivityAttributes.ContentState.previewNear
    RouteActivityAttributes.ContentState.previewPlaying
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: RouteActivityAttributes.preview) {
    RouteActivityLiveActivity()
} contentStates: {
    RouteActivityAttributes.ContentState.preview
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: RouteActivityAttributes.preview) {
    RouteActivityLiveActivity()
} contentStates: {
    RouteActivityAttributes.ContentState.preview
    RouteActivityAttributes.ContentState.previewNear
}

#Preview("Dynamic Island Minimal", as: .dynamicIsland(.minimal), using: RouteActivityAttributes.preview) {
    RouteActivityLiveActivity()
} contentStates: {
    RouteActivityAttributes.ContentState.preview
}

// MARK: - Preview Data

extension RouteActivityAttributes {
    static var preview: RouteActivityAttributes {
        RouteActivityAttributes(
            routeName: "Barrio de las Letras",
            routeCity: "Madrid",
            routeId: "letras-poc-001"
        )
    }
}

extension RouteActivityAttributes.ContentState {
    static var preview: RouteActivityAttributes.ContentState {
        RouteActivityAttributes.ContentState(
            distanceToNextStop: 245,
            nextStopName: "Casa de Lope de Vega",
            nextStopOrder: 2,
            visitedStops: 1,
            totalStops: 5,
            isPlaying: false
        )
    }

    static var previewNear: RouteActivityAttributes.ContentState {
        RouteActivityAttributes.ContentState(
            distanceToNextStop: 35,
            nextStopName: "Casa de Lope de Vega",
            nextStopOrder: 2,
            visitedStops: 1,
            totalStops: 5,
            isPlaying: false
        )
    }

    static var previewPlaying: RouteActivityAttributes.ContentState {
        RouteActivityAttributes.ContentState(
            distanceToNextStop: 0,
            nextStopName: "Casa de Lope de Vega",
            nextStopOrder: 2,
            visitedStops: 2,
            totalStops: 5,
            isPlaying: true
        )
    }
}
