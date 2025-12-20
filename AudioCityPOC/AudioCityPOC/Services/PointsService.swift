//
//  PointsService.swift
//  AudioCityPOC
//
//  Servicio para gestionar el sistema de puntos y niveles
//

import Foundation
import Combine

class PointsService: ObservableObject, PointsServiceProtocol {

    // MARK: - Singleton
    static let shared = PointsService()

    // MARK: - Published Properties
    @Published var stats: UserPointsStats = UserPointsStats()
    @Published var transactions: [PointsTransaction] = []
    @Published var recentLevelUp: UserLevel? = nil

    // MARK: - Dependencies
    private let repository: PointsRepositoryProtocol

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(repository: PointsRepositoryProtocol = PointsRepository()) {
        self.repository = repository
        loadData()
        checkAndResetDailyStats()
        setupEventSubscriptions()
    }

    deinit {
        cancellables.removeAll()
        Log("PointsService deinit", level: .debug, category: .points)
    }

    // MARK: - Event Subscriptions

    /// Suscribirse a eventos del EventBus
    private func setupEventSubscriptions() {
        // Escuchar eventos de ruta completada
        EventBus.shared.routeEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .routeCompleted(let routeId, let routeName):
                    self?.awardPointsForCompletingRoute(routeId: routeId, routeName: routeName)
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // Escuchar eventos de rutas de usuario
        EventBus.shared.userRouteEvents
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .routeCreated(let routeId, let routeName, let stopsCount):
                    self?.awardPointsForCreatingRoute(routeId: routeId, routeName: routeName, stopsCount: stopsCount)
                case .routePublished(let routeId, let routeName):
                    self?.awardPointsForPublishingRoute(routeId: routeId, routeName: routeName)
                case .routeUsedByOther(let routeId, let routeName):
                    self?.awardPointsForRouteUsedByOther(routeId: routeId, routeName: routeName)
                }
            }
            .store(in: &cancellables)

        Log("Suscrito a eventos", level: .debug, category: .points)
    }

    /// Otorgar puntos cuando otro usuario usa una de tus rutas
    func awardPointsForRouteUsedByOther(routeId: String, routeName: String) {
        let transaction = PointsTransaction(
            action: .routeUsedByOthers,
            routeId: routeId,
            routeName: routeName
        )
        addTransaction(transaction)
        Log("+\(PointsAction.routeUsedByOthers.points) pts - tu ruta '\(routeName)' fue usada", level: .success, category: .points)
    }

    // MARK: - Public Methods

    /// Otorgar puntos por crear una ruta
    func awardPointsForCreatingRoute(routeId: String, routeName: String, stopsCount: Int) {
        guard stopsCount >= 3 else {
            Log("Ruta con menos de 3 paradas, no se otorgan puntos", level: .warning, category: .points)
            return
        }

        let action: PointsAction
        if stopsCount >= 10 {
            action = .createRouteLarge
        } else if stopsCount >= 5 {
            action = .createRouteMedium
        } else {
            action = .createRouteSmall
        }

        let transaction = PointsTransaction(
            action: action,
            routeId: routeId,
            routeName: routeName
        )

        addTransaction(transaction)
        stats.routesCreated += 1

        Log("+\(action.points) pts por crear ruta '\(routeName)' (\(stopsCount) paradas)", level: .success, category: .points)
    }

    /// Otorgar puntos por publicar una ruta
    func awardPointsForPublishingRoute(routeId: String, routeName: String) {
        let transaction = PointsTransaction(
            action: .publishRoute,
            routeId: routeId,
            routeName: routeName
        )

        addTransaction(transaction)
        Log("+\(PointsAction.publishRoute.points) pts por publicar ruta '\(routeName)'", level: .success, category: .points)
    }

    /// Otorgar puntos por completar una ruta
    func awardPointsForCompletingRoute(routeId: String, routeName: String) {
        // Puntos base por completar
        let baseTransaction = PointsTransaction(
            action: .completeRoute,
            routeId: routeId,
            routeName: routeName
        )
        addTransaction(baseTransaction)
        stats.routesCompleted += 1

        Log("+\(PointsAction.completeRoute.points) pts por completar ruta '\(routeName)'", level: .success, category: .points)

        // Verificar si es la primera ruta del día
        checkFirstRouteOfDay(routeId: routeId, routeName: routeName)

        // Actualizar racha
        updateStreak()
    }

    /// Otorgar puntos cuando alguien usa tu ruta
    func awardPointsForRouteUsage(routeId: String, routeName: String) {
        let transaction = PointsTransaction(
            action: .routeUsedByOthers,
            routeId: routeId,
            routeName: routeName
        )

        addTransaction(transaction)
        Log("+\(PointsAction.routeUsedByOthers.points) pts - Tu ruta '\(routeName)' fue usada", level: .success, category: .points)
    }

    /// Obtener transacciones recientes (últimas N)
    func getRecentTransactions(limit: Int = 10) -> [PointsTransaction] {
        return Array(transactions.prefix(limit))
    }

    /// Obtener transacciones agrupadas por fecha
    func getTransactionsGroupedByDate() -> [(date: String, transactions: [PointsTransaction])] {
        let grouped = Dictionary(grouping: transactions) { $0.dateFormatted }

        return grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.transactions.first?.date ?? Date() > $1.transactions.first?.date ?? Date() }
    }

    /// Limpiar notificación de level up
    func clearLevelUpNotification() {
        recentLevelUp = nil
    }

    // MARK: - Private Methods

    private func addTransaction(_ transaction: PointsTransaction) {
        transactions.insert(transaction, at: 0)

        let previousLevel = stats.currentLevel
        stats.totalPoints += transaction.points
        stats.currentLevel = UserLevel.level(for: stats.totalPoints)
        stats.lastActivityDate = Date()

        // Verificar si subió de nivel
        if stats.currentLevel.rawValue > previousLevel.rawValue {
            recentLevelUp = stats.currentLevel
            Log("¡Subiste a nivel \(stats.currentLevel.name)!", level: .success, category: .points)
        }

        saveData()
    }

    private func checkFirstRouteOfDay(routeId: String, routeName: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = try? repository.loadLastCompletionDate()
        let lastCompletionDay = lastDate.map { Calendar.current.startOfDay(for: $0) }

        if lastCompletionDay != today {
            // Es la primera ruta del día
            let transaction = PointsTransaction(
                action: .firstRouteOfDay,
                routeId: routeId,
                routeName: routeName
            )
            addTransaction(transaction)
            Log("+\(PointsAction.firstRouteOfDay.points) pts - Primera ruta del día", level: .success, category: .points)
        }

        try? repository.saveLastCompletionDate(Date())
    }

    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!

        if let lastActivity = stats.lastActivityDate {
            let lastActivityDay = Calendar.current.startOfDay(for: lastActivity)

            if lastActivityDay == yesterday {
                // Continúa la racha
                stats.currentStreak += 1
            } else if lastActivityDay != today {
                // Se rompió la racha
                stats.currentStreak = 1
            }
            // Si es el mismo día, no cambia la racha
        } else {
            stats.currentStreak = 1
        }

        // Actualizar racha más larga
        if stats.currentStreak > stats.longestStreak {
            stats.longestStreak = stats.currentStreak
        }

        // Verificar bonos de racha
        checkStreakBonuses()

        saveData()
    }

    private func checkStreakBonuses() {
        // Bonus por racha de 3 días
        if stats.currentStreak == 3 {
            let transaction = PointsTransaction(action: .streakThreeDays)
            addTransaction(transaction)
            Log("+\(PointsAction.streakThreeDays.points) pts - ¡Racha de 3 días!", level: .success, category: .points)
        }

        // Bonus por racha de 7 días
        if stats.currentStreak == 7 {
            let transaction = PointsTransaction(action: .streakSevenDays)
            addTransaction(transaction)
            Log("+\(PointsAction.streakSevenDays.points) pts - ¡Racha de 7 días!", level: .success, category: .points)
        }
    }

    private func checkAndResetDailyStats() {
        let today = Calendar.current.startOfDay(for: Date())

        if let lastActivity = stats.lastActivityDate {
            let lastActivityDay = Calendar.current.startOfDay(for: lastActivity)
            let daysDifference = Calendar.current.dateComponents([.day], from: lastActivityDay, to: today).day ?? 0

            // Si pasaron más de 1 día, resetear racha
            if daysDifference > 1 {
                stats.currentStreak = 0
                saveData()
            }
        }
    }

    // MARK: - Persistence

    private func loadData() {
        do {
            stats = try repository.loadStats()
            transactions = try repository.loadTransactions()
            Log("Datos cargados - \(stats.totalPoints) pts, Nivel \(stats.currentLevel.name)", level: .info, category: .points)
        } catch {
            Log("Error cargando datos - \(error.localizedDescription)", level: .error, category: .points)
            stats = UserPointsStats()
            transactions = []
        }
    }

    private func saveData() {
        do {
            try repository.saveStats(stats)
            try repository.saveTransactions(transactions)
        } catch {
            Log("Error guardando datos - \(error.localizedDescription)", level: .error, category: .points)
        }
    }
}
