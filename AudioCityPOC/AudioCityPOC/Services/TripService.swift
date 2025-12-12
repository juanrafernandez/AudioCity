//
//  TripService.swift
//  AudioCityPOC
//
//  Servicio para gestionar viajes del usuario
//

import Foundation
import Combine

class TripService: ObservableObject {

    // MARK: - Singleton
    static let shared = TripService()

    // MARK: - Published Properties
    @Published var trips: [Trip] = []
    @Published var availableDestinations: [Destination] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Dependencies
    private let repository: TripRepositoryProtocol
    private let firebaseService: FirebaseService

    // MARK: - Initialization
    init(
        repository: TripRepositoryProtocol = TripRepository(),
        firebaseService: FirebaseService = FirebaseService()
    ) {
        self.repository = repository
        self.firebaseService = firebaseService
        loadTrips()
    }

    // MARK: - Public Methods

    /// Crear un nuevo viaje
    /// - Returns: El viaje creado, o nil si ya existe un viaje duplicado
    func createTrip(
        destinationCity: String,
        destinationCountry: String = "España",
        startDate: Date? = nil,
        endDate: Date? = nil
    ) -> Trip? {
        // Validar que no exista un viaje duplicado (mismo destino + mismas fechas)
        if tripExists(city: destinationCity, startDate: startDate, endDate: endDate) {
            print("⚠️ TripService: Ya existe un viaje a \(destinationCity) con esas fechas")
            return nil
        }

        let trip = Trip(
            destinationCity: destinationCity,
            destinationCountry: destinationCountry,
            startDate: startDate,
            endDate: endDate
        )

        trips.append(trip)
        saveTrips()

        print("✅ TripService: Viaje creado - \(destinationCity)")
        return trip
    }

    /// Verificar si ya existe un viaje con el mismo destino y fechas
    func tripExists(city: String, startDate: Date?, endDate: Date?) -> Bool {
        return trips.contains { trip in
            let sameCity = trip.destinationCity.lowercased() == city.lowercased()
            let sameDates = areDatesEqual(trip.startDate, startDate) && areDatesEqual(trip.endDate, endDate)
            return sameCity && sameDates
        }
    }

    /// Comparar fechas (nil == nil es true, y compara solo día/mes/año)
    private func areDatesEqual(_ date1: Date?, _ date2: Date?) -> Bool {
        switch (date1, date2) {
        case (nil, nil):
            return true
        case (let d1?, let d2?):
            let calendar = Calendar.current
            return calendar.isDate(d1, inSameDayAs: d2)
        default:
            return false
        }
    }

    /// Añadir ruta a un viaje
    func addRoute(_ routeId: String, to tripId: String) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else {
            print("❌ TripService: Viaje no encontrado - \(tripId)")
            return
        }

        if !trips[index].selectedRouteIds.contains(routeId) {
            trips[index].selectedRouteIds.append(routeId)
            saveTrips()
            print("✅ TripService: Ruta añadida al viaje")
        }
    }

    /// Eliminar ruta de un viaje
    func removeRoute(_ routeId: String, from tripId: String) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else {
            return
        }

        trips[index].selectedRouteIds.removeAll { $0 == routeId }
        saveTrips()
        print("✅ TripService: Ruta eliminada del viaje")
    }

    /// Eliminar un viaje
    func deleteTrip(_ tripId: String) {
        trips.removeAll { $0.id == tripId }
        saveTrips()
        print("🗑️ TripService: Viaje eliminado")
    }

    /// Actualizar fechas de un viaje
    func updateTripDates(_ tripId: String, startDate: Date?, endDate: Date?) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else {
            return
        }

        trips[index].startDate = startDate
        trips[index].endDate = endDate
        saveTrips()
    }

    /// Marcar viaje como disponible offline
    func markAsOfflineAvailable(_ tripId: String, available: Bool) {
        guard let index = trips.firstIndex(where: { $0.id == tripId }) else {
            return
        }

        trips[index].isOfflineAvailable = available
        if available {
            trips[index].lastSyncDate = Date()
        }
        saveTrips()
    }

    /// Obtener viajes por ciudad
    func getTrips(for city: String) -> [Trip] {
        return trips.filter { $0.destinationCity.lowercased() == city.lowercased() }
    }

    /// Obtener viaje por ID
    func getTrip(by id: String) -> Trip? {
        return trips.first { $0.id == id }
    }

    /// Obtener el viaje activo actual (en curso)
    var activeTrip: Trip? {
        return trips.first { $0.isCurrent }
    }

    /// Obtener todos los route IDs de viajes activos (actuales o próximos sin fecha pasada)
    var activeRouteIds: Set<String> {
        let activeTrips = trips.filter { !$0.isPast }
        var routeIds = Set<String>()
        for trip in activeTrips {
            routeIds.formUnion(trip.selectedRouteIds)
        }
        return routeIds
    }

    /// Cargar destinos disponibles desde Firebase
    func loadAvailableDestinations() async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let routes = try await firebaseService.fetchAllRoutes()

            // Agrupar rutas por ciudad
            var cityRouteCount: [String: Int] = [:]
            for route in routes {
                cityRouteCount[route.city, default: 0] += 1
            }

            // Crear destinos
            let destinations = cityRouteCount.map { city, count in
                Destination(
                    id: city.lowercased().replacingOccurrences(of: " ", with: "-"),
                    city: city,
                    routeCount: count,
                    isPopular: count >= 3 // Marcar como popular si tiene 3+ rutas
                )
            }.sorted { $0.routeCount > $1.routeCount }

            await MainActor.run {
                self.availableDestinations = destinations
                self.isLoading = false
                print("✅ TripService: \(destinations.count) destinos disponibles")
            }

        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                print("❌ TripService: Error cargando destinos - \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Private Methods

    private func loadTrips() {
        do {
            trips = try repository.loadTrips()
            print("✅ TripService: \(trips.count) viajes cargados")
        } catch {
            print("❌ TripService: Error cargando viajes - \(error.localizedDescription)")
            trips = []
        }
    }

    private func saveTrips() {
        do {
            try repository.saveTrips(trips)
        } catch {
            print("❌ TripService: Error guardando viajes - \(error.localizedDescription)")
        }
    }
}
