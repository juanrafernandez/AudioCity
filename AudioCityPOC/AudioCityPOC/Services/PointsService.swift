//
//  PointsService.swift
//  AudioCityPOC
//
//  Servicio para gestionar el sistema de puntos y niveles
//

import Foundation
import Combine

class PointsService: ObservableObject {

    // MARK: - Singleton
    static let shared = PointsService()

    // MARK: - Published Properties
    @Published var stats: UserPointsStats = UserPointsStats()
    @Published var transactions: [PointsTransaction] = []
    @Published var recentLevelUp: UserLevel? = nil

    // MARK: - Private Properties
    private let userDefaults = UserDefaults.standard
    private let statsKey = "userPointsStats"
    private let transactionsKey = "pointsTransactions"
    private let completedRoutesTodayKey = "completedRoutesToday"
    private let lastCompletionDateKey = "lastRouteCompletionDate"

    // MARK: - Initialization
    init() {
        loadData()
        checkAndResetDailyStats()
    }

    // MARK: - Public Methods

    /// Otorgar puntos por crear una ruta
    func awardPointsForCreatingRoute(routeId: String, routeName: String, stopsCount: Int) {
        guard stopsCount >= 3 else {
            print("⚠️ PointsService: Ruta con menos de 3 paradas, no se otorgan puntos")
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

        print("✅ PointsService: +\(action.points) pts por crear ruta '\(routeName)' (\(stopsCount) paradas)")
    }

    /// Otorgar puntos por publicar una ruta
    func awardPointsForPublishingRoute(routeId: String, routeName: String) {
        let transaction = PointsTransaction(
            action: .publishRoute,
            routeId: routeId,
            routeName: routeName
        )

        addTransaction(transaction)
        print("✅ PointsService: +\(PointsAction.publishRoute.points) pts por publicar ruta '\(routeName)'")
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

        print("✅ PointsService: +\(PointsAction.completeRoute.points) pts por completar ruta '\(routeName)'")

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
        print("✅ PointsService: +\(PointsAction.routeUsedByOthers.points) pts - Tu ruta '\(routeName)' fue usada")
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
            print("🎉 PointsService: ¡Subiste a nivel \(stats.currentLevel.name)!")
        }

        saveData()
    }

    private func checkFirstRouteOfDay(routeId: String, routeName: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = userDefaults.object(forKey: lastCompletionDateKey) as? Date
        let lastCompletionDay = lastDate.map { Calendar.current.startOfDay(for: $0) }

        if lastCompletionDay != today {
            // Es la primera ruta del día
            let transaction = PointsTransaction(
                action: .firstRouteOfDay,
                routeId: routeId,
                routeName: routeName
            )
            addTransaction(transaction)
            print("✅ PointsService: +\(PointsAction.firstRouteOfDay.points) pts - Primera ruta del día")
        }

        userDefaults.set(Date(), forKey: lastCompletionDateKey)
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
            print("🔥 PointsService: +\(PointsAction.streakThreeDays.points) pts - ¡Racha de 3 días!")
        }

        // Bonus por racha de 7 días
        if stats.currentStreak == 7 {
            let transaction = PointsTransaction(action: .streakSevenDays)
            addTransaction(transaction)
            print("🔥 PointsService: +\(PointsAction.streakSevenDays.points) pts - ¡Racha de 7 días!")
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
        // Cargar stats
        if let statsData = userDefaults.data(forKey: statsKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(UserPointsStats.self, from: statsData) {
                stats = decoded
            }
        }

        // Cargar transacciones
        if let transData = userDefaults.data(forKey: transactionsKey) {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode([PointsTransaction].self, from: transData) {
                transactions = decoded
            }
        }

        print("✅ PointsService: Datos cargados - \(stats.totalPoints) pts, Nivel \(stats.currentLevel.name)")
    }

    private func saveData() {
        let encoder = JSONEncoder()

        if let statsData = try? encoder.encode(stats) {
            userDefaults.set(statsData, forKey: statsKey)
        }

        if let transData = try? encoder.encode(transactions) {
            userDefaults.set(transData, forKey: transactionsKey)
        }
    }
}
