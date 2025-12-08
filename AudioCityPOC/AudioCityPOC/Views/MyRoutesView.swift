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
        NavigationView {
            Group {
                if userRoutesService.userRoutes.isEmpty {
                    emptyStateView
                } else {
                    routesListView
                }
            }
            .navigationTitle("Mis Rutas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateRoute = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
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
        VStack(spacing: 24) {
            Image(systemName: "map.fill")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 8) {
                Text("No tienes rutas creadas")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Crea tu primera ruta y compártela con otros viajeros")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: { showingCreateRoute = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Crear Ruta")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.blue))
            }
        }
    }

    // MARK: - Routes List
    private var routesListView: some View {
        List {
            ForEach(userRoutesService.userRoutes) { route in
                UserRouteCard(route: route)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedRoute = route
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteRoutes)
        }
        .listStyle(.plain)
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
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(route.name)
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("\(route.city)\(route.neighborhood.isEmpty ? "" : ", \(route.neighborhood)")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Estado de publicación
                if route.isPublished {
                    Text("Publicada")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                } else {
                    Text("Borrador")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                }
            }

            // Descripción
            if !route.description.isEmpty {
                Text(route.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Stats
            HStack(spacing: 16) {
                Label("\(route.numStops) paradas", systemImage: "mappin")
                Label("\(route.estimatedDurationMinutes) min", systemImage: "clock")
                if route.totalDistanceKm > 0 {
                    Label(String(format: "%.1f km", route.totalDistanceKm), systemImage: "figure.walk")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            // Fecha de actualización
            Text("Actualizada: \(route.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
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
            Form {
                Section("Información básica") {
                    TextField("Nombre de la ruta", text: $name)
                    TextField("Ciudad", text: $city)
                    TextField("Barrio (opcional)", text: $neighborhood)
                }

                Section("Descripción") {
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }

                Section {
                    Text("Después de crear la ruta podrás añadir paradas desde el mapa")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Nueva Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Crear") {
                        createRoute()
                    }
                    .fontWeight(.bold)
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
            List {
                // Información básica
                Section("Información") {
                    TextField("Nombre", text: $name)
                    TextField("Ciudad", text: $city)
                    TextField("Barrio", text: $neighborhood)
                }

                Section("Descripción") {
                    TextEditor(text: $description)
                        .frame(minHeight: 80)
                }

                // Paradas
                Section {
                    if route.stops.isEmpty {
                        Button(action: { showingAddStop = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Añadir primera parada")
                            }
                        }
                    } else {
                        ForEach(route.stops.sorted { $0.order < $1.order }) { stop in
                            HStack {
                                Text("\(stop.order)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Circle().fill(Color.blue))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(stop.name)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    if !stop.description.isEmpty {
                                        Text(stop.description)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: deleteStops)
                        .onMove(perform: moveStops)

                        Button(action: { showingAddStop = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                Text("Añadir parada")
                            }
                        }
                    }
                } header: {
                    Text("Paradas (\(route.stops.count))")
                }

                // Publicar
                Section {
                    Toggle("Ruta publicada", isOn: Binding(
                        get: { route.isPublished },
                        set: { _ in userRoutesService.togglePublish(route.id) }
                    ))
                } footer: {
                    Text("Las rutas publicadas serán visibles para otros usuarios")
                }

                // Eliminar
                Section {
                    Button(role: .destructive) {
                        userRoutesService.deleteRoute(route.id)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Eliminar Ruta")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Editar Ruta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveChanges()
                    }
                    .fontWeight(.bold)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $showingAddStop) {
                AddStopView(routeId: route.id)
            }
        }
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
            Form {
                Section("Información de la parada") {
                    TextField("Nombre", text: $name)
                    TextField("Descripción breve", text: $description)
                }

                Section("Ubicación") {
                    TextField("Latitud", text: $latitude)
                        .keyboardType(.decimalPad)
                    TextField("Longitud", text: $longitude)
                        .keyboardType(.decimalPad)
                }

                Section {
                    TextEditor(text: $script)
                        .frame(minHeight: 150)
                } header: {
                    Text("Narración")
                } footer: {
                    Text("Escribe el texto que se reproducirá cuando el usuario llegue a esta parada")
                }
            }
            .navigationTitle("Nueva Parada")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Añadir") {
                        addStop()
                    }
                    .fontWeight(.bold)
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
