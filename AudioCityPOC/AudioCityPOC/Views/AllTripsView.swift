//
//  AllTripsView.swift
//  AudioCityPOC
//
//  Vista para mostrar todos los viajes del usuario (pasados, actuales y futuros)
//

import SwiftUI

struct AllTripsView: View {
    @ObservedObject var tripService: TripService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTrip: Trip?

    var body: some View {
        NavigationView {
            List {
                // Viajes actuales
                if !currentTrips.isEmpty {
                    Section {
                        ForEach(currentTrips) { trip in
                            TripRowView(trip: trip, tripService: tripService)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                        }
                        .onDelete { indexSet in
                            deleteTrips(from: currentTrips, at: indexSet)
                        }
                    } header: {
                        Label("En curso", systemImage: "location.fill")
                    }
                }

                // Viajes futuros
                if !futureTrips.isEmpty {
                    Section {
                        ForEach(futureTrips) { trip in
                            TripRowView(trip: trip, tripService: tripService)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                        }
                        .onDelete { indexSet in
                            deleteTrips(from: futureTrips, at: indexSet)
                        }
                    } header: {
                        Label("Próximos", systemImage: "calendar")
                    }
                }

                // Viajes pasados
                if !pastTrips.isEmpty {
                    Section {
                        ForEach(pastTrips) { trip in
                            TripRowView(trip: trip, tripService: tripService, isPast: true)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTrip = trip
                                }
                        }
                        .onDelete { indexSet in
                            deleteTrips(from: pastTrips, at: indexSet)
                        }
                    } header: {
                        Label("Pasados", systemImage: "clock.arrow.circlepath")
                    }
                }

                // Estado vacío
                if tripService.trips.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "suitcase")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)

                            Text("No tienes viajes")
                                .font(.headline)

                            Text("Planifica tu primer viaje para tener tus rutas organizadas")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
            }
            .navigationTitle("Mis Viajes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedTrip) { trip in
                TripDetailView(trip: trip, tripService: tripService)
            }
        }
    }

    // MARK: - Computed Properties

    private var currentTrips: [Trip] {
        tripService.trips.filter { $0.isCurrent }
    }

    private var futureTrips: [Trip] {
        tripService.trips
            .filter { $0.isFuture && !$0.isCurrent }
            .sorted { ($0.startDate ?? .distantFuture) < ($1.startDate ?? .distantFuture) }
    }

    private var pastTrips: [Trip] {
        tripService.trips
            .filter { $0.isPast }
            .sorted { ($0.endDate ?? .distantPast) > ($1.endDate ?? .distantPast) }
    }

    // MARK: - Actions

    private func deleteTrips(from trips: [Trip], at indexSet: IndexSet) {
        for index in indexSet {
            let trip = trips[index]
            tripService.deleteTrip(trip.id)
        }
    }
}

// MARK: - Trip Row View
struct TripRowView: View {
    let trip: Trip
    let tripService: TripService
    var isPast: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            // Icono
            Image(systemName: isPast ? "checkmark.circle.fill" : "mappin.circle.fill")
                .font(.title2)
                .foregroundColor(isPast ? .gray : .purple)

            VStack(alignment: .leading, spacing: 4) {
                Text(trip.destinationCity)
                    .font(.headline)
                    .foregroundColor(isPast ? .secondary : .primary)

                HStack(spacing: 8) {
                    Text("\(trip.routeCount) rutas")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if trip.isOfflineAvailable {
                        Label("Offline", systemImage: "arrow.down.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                }

                if let dateRange = trip.dateRangeFormatted {
                    Text(dateRange)
                        .font(.caption)
                        .foregroundColor(isPast ? .secondary : .blue)
                }
            }

            Spacer()

            if trip.isCurrent {
                Text("Ahora")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green))
            }
        }
        .opacity(isPast ? 0.7 : 1.0)
    }
}

#Preview {
    AllTripsView(tripService: TripService())
}
