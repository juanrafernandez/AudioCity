//
//  MyRoutesView.swift
//  AudioCityPOC
//
//  Vista para gestionar rutas creadas por el usuario
//

import SwiftUI

struct MyRoutesView: View {
    @ObservedObject private var userRoutesService = UserRoutesService.shared
    @State private var showingCreateRoute = false
    @State private var selectedRoute: UserRoute?

    var body: some View {
        NavigationStack {
            Group {
                if userRoutesService.userRoutes.isEmpty {
                    emptyStateView
                } else {
                    routesListView
                }
            }
            .background(ACColors.background)
            .navigationTitle("Crear")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateRoute = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(ACColors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreateRoute) {
            CreateRouteView()
        }
        .sheet(item: $selectedRoute) { route in
            EditRouteView(route: route)
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: ACSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(ACColors.primaryLight)
                    .frame(width: 120, height: 120)

                Image(systemName: "map.fill")
                    .font(.system(size: 48))
                    .foregroundColor(ACColors.primary)
            }

            VStack(spacing: ACSpacing.sm) {
                Text("No tienes rutas creadas")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text("Crea tu primera ruta y compártela con otros viajeros")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ACSpacing.xxl)
            }

            ACButton("Crear Ruta", icon: "plus.circle.fill", style: .primary, size: .large) {
                showingCreateRoute = true
            }
            .padding(.horizontal, ACSpacing.mega)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ACColors.background)
    }

    // MARK: - Routes List
    private var routesListView: some View {
        ScrollView {
            LazyVStack(spacing: ACSpacing.md) {
                ForEach(userRoutesService.userRoutes) { route in
                    UserRouteCard(route: route)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedRoute = route
                        }
                }
            }
            .padding(ACSpacing.containerPadding)
        }
        .background(ACColors.background)
    }

    private func deleteRoutes(at offsets: IndexSet) {
        for index in offsets {
            let route = userRoutesService.userRoutes[index]
            userRoutesService.deleteRoute(route.id)
        }
    }
}

// MARK: - User Route Card
struct UserRouteCard: View {
    let route: UserRoute

    var body: some View {
        VStack(alignment: .leading, spacing: ACSpacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: ACSpacing.xs) {
                    Text(route.name)
                        .font(ACTypography.titleMedium)
                        .foregroundColor(ACColors.textPrimary)

                    Text("\(route.city)\(route.neighborhood.isEmpty ? "" : ", \(route.neighborhood)")")
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                // Estado de publicación
                ACStatusBadge(
                    text: route.isPublished ? "Publicada" : "Borrador",
                    status: route.isPublished ? .active : .draft
                )
            }

            // Descripción
            if !route.description.isEmpty {
                Text(route.description)
                    .font(ACTypography.bodySmall)
                    .foregroundColor(ACColors.textSecondary)
                    .lineLimit(2)
            }

            // Stats
            HStack(spacing: ACSpacing.lg) {
                ACMetaBadge(icon: "mappin", text: "\(route.numStops) paradas")
                ACMetaBadge(icon: "clock", text: "\(route.estimatedDurationMinutes) min")
                if route.totalDistanceKm > 0 {
                    ACMetaBadge(icon: "figure.walk", text: String(format: "%.1f km", route.totalDistanceKm))
                }
            }

            // Fecha de actualización
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 10))
                Text("Actualizada: \(route.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(ACTypography.captionSmall)
            }
            .foregroundColor(ACColors.textTertiary)
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }
}

