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
                // Icon - Maleta de viaje
                ZStack {
                    RoundedRectangle(cornerRadius: ACRadius.md)
                        .fill(ACColors.primaryLight)
                        .frame(width: 56, height: 56)

                    Image(systemName: "suitcase.rolling.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ACColors.primary)
                }

                // Info
                VStack(alignment: .leading, spacing: ACSpacing.xs) {
                    // Ciudad y badge activo
                    HStack {
                        Text(trip.destinationCity)
                            .font(ACTypography.titleMedium)
                            .foregroundColor(ACColors.textPrimary)

                        if trip.isCurrent {
                            ACStatusBadge(text: "Activo", status: .active)
                        }
                    }

                    // Fechas del viaje (prominentes)
                    if let dateRange = trip.dateRangeFormatted {
                        HStack(spacing: ACSpacing.xs) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(ACColors.primary)
                            Text(dateRange)
                                .font(ACTypography.bodySmall)
                                .foregroundColor(ACColors.textSecondary)
                        }
                    }

                    // Meta info
                    HStack(spacing: ACSpacing.md) {
                        ACMetaBadge(icon: "map", text: "\(trip.routeCount) rutas")

                        if trip.isOfflineAvailable {
                            ACMetaBadge(icon: "arrow.down.circle.fill", text: "Offline", color: ACColors.success)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ACColors.textTertiary)
            }
            .padding(ACSpacing.md)
            .background(ACColors.surface)
            .cornerRadius(ACRadius.lg)
            .acShadow(ACShadow.sm)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Scale Button Style (microinteracción)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
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
