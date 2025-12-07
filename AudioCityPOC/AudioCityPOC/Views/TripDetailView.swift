//
//  TripDetailView.swift
//  AudioCityPOC
//
//  Vista de detalle de un viaje con sus rutas
//

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @ObservedObject var tripService: TripService
    @StateObject private var firebaseService = FirebaseService()
    @Environment(\.dismiss) private var dismiss

    @State private var tripRoutes: [Route] = []
    @State private var isLoading = true
    @State private var showingAddRoutes = false
    @State private var selectedRouteToStart: Route?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header del viaje
                    tripHeader

                    // Estado del viaje
                    tripStatusBadge

                    // Sección de rutas
                    routesSection

                    // Botón añadir rutas
                    addRoutesButton

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle(trip.destinationCity)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            tripService.deleteTrip(trip.id)
                            dismiss()
                        } label: {
                            Label("Eliminar viaje", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .onAppear {
            loadTripRoutes()
        }
        .sheet(isPresented: $showingAddRoutes) {
            AddRoutesToTripView(
                trip: trip,
                tripService: tripService,
                existingRouteIds: Set(trip.selectedRouteIds),
                onRoutesAdded: {
                    loadTripRoutes()
                }
            )
        }
        .sheet(item: $selectedRouteToStart) { route in
            RoutePreviewSheet(route: route, onStart: {
                // TODO: Iniciar ruta
                selectedRouteToStart = nil
            })
        }
    }

    // MARK: - Trip Header
    private var tripHeader: some View {
        VStack(spacing: 12) {
            // Icono de destino
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.purple)

            Text(trip.destinationCity)
                .font(.title)
                .fontWeight(.bold)

            Text(trip.destinationCountry)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Fechas si las tiene
            if let dateRange = trip.dateRangeFormatted {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.purple)
                    Text(dateRange)
                        .font(.subheadline)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.purple.opacity(0.1))
                )
            }
        }
        .padding(.vertical)
    }

    // MARK: - Trip Status Badge
    private var tripStatusBadge: some View {
        HStack(spacing: 16) {
            // Estado
            VStack(spacing: 4) {
                Image(systemName: statusIcon)
                    .font(.title2)
                    .foregroundColor(statusColor)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Rutas
            VStack(spacing: 4) {
                Text("\(trip.routeCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.purple)
                Text("Rutas")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Offline
            VStack(spacing: 4) {
                Image(systemName: trip.isOfflineAvailable ? "checkmark.circle.fill" : "arrow.down.circle")
                    .font(.title2)
                    .foregroundColor(trip.isOfflineAvailable ? .green : .gray)
                Text(trip.isOfflineAvailable ? "Offline" : "Online")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }

    private var statusIcon: String {
        if trip.isCurrent { return "location.fill" }
        if trip.isPast { return "checkmark.circle.fill" }
        return "calendar.badge.clock"
    }

    private var statusColor: Color {
        if trip.isCurrent { return .green }
        if trip.isPast { return .gray }
        return .blue
    }

    private var statusText: String {
        if trip.isCurrent { return "En curso" }
        if trip.isPast { return "Completado" }
        return "Próximo"
    }

    // MARK: - Routes Section
    private var routesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "map.fill")
                    .foregroundColor(.purple)
                Text("Rutas del viaje")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if tripRoutes.isEmpty {
                emptyRoutesView
            } else {
                ForEach(tripRoutes) { route in
                    TripRouteCard(route: route) {
                        selectedRouteToStart = route
                    } onRemove: {
                        removeRoute(route)
                    }
                }
            }
        }
    }

    private var emptyRoutesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("No hay rutas en este viaje")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Añadir rutas") {
                showingAddRoutes = true
            }
            .font(.subheadline)
            .foregroundColor(.purple)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
        )
    }

    // MARK: - Add Routes Button
    private var addRoutesButton: some View {
        Button(action: { showingAddRoutes = true }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Añadir más rutas")
            }
            .font(.headline)
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple, lineWidth: 2)
            )
        }
    }

    // MARK: - Actions
    private func loadTripRoutes() {
        isLoading = true
        Task {
            do {
                let allRoutes = try await firebaseService.fetchAllRoutes()
                await MainActor.run {
                    tripRoutes = allRoutes.filter { trip.selectedRouteIds.contains($0.id) }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func removeRoute(_ route: Route) {
        tripService.removeRoute(route.id, from: trip.id)
        tripRoutes.removeAll { $0.id == route.id }
    }
}

// MARK: - Trip Route Card
struct TripRouteCard: View {
    let route: Route
    let onStart: () -> Void
    let onRemove: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icono
                Image(systemName: "map.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        Label("\(route.durationMinutes) min", systemImage: "clock")
                        Label("\(route.numStops) paradas", systemImage: "mappin")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Botón comenzar
                Button(action: onStart) {
                    Text("Comenzar")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.green))
                }
            }
            .padding()

            // Botón eliminar (sutil)
            HStack {
                Spacer()
                Button(action: onRemove) {
                    HStack(spacing: 4) {
                        Image(systemName: "minus.circle")
                        Text("Quitar del viaje")
                    }
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.8))
                }
                Spacer()
            }
            .padding(.bottom, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Add Routes To Trip View
struct AddRoutesToTripView: View {
    let trip: Trip
    @ObservedObject var tripService: TripService
    let existingRouteIds: Set<String>
    let onRoutesAdded: () -> Void

    @StateObject private var firebaseService = FirebaseService()
    @Environment(\.dismiss) private var dismiss

    @State private var availableRoutes: [Route] = []
    @State private var selectedRouteIds: Set<String> = []
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if availableRoutes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("Ya tienes todas las rutas de \(trip.destinationCity)")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(availableRoutes) { route in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(route.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)

                                    HStack(spacing: 8) {
                                        Label("\(route.durationMinutes) min", systemImage: "clock")
                                        Label("\(route.numStops) paradas", systemImage: "mappin")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: selectedRouteIds.contains(route.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedRouteIds.contains(route.id) ? .purple : .gray)
                                    .font(.title2)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleRoute(route.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Añadir rutas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Añadir") {
                        addSelectedRoutes()
                    }
                    .disabled(selectedRouteIds.isEmpty)
                    .fontWeight(.bold)
                }
            }
        }
        .onAppear {
            loadAvailableRoutes()
        }
    }

    private func toggleRoute(_ routeId: String) {
        if selectedRouteIds.contains(routeId) {
            selectedRouteIds.remove(routeId)
        } else {
            selectedRouteIds.insert(routeId)
        }
    }

    private func loadAvailableRoutes() {
        isLoading = true
        Task {
            do {
                let allRoutes = try await firebaseService.fetchAllRoutes()
                await MainActor.run {
                    // Filtrar por ciudad y excluir las que ya están en el viaje
                    availableRoutes = allRoutes.filter { route in
                        route.city.lowercased() == trip.destinationCity.lowercased() &&
                        !existingRouteIds.contains(route.id)
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func addSelectedRoutes() {
        for routeId in selectedRouteIds {
            tripService.addRoute(routeId, to: trip.id)
        }
        onRoutesAdded()
        dismiss()
    }
}

// MARK: - Route Preview Sheet
struct RoutePreviewSheet: View {
    let route: Route
    let onStart: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Icono
                Image(systemName: "map.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                    .padding(.top, 30)

                // Info
                Text(route.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(route.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Stats
                HStack(spacing: 30) {
                    VStack {
                        Text("\(route.durationMinutes)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("minutos")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text("\(route.numStops)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("paradas")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    VStack {
                        Text(String(format: "%.1f", route.distanceKm))
                            .font(.title)
                            .fontWeight(.bold)
                        Text("km")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Spacer()

                // Botón comenzar
                Button(action: onStart) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Comenzar Ruta")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TripDetailView(
        trip: Trip(
            destinationCity: "Madrid",
            destinationCountry: "España",
            selectedRouteIds: ["route-1", "route-2"],
            startDate: Date(),
            endDate: Date().addingTimeInterval(86400 * 3)
        ),
        tripService: TripService()
    )
}
