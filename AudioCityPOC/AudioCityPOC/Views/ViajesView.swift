//
//  ViajesView.swift
//  AudioCityPOC
//
//  Vista principal del tab de Viajes - Planificación de viajes
//

import SwiftUI

struct ViajesView: View {
    @ObservedObject private var tripService = TripService.shared
    @State private var showingTripOnboarding = false
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationStack {
            Group {
                if tripService.trips.isEmpty {
                    emptyStateView
                } else {
                    tripsListView
                }
            }
            .background(ACColors.background)
            .navigationTitle("Viajes")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    ACButton("Planificar", icon: "plus", style: .primary, size: .small) {
                        showingTripOnboarding = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingTripOnboarding) {
            TripOnboardingView(tripService: tripService, onComplete: { _ in
                showingTripOnboarding = false
            })
        }
        .sheet(item: $selectedTrip) { trip in
            TripDetailView(trip: trip, tripService: tripService)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: ACSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ACColors.secondaryLight)
                    .frame(width: 120, height: 120)

                Image(systemName: "suitcase.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ACColors.secondary)
            }

            VStack(spacing: ACSpacing.sm) {
                Text("Planifica tu viaje")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text("Organiza tus rutas por destino y tenlas disponibles offline")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ACSpacing.xxl)
            }

            ACButton("Crear mi primer viaje", icon: "plus", style: .primary, size: .large) {
                showingTripOnboarding = true
            }
            .padding(.horizontal, ACSpacing.containerPadding)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Trips List

    private var tripsListView: some View {
        ScrollView {
            VStack(spacing: ACSpacing.sectionSpacing) {
                // Viaje activo
                if let currentTrip = currentTrips.first {
                    currentTripSection(currentTrip)
                        .padding(.horizontal, ACSpacing.containerPadding)
                }

                // Próximos viajes
                if !upcomingTrips.isEmpty {
                    tripsSection(
                        title: "Próximos",
                        icon: "calendar",
                        iconColor: ACColors.secondary,
                        trips: upcomingTrips
                    )
                }

                // Viajes pasados
                if !pastTrips.isEmpty {
                    tripsSection(
                        title: "Pasados",
                        icon: "clock.arrow.circlepath",
                        iconColor: ACColors.textTertiary,
                        trips: pastTrips,
                        isPast: true
                    )
                }

                Spacer(minLength: ACSpacing.mega)
            }
            .padding(.top, ACSpacing.base)
        }
    }

    // MARK: - Current Trip Section

    private func currentTripSection(_ trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack(spacing: ACSpacing.sm) {
                Image(systemName: "location.fill")
                    .font(.system(size: 18))
                    .foregroundColor(ACColors.success)

                Text("Viaje activo")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)
            }

            // Card con borde destacado
            Button(action: { selectedTrip = trip }) {
                HStack(spacing: ACSpacing.md) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: ACRadius.md)
                            .fill(ACColors.successLight)
                            .frame(width: 56, height: 56)

                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ACColors.success)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: ACSpacing.xs) {
                        HStack {
                            Text(trip.destinationCity)
                                .font(ACTypography.titleMedium)
                                .foregroundColor(ACColors.textPrimary)

                            ACStatusBadge(text: "Ahora", status: .active)
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
                .background(ACColors.surface)
                .cornerRadius(ACRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: ACRadius.lg)
                        .stroke(ACColors.success, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }

    // MARK: - Trips Section

    private func tripsSection(
        title: String,
        icon: String,
        iconColor: Color,
        trips: [Trip],
        isPast: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack(spacing: ACSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text("\(trips.count)")
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textTertiary)
            }
            .padding(.horizontal, ACSpacing.containerPadding)

            // Trips
            VStack(spacing: ACSpacing.sm) {
                ForEach(trips) { trip in
                    ACTripCard(trip: trip) {
                        selectedTrip = trip
                    }
                    .opacity(isPast ? 0.7 : 1.0)
                }
            }
            .padding(.horizontal, ACSpacing.containerPadding)
        }
    }

    // MARK: - Computed Properties

    private var currentTrips: [Trip] {
        tripService.trips.filter { $0.isCurrent }
    }

    private var upcomingTrips: [Trip] {
        tripService.trips
            .filter { !$0.isPast && !$0.isCurrent }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
    }

    private var pastTrips: [Trip] {
        tripService.trips
            .filter { $0.isPast }
            .sorted { ($0.endDate ?? .distantPast) > ($1.endDate ?? .distantPast) }
    }
}

#Preview {
    ViajesView()
}
