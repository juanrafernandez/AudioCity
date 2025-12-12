//
//  HistoryView.swift
//  AudioCityPOC
//
//  Vista para mostrar el historial de rutas completadas
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject private var historyService = HistoryService.shared
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationStack {
            Group {
                if historyService.history.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .background(ACColors.background)
            .navigationTitle("Historial")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !historyService.history.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                showingClearConfirmation = true
                            } label: {
                                Label("Borrar historial", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(ACColors.textSecondary)
                        }
                    }
                }
            }
            .alert("Borrar historial", isPresented: $showingClearConfirmation) {
                Button("Cancelar", role: .cancel) { }
                Button("Borrar", role: .destructive) {
                    historyService.clearHistory()
                }
            } message: {
                Text("Se eliminarán todos los registros del historial. Esta acción no se puede deshacer.")
            }
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

                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 48))
                    .foregroundColor(ACColors.primary)
            }

            VStack(spacing: ACSpacing.sm) {
                Text("Sin historial")
                    .font(ACTypography.headlineMedium)
                    .foregroundColor(ACColors.textPrimary)

                Text("Aquí aparecerán las rutas que completes")
                    .font(ACTypography.bodyMedium)
                    .foregroundColor(ACColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ACSpacing.xxl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ACColors.background)
    }

    // MARK: - History List
    private var historyListView: some View {
        ScrollView {
            VStack(spacing: ACSpacing.sectionSpacing) {
                // Stats Section
                statsSection
                    .padding(.horizontal, ACSpacing.containerPadding)

                // History grouped by date
                ForEach(historyService.getHistoryGroupedByDate(), id: \.date) { group in
                    VStack(alignment: .leading, spacing: ACSpacing.md) {
                        // Date header
                        Text(group.date)
                            .font(ACTypography.titleSmall)
                            .foregroundColor(ACColors.textSecondary)
                            .padding(.horizontal, ACSpacing.containerPadding)

                        // Records
                        VStack(spacing: ACSpacing.sm) {
                            ForEach(group.routes) { record in
                                HistoryRecordCard(record: record)
                            }
                        }
                        .padding(.horizontal, ACSpacing.containerPadding)
                    }
                }

                Spacer(minLength: ACSpacing.mega)
            }
            .padding(.top, ACSpacing.base)
        }
        .background(ACColors.background)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        let stats = historyService.getStats()

        return HStack(spacing: 0) {
            HistoryStatItem(
                value: "\(stats.totalRoutes)",
                label: "Rutas",
                icon: "map.fill",
                color: ACColors.primary
            )

            HistoryStatItem(
                value: stats.totalDistanceFormatted,
                label: "Recorrido",
                icon: "figure.walk",
                color: ACColors.secondary
            )

            HistoryStatItem(
                value: stats.totalDurationFormatted,
                label: "Tiempo",
                icon: "clock.fill",
                color: ACColors.info
            )

            HistoryStatItem(
                value: "\(stats.completionRate)%",
                label: "Completado",
                icon: "checkmark.circle.fill",
                color: ACColors.success
            )
        }
        .padding(ACSpacing.md)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }

    private func deleteRecords(from routes: [RouteHistory], at offsets: IndexSet) {
        for index in offsets {
            historyService.deleteRecord(routes[index].id)
        }
    }
}

// MARK: - History Stat Item
struct HistoryStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: ACSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(ACTypography.titleMedium)
                .fontWeight(.bold)
                .foregroundColor(ACColors.textPrimary)

            Text(label)
                .font(ACTypography.captionSmall)
                .foregroundColor(ACColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - History Record Card
struct HistoryRecordCard: View {
    let record: RouteHistory

    var body: some View {
        HStack(spacing: ACSpacing.md) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(ACColors.border, lineWidth: 4)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: CGFloat(record.completionPercentage) / 100)
                    .stroke(
                        record.isCompleted ? ACColors.success : ACColors.warning,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Text("\(record.completionPercentage)%")
                    .font(ACTypography.labelSmall)
                    .fontWeight(.bold)
                    .foregroundColor(record.isCompleted ? ACColors.success : ACColors.warning)
            }

            // Route Info
            VStack(alignment: .leading, spacing: ACSpacing.xs) {
                HStack {
                    Text(record.routeName)
                        .font(ACTypography.titleSmall)
                        .foregroundColor(ACColors.textPrimary)
                        .lineLimit(1)

                    if record.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ACColors.success)
                            .font(.system(size: 14))
                    }
                }

                Text(record.routeCity)
                    .font(ACTypography.caption)
                    .foregroundColor(ACColors.textSecondary)

                HStack(spacing: ACSpacing.md) {
                    ACMetaBadge(icon: "clock", text: record.timeFormatted)
                    ACMetaBadge(icon: "timer", text: record.durationFormatted)
                    ACMetaBadge(icon: "mappin", text: "\(record.stopsVisited)/\(record.totalStops)")
                }
            }

            Spacer()
        }
        .padding(ACSpacing.cardPadding)
        .background(ACColors.surface)
        .cornerRadius(ACRadius.lg)
        .acShadow(ACShadow.sm)
    }
}

#Preview {
    HistoryView()
}
