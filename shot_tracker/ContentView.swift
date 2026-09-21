import SwiftUI
import SwiftData

enum WorkoutFlowStep: Hashable {
    case home
    case chooseZones
    case chooseFirstDrill(sessionID: UUID)
    case activeDrill(drillID: UUID)
    case drillSummary(drillID: UUID)
    case workoutSummary(sessionID: UUID)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShootingSession.startedAt, order: .reverse) private var sessions: [ShootingSession]
    @State private var path: [WorkoutFlowStep] = []
    @State private var showDelete = false
    @State private var showFinishWorkout = false
    @State private var finishingSessionID: UUID?

    private var unfinishedSession: ShootingSession? {
        sessions.first(where: { $0.status != .completed && $0.endedAt == nil })
    }

    var body: some View {
        TabView {
            NavigationStack(path: $path) {
                home.navigationDestination(for: WorkoutFlowStep.self, destination: destination)
            }
            .tabItem { Label("Track", systemImage: "basketball.fill") }
            NavigationStack { HistoryView() }.tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            NavigationStack { ZoneStatsView() }.tabItem { Label("Stats", systemImage: "chart.bar") }
        }
        .tint(.orange)
        .alert("Delete unfinished workout?", isPresented: $showDelete) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Workout", role: .destructive) { deleteUnfinishedWorkout() }
        } message: {
            Text("This will remove the workout and its recorded shots.")
        }
        .confirmationDialog("Finish workout?", isPresented: $showFinishWorkout, titleVisibility: .visible) {
            Button("Keep Workout Going", role: .cancel) { }
            Button("Finish Workout", role: .destructive) { finishWorkout() }
        } message: {
            if let session = session(for: finishingSessionID) {
                Text("\(session.makes) makes on \(session.attempts) attempts, \(String(format: "%.0f%%", session.percentage)), across \(session.drills.count) drills.")
            }
        }
    }

    private var home: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "basketball.fill").font(.system(size: 76)).foregroundStyle(.orange)
            Text("Shot Tracker").font(.largeTitle.bold())
            Text("Train with focused drills. Every shot stays locked to its court zone.")
                .multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal)
            Button(unfinishedSession == nil ? "Start Workout" : "Resume Workout") { resumeOrStart() }
                .buttonStyle(.borderedProminent).controlSize(.large)
            Spacer()
        }
        .padding().background(Color.orange.opacity(0.035))
        .navigationTitle("Track")
        .toolbar {
            if unfinishedSession != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("End and Delete Workout", role: .destructive) { showDelete = true }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for step: WorkoutFlowStep) -> some View {
        switch step {
        case .home: EmptyView()
        case .chooseZones:
            ZoneSelectionView { session in path.append(.chooseFirstDrill(sessionID: session.id)) }
        case .chooseFirstDrill(let id):
            if let session = session(for: id) {
                DrillStartView(session: session) { drill in path.append(.activeDrill(drillID: drill.id)) }
            } else { unavailable("Workout") }
        case .activeDrill(let id):
            if let drill = drill(for: id) {
                ActiveDrillView(drill: drill, onFinish: { path.append(.drillSummary(drillID: drill.id)) }, onEndWorkout: {
                    finishingSessionID = drill.session?.id
                    showFinishWorkout = true
                }, onSwitchToDrill: { target in
                    path.append(.activeDrill(drillID: target.id))
                })
            } else { unavailable("Drill") }
        case .drillSummary(let id):
            if let drill = drill(for: id) {
                DrillSummaryView(drill: drill, onSwitchToZone: { zoneID in
                    startDrill(in: drill.session, zoneID: zoneID)
                }, onAnother: {
                    if let session = drill.session { path.append(.chooseFirstDrill(sessionID: session.id)) }
                }, onFinishWorkout: {
                    finishingSessionID = drill.session?.id
                    showFinishWorkout = true
                })
            } else { unavailable("Drill") }
        case .workoutSummary(let id):
            if let session = session(for: id) { WorkoutSummaryView(session: session) { path = [] } } else { unavailable("Workout") }
        }
    }

    private func unavailable(_ item: String) -> some View {
        ContentUnavailableView("\(item) unavailable", systemImage: "exclamationmark.triangle")
    }

    private func resumeOrStart() {
        guard let session = unfinishedSession else {
            path.append(.chooseZones)
            return
        }
        if let drill = session.activeDrill {
            path.append(.activeDrill(drillID: drill.id))
        } else if session.selectedZoneIDs.isEmpty {
            path.append(.chooseZones)
        } else {
            path.append(.chooseFirstDrill(sessionID: session.id))
        }
    }

    private func startDrill(in session: ShootingSession?, zoneID: Int) {
        guard let session, session.selectedZoneIDs.contains(zoneID) else { return }
        let drill = session.resumableDrill(for: zoneID) ?? ShootingDrill(zoneID: zoneID, session: session)
        if drill.modelContext == nil {
            modelContext.insert(drill)
        }
        session.makeActive(drill)
        try? modelContext.save()
        path.append(.activeDrill(drillID: drill.id))
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
        }.frame(maxWidth: .infinity)
    }
}
