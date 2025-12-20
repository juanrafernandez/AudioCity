//
//  ACHistoryComponents.swift
//  AudioCityPOC
//
//  Componentes reutilizables para historial de rutas
//

import SwiftUI

// MARK: - History Stat Item

struct ACHistoryStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: ACSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(ACTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(ACColors.textPrimary)

            Text(label)
                .font(ACTypography.captionSmall)
                .foregroundColor(ACColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - History Stats Row

struct ACHistoryStatsRow: View {
    let stats: HistoryStats

    var body: some View {
        HStack(spacing: 0) {
            ACHistoryStatItem(
                value: "\(stats.totalRoutes)",
                label: "Rutas",
                icon: "map.fill",
                color: ACColors.primary
            )

            ACHistoryStatItem(
                value: stats.totalDistanceFormatted,
                label: "Recorrido",
                icon: "figure.walk",
                color: ACColors.secondary
            )

            ACHistoryStatItem(
                value: stats.totalDurationFormatted,
                label: "Tiempo",
                icon: "clock.fill",
                color: ACColors.info
            )

            ACHistoryStatItem(
                value: "\(stats.completionRate)%",
                label: "Completado",
                icon: "checkmark.circle.fill",
                color: ACColors.success
            )
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }
}

// MARK: - History Record Card

struct ACHistoryRecordCard: View {
    let record: RouteHistory

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(ACColors.border, lineWidth: 4)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: CGFloat(record.completionPercentage) / 100)
                    .stroke(
                        record.isCompleted ? ACColors.success : ACColors.warning,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Text("\(record.completionPercentage)%")
                    .font(ACTypography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundColor(record.isCompleted ? ACColors.success : ACColors.warning)
            }

            // Route Info
            VStack(alignment: .leading, spacing: ACSpacing.xs) {
                HStack {
                    Text(record.routeName)
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(1)

                    if record.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ACColors.success)
                            .font(.system(size: 14))
                    }
                }

                Text(record.routeCity)
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textSecondary)

                HStack(spacing: ACSpacing.md) {
                    ACMetaBadge(icon: "clock", text: record.timeFormatted)
                    ACMetaBadge(icon: "timer", text: record.durationFormatted)
                    ACMetaBadge(icon: "mappin", text: "\(record.stopsVisited)/\(record.totalStops)")
                }
            }

            Spacer()
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }
}

#Preview {
    VStack(spacing: 16) {
        ACHistoryStatsRow(stats: HistoryStats(
            totalRoutes: 12,
            completedRoutes: 10,
            totalDistanceKm: 45.3,
            totalDurationMinutes: 540,
            totalStopsVisited: 85
        ))

        ACHistoryRecordCard(record: RouteHistory(
            routeId: "test",
            routeName: "Barrio de las Letras",
            routeCity: "Madrid",
            totalStops: 5
        ))
    }
    .padding()
    .background(ACColors.background)
}