// MARK: - Create Route View
struct CreateRouteView: View {
    @ObservedObject private var userRoutesService = UserRoutesService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var city = ""
    @State private var neighborhood = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ACSpacing.xl) {
                    // Información básica
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        Text("Información básica")
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textSecondary)

                        ACTextField(
                            placeholder: "Nombre de la ruta",
                            text: $name,
                            icon: "map"
                        )

                        ACTextField(
                            placeholder: "Ciudad",
                            text: $city,
                            icon: "building.2"
                        )

                        ACTextField(
                            placeholder: "Barrio (opcional)",
                            text: $neighborhood,
                            icon: "mappin.circle"
                        )
                    }

                    // Descripción
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        Text("Descripción")
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textSecondary)

                        TextEditor(text: $description)
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textPrimary)
                            .frame(minHeight: 100)
                            .padding(ACSpacing.sm)
                            .background(ACColors.surface)
                            .cornerRadius(ACRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: ACRadius.md)
                                    .stroke(ACColors.border, lineWidth: 1)
                            )
                    }

                    // Info
                    HStack(spacing: ACSpacing.sm) {
                        Image(systemName: "info.circle")
                            .foregroundColor(ACColors.info)
                        Text("Después de crear la ruta podrás añadir paradas desde el mapa")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textSecondary)
                    }
                    .padding(ACSpacing.md)
                    .background(ACColors.infoLight)
                    .cornerRadius(ACRadius.md)
                }
                .padding(ACSpacing.containerPadding)
            }
            .background(ACColors.background)
            .navigationTitle("Nueva Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(ACColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Crear") {
                        createRoute()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(name.isEmpty || city.isEmpty ? ACColors.textTertiary : ACColors.primary)
                    .disabled(name.isEmpty || city.isEmpty)
                }
            }
        }
    }

    private func createRoute() {
        _ = userRoutesService.createRoute(
            name: name,
            city: city,
            description: description,
            neighborhood: neighborhood
        )
        dismiss()
    }
}

// MARK: - Edit Route View
struct EditRouteView: View {
    let route: UserRoute
    @ObservedObject private var userRoutesService = UserRoutesService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var description: String
    @State private var city: String
    @State private var neighborhood: String
    @State private var showingAddStop = false

    init(route: UserRoute) {
        self.route = route
        _name = State(initialValue: route.name)
        _description = State(initialValue: route.description)
        _city = State(initialValue: route.city)
        _neighborhood = State(initialValue: route.neighborhood)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ACSpacing.xl) {
                    // Información básica
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        Text("Información")
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textSecondary)

