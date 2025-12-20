//
//  ACTripCard.swift
//  AudioCityPOC
//
//  Componente de tarjeta de viaje reutilizable
//

import SwiftUI

// MARK: - Trip Card

struct ACTripCard: View {
    let trip: Trip
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: ACRadius.md)
                        .fill(ACColors.secondaryLight)
                        .frame(width: 56, height: 56)

                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ACColors.secondary)
                }

                // Info
                VStack(alignment: .leading, spacing: ACSpacing.xs) {
                    HStack {
                        Text(trip.destinationCity)
                            .font(ACTypography.titleMedium)
                            .foregroundColor(ACColors.textPrimary)

                        if trip.isCurrent {
                            ACStatusBadge(text: "Activo", status: .active)
                        }
                    }

                    HStack(spacing: ACSpacing.md) {
                        ACMetaBadge(icon: "map", text: "\(trip.routeCount) rutas")

                        if trip.isOfflineAvailable {
                            ACMetaBadge(icon: "arrow.down.circle.fill", text: "Offline", color: ACColors.success)
                        }

                        if let dateRange = trip.dateRangeFormatted {
                            ACMetaBadge(icon: "calendar", text: dateRange)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ACColors.textTertiary)
            }
            .padding(ACSpacing.md)
            .background(ACColors.background)
            .cornerRadius(ACRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty Trip Card

struct ACEmptyTripCard: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: ACSpacing.md) {
                ZStack {
                    Circle()
                        .fill(ACColors.secondaryLight)
                        .frame(width: 48, height: 48)

                    Image(systemName: "airplane.departure")
                        .font(.system(size: 20))
                        .foregroundColor(ACColors.secondary)
                }

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text("Planifica tu primer viaje")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)

                    Text("Selecciona destino y rutas para tenerlas offline")
                        .font(ACTypography.bodySmall)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ACColors.textTertiary)
            }
            .padding(ACSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: ACRadius.md)
                    .stroke(ACColors.secondary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: 16) {
        ACTripCard(
            trip: Trip(
                destinationCity: "Madrid",
                selectedRouteIds: ["route1", "route2"],
                startDate: Date(),
                endDate: Date().addingTimeInterval(86400 * 3)
            ),
            onTap: {}
        )

        ACEmptyTripCard(onTap: {})
    }
    .padding()
    .background(ACColors.surface)
}
