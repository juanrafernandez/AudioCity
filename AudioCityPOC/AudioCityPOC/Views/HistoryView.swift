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
        NavigationView {
            Group {
                if historyService.history.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .navigationTitle("Historial")
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
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 70))
                .foregroundColor(.gray.opacity(0.5))

            VStack(spacing: 8) {
                Text("Sin historial")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Aquí aparecerán las rutas que completes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - History List
    private var historyListView: some View {
        List {
            // Stats Section
            statsSection

            // History grouped by date
            ForEach(historyService.getHistoryGroupedByDate(), id: \.date) { group in
                Section(group.date) {
                    ForEach(group.routes) { record in
                        HistoryRecordRow(record: record)
                    }
                    .onDelete { offsets in
                        deleteRecords(from: group.routes, at: offsets)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Stats Section
    private var statsSection: some View {
        Section {
            let stats = historyService.getStats()

            HStack(spacing: 0) {
                StatItem(
                    value: "\(stats.totalRoutes)",
                    label: "Rutas",
                    icon: "map"
                )
                Divider()
                    .frame(height: 40)
                StatItem(
                    value: stats.totalDistanceFormatted,
                    label: "Recorrido",
                    icon: "figure.walk"
                )
                Divider()
                    .frame(height: 40)
                StatItem(
                    value: stats.totalDurationFormatted,
                    label: "Tiempo",
                    icon: "clock"
                )
                Divider()
                    .frame(height: 40)
                StatItem(
                    value: "\(stats.completionRate)%",
                    label: "Completado",
                    icon: "checkmark.circle"
                )
            }
            .padding(.vertical, 8)
        }
    }

    private func deleteRecords(from routes: [RouteHistory], at offsets: IndexSet) {
        for index in offsets {
            historyService.deleteRecord(routes[index].id)
        }
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - History Record Row
struct HistoryRecordRow: View {
    let record: RouteHistory

    var body: some View {
        HStack(spacing: 12) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: CGFloat(record.completionPercentage) / 100)
                    .stroke(
                        record.isCompleted ? Color.green : Color.orange,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(record.completionPercentage)%")
                    .font(.caption2)
                    .fontWeight(.bold)
            }

            // Route Info
            VStack(alignment: .leading, spacing: 4) {
                Text(record.routeName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Text(record.routeCity)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 12) {
                    Label(record.timeFormatted, systemImage: "clock")
                    Label(record.durationFormatted, systemImage: "timer")
                    Label("\(record.stopsVisited)/\(record.totalStops)", systemImage: "mappin")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Status indicator
            if record.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}