                        ACTextField(placeholder: "Nombre", text: $name, icon: "map")
                        ACTextField(placeholder: "Ciudad", text: $city, icon: "building.2")
                        ACTextField(placeholder: "Barrio", text: $neighborhood, icon: "mappin.circle")
                    }

                    // Descripción
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        Text("Descripción")
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textSecondary)

                        TextEditor(text: $description)
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textPrimary)
                            .frame(minHeight: 80)
                            .padding(ACSpacing.sm)
                            .background(ACColors.surface)
                            .cornerRadius(ACRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: ACRadius.md)
                                    .stroke(ACColors.border, lineWidth: 1)
                            )
                    }

                    // Paradas
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        HStack {
                            Text("Paradas (\(route.stops.count))")
                                .font(ACTypography.titleSmall)
                                .foregroundColor(ACColors.textSecondary)

                            Spacer()

                            Button(action: { showingAddStop = true }) {
                                HStack(spacing: ACSpacing.xs) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Añadir")
                                }
                                .font(ACTypography.labelSmall)
                                .foregroundColor(ACColors.primary)
                            }
                        }

                        if route.stops.isEmpty {
                            emptyStopsView
                        } else {
                            VStack(spacing: ACSpacing.sm) {
                                ForEach(route.stops.sorted { $0.order < $1.order }) { stop in
                                    StopEditRow(stop: stop)
                                }
                            }
                        }
                    }

                    // Publicar
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                                Text("Publicar ruta")
                                    .font(ACTypography.titleSmall)
                                    .foregroundColor(ACColors.textPrimary)
                                Text("Las rutas publicadas serán visibles para otros usuarios")
                                    .font(ACTypography.caption)
                                    .foregroundColor(ACColors.textSecondary)
                            }

                            Spacer()

                            Toggle("", isOn: Binding(
                                get: { route.isPublished },
                                set: { _ in userRoutesService.togglePublish(route.id) }
                            ))
                            .tint(ACColors.primary)
                        }
                        .padding(ACSpacing.cardPadding)
                        .background(ACColors.surface)
                        .cornerRadius(ACRadius.md)
                    }

                    // Eliminar
                    Button(role: .destructive) {
                        userRoutesService.deleteRoute(route.id)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Eliminar Ruta")
                        }
                        .font(ACTypography.labelMedium)
                        .foregroundColor(ACColors.error)
                        .frame(maxWidth: .infinity)
                        .padding(ACSpacing.md)
                        .background(ACColors.errorLight)
                        .cornerRadius(ACRadius.md)
                    }
                }
                .padding(ACSpacing.containerPadding)
            }
            .background(ACColors.background)
            .navigationTitle("Editar Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(ACColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(ACColors.primary)
                }
            }
            .sheet(isPresented: $showingAddStop) {
                AddStopView(routeId: route.id)
            }
        }
    }

    private var emptyStopsView: some View {
        Button(action: { showingAddStop = true }) {
            HStack(spacing: ACSpacing.md) {
                ZStack {
                    Circle()
                        .fill(ACColors.primaryLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(ACColors.primary)
                }

                VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                    Text("Añadir primera parada")
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)
                    Text("Define los puntos de interés de tu ruta")
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(ACColors.textTertiary)
            }
            .padding(ACSpacing.cardPadding)
            .background(
                RoundedRectangle(cornerRadius: ACRadius.md)
                    .stroke(ACColors.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [6]))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func saveChanges() {
        var updatedRoute = route
        updatedRoute.name = name
        updatedRoute.description = description
        updatedRoute.city = city
        updatedRoute.neighborhood = neighborhood
        userRoutesService.updateRoute(updatedRoute)
        dismiss()
    }

    private func deleteStops(at offsets: IndexSet) {
        let sortedStops = route.stops.sorted { $0.order < $1.order }
        for index in offsets {
            let stop = sortedStops[index]
            userRoutesService.removeStop(from: route.id, stopId: stop.id)
        }
    }

    private func moveStops(from source: IndexSet, to destination: Int) {
        userRoutesService.reorderStops(in: route.id, from: source, to: destination)
    }
}

// MARK: - Stop Edit Row
struct StopEditRow: View {
    let stop: UserStop

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            ZStack {
                Circle()
                    .fill(ACColors.primary)
                    .frame(width: 32, height: 32)

                Text("\(stop.order)")
                    .font(ACTypography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: ACSpacing.xxs) {
                Text(stop.name)
                    .font(ACTypography.titleSmall)
                    .foregroundColor(ACColors.textPrimary)

                if !stop.description.isEmpty {
                    Text(stop.description)
                        .font(ACTypography.caption)
                        .foregroundColor(ACColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(ACColors.textTertiary)
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.md)
    }
}

// MARK: - Add Stop View
struct AddStopView: View {
    let routeId: String
    @ObservedObject private var userRoutesService = UserRoutesService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var script = ""
    @State private var latitude = ""
    @State private var longitude = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: ACSpacing.xl) {
                    // Información de la parada
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        Text("Información de la parada")
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textSecondary)

                        ACTextField(placeholder: "Nombre", text: $name, icon: "mappin")
                        ACTextField(placeholder: "Descripción breve", text: $description, icon: "text.alignleft")
                    }

                    // Ubicación
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        Text("Ubicación")
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textSecondary)

                        HStack(spacing: ACSpacing.md) {
                            ACTextField(placeholder: "Latitud", text: $latitude, icon: "location")
                            ACTextField(placeholder: "Longitud", text: $longitude, icon: "location")
                        }
                    }

                    // Narración
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        Text("Narración")
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textSecondary)

                        TextEditor(text: $script)
                            .font(ACTypography.bodyMedium)
                            .foregroundColor(ACColors.textPrimary)
                            .frame(minHeight: 150)
                            .padding(ACSpacing.sm)
                            .background(ACColors.surface)
                            .cornerRadius(ACRadius.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: ACRadius.md)
                                    .stroke(ACColors.border, lineWidth: 1)
                            )

                        Text("Escribe el texto que se reproducirá cuando el usuario llegue a esta parada")
                            .font(ACTypography.caption)
                            .foregroundColor(ACColors.textTertiary)
                    }
                }
                .padding(ACSpacing.containerPadding)
            }
            .background(ACColors.background)
            .navigationTitle("Nueva Parada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(ACColors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Añadir") {
                        addStop()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(isValid ? ACColors.primary : ACColors.textTertiary)
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.isEmpty &&
        Double(latitude) != nil &&
        Double(longitude) != nil
    }

    private func addStop() {
        guard let lat = Double(latitude),
              let lon = Double(longitude) else { return }

        let stop = UserStop(
            name: name,
            description: description,
            latitude: lat,
            longitude: lon,
            script: script,
            order: 0 // Se asignará en el servicio
        )

        userRoutesService.addStop(to: routeId, stop: stop)
        dismiss()
    }
}

#Preview {
    MyRoutesView()
}
