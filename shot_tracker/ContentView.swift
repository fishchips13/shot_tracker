import SwiftUI
import SwiftData

enum WorkoutFlowStep: Hashable {
    case home
    case chooseZones
    case activeDrill(drillID: UUID, previousDrillID: UUID?)
    case workoutSummary(sessionID: UUID)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShootingSession.startedAt, order: .reverse) private var sessions: [ShootingSession]
    @State private var path: [WorkoutFlowStep] = []
    @State private var didRouteInitialWorkout = false
    @State private var showDelete = false
    @State private var showFinishWorkout = false
    @State private var finishingSessionID: UUID?

    private var unfinishedSession: ShootingSession? {
        sessions.first(where: { $0.status != .completed && $0.endedAt == nil })
    }

    private var completedSessions: [ShootingSession] {
        sessions.filter { $0.status == .completed || $0.endedAt != nil }
    }

    var body: some View {
        TabView {
            NavigationStack(path: $path) {
                dashboard
                    .navigationDestination(for: WorkoutFlowStep.self, destination: destination)
            }
            .tabItem { Label("Track", systemImage: "basketball.fill") }

            NavigationStack { HistoryView() }
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }

            NavigationStack { ZoneStatsView() }
                .tabItem { Label("Stats", systemImage: "chart.bar") }
        }
        .tint(.orange)
        .task {
            routeInitialWorkoutIfNeeded()
        }
        .alert("Delete unfinished workout?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Workout", role: .destructive) { deleteUnfinishedWorkout() }
        } message: {
            Text("This will remove the workout and its recorded shots.")
        }
        .confirmationDialog("Finish workout?", isPresented: $showFinishWorkout, titleVisibility: .visible) {
            Button("Keep Shooting", role: .cancel) { }
            Button("Finish Workout", role: .destructive) { finishWorkout() }
        } message: {
            if let session = session(for: finishingSessionID) {
                Text("\(session.makes) makes on \(session.attempts) attempts, \(String(format: "%.0f%%", session.percentage)).")
            }
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Ready to work?").font(.largeTitle.bold())
                if let latest = completedSessions.first {
                    dashboardCard(latest)
                } else {
                    Text("Log your first workout and build your shot chart.")
                        .foregroundStyle(.secondary)
                }

                Button {
                    path.append(.chooseZones)
                } label: {
                    Label("Start Shooting", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if !completedSessions.isEmpty {
                    Text("Latest session").font(.headline)
                    Text("\(completedSessions.first?.makes ?? 0)/\(completedSessions.first?.attempts ?? 0) • \(String(format: "%.0f%%", completedSessions.first?.percentage ?? 0))")
                        .font(.title3.bold().monospacedDigit())
                }
            }
            .padding()
        }
        .background(Color.orange.opacity(0.035))
        .navigationTitle("Track")
        .toolbar {
            if unfinishedSession != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("End and Delete Workout", role: .destructive) { showDelete = true }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private func dashboardCard(_ session: ShootingSession) -> some View {
        HStack(spacing: 0) {
            dashboardStat("\(session.makes)", "MAKES")
            dashboardStat("\(session.attempts)", "ATTEMPTS")
            dashboardStat(String(format: "%.0f%%", session.percentage), "FG%")
        }
        .padding(.vertical, 16)
        .background(LinearGradient(colors: [.orange, .orange.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func dashboardStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title3.bold().monospacedDigit())
            Text(label).font(.caption2.bold()).opacity(0.85)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func destination(for step: WorkoutFlowStep) -> some View {
        switch step {
        case .home:
            EmptyView()
        case .chooseZones:
            ZoneSelectionView { drill in
                path.append(.activeDrill(drillID: drill.id, previousDrillID: nil))
            }
        case .activeDrill(let id, let previousID):
            if let drill = drill(for: id) {
                ActiveDrillView(
                    drill: drill,
                    previousDrill: previousID.flatMap(drill(for:)),
                    onSwitchToDrill: { target, previous in
                        replaceActiveRoute(with: target, previousDrill: previous)
                    },
                    onEndWorkout: {
                        finishingSessionID = drill.session?.id
                        showFinishWorkout = true
                    }
                )
            } else {
                unavailable("Drill")
            }
        case .workoutSummary(let id):
            if let session = session(for: id) {
                WorkoutSummaryView(session: session) { path = [] }
            } else {
                unavailable("Workout")
            }
        }
    }

    private func routeInitialWorkoutIfNeeded() {
        guard !didRouteInitialWorkout else { return }
        didRouteInitialWorkout = true
        guard let session = unfinishedSession else { return }

        if let drill = session.activeDrill {
            path = [.activeDrill(drillID: drill.id, previousDrillID: nil)]
            return
        }

        guard let zoneID = session.selectedZoneIDs.first else { return }
        let drill = session.resumableDrill(for: zoneID) ?? ShootingDrill(zoneID: zoneID, session: session)
        if drill.modelContext == nil {
            modelContext.insert(drill)
        }
        session.makeActive(drill)
        try? modelContext.save()
        path = [.activeDrill(drillID: drill.id, previousDrillID: nil)]
    }

    private func replaceActiveRoute(with target: ShootingDrill, previousDrill: ShootingDrill?) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(.activeDrill(drillID: target.id, previousDrillID: previousDrill?.id))
    }

    private func unavailable(_ item: String) -> some View {
        ContentUnavailableView("\(item) unavailable", systemImage: "exclamationmark.triangle")
    }

    private func session(for id: UUID?) -> ShootingSession? {
        guard let id else { return nil }
        return sessions.first(where: { $0.id == id })
    }

    private func drill(for id: UUID) -> ShootingDrill? {
        sessions.flatMap(\.drills).first(where: { $0.id == id })
    }

    private func deleteUnfinishedWorkout() {
        guard let session = unfinishedSession else { return }
        modelContext.delete(session)
        try? modelContext.save()
        path = []
    }

    private func finishWorkout() {
        guard let session = session(for: finishingSessionID) else { return }
        if let activeDrill = session.activeDrill {
            activeDrill.statusRaw = DrillStatus.completed.rawValue
            activeDrill.endedAt = Date()
        }
        session.statusRaw = SessionStatus.completed.rawValue
        session.endedAt = Date()
        try? modelContext.save()
        path = [.workoutSummary(sessionID: session.id)]
        finishingSessionID = nil
    }
}

struct StatView: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.title3.bold().monospacedDigit())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
