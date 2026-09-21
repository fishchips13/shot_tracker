import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ActiveDrillView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let drill: ShootingDrill
    let previousDrill: ShootingDrill?
    let onSwitchToDrill: (ShootingDrill, ShootingDrill?) -> Void
    let onEndWorkout: () -> Void

    @State private var savingShot = false
    @State private var showFinishConfirmation = false
    @State private var showCompletionSheet = false
    @State private var showSwitchUndo = false
    @State private var feedbackBadge: String?

    private var session: ShootingSession? { drill.session }
    private var activeZone: CourtZone? { zone(for: drill.zoneID) }
    private var hasGoal: Bool { drill.goalAttempts != nil }
    private var goalReached: Bool {
        guard let goal = drill.goalAttempts else { return false }
        return drill.attempts >= goal
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                trackerHeader

                if let session, session.selectedZoneIDs.count == 2 {
                    zoneSwitcher(session)
                }

                compactCourt
                scoreCard

                if let goal = drill.goalAttempts {
                    goalProgress(goal)
                }

                shotControls

                if !drill.shots.isEmpty {
                    Button("Undo Last Shot") { undoLastShot() }
                        .buttonStyle(.bordered)
                        .disabled(savingShot)
                }

                if let streakText {
                    Text(streakText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Button("Finish Drill") { showFinishConfirmation = true }
                    .buttonStyle(.bordered)
            }
            .padding()
        }
        .background(Color.orange.opacity(0.035))
        .navigationTitle("Live Tracker")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Finish Workout", role: .destructive) { onEndWorkout() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .overlay(alignment: .top) {
            if let feedbackBadge {
                Text(feedbackBadge)
                    .font(.headline.bold())
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    .padding(.top, 8)
                    .accessibilityAddTraits(.isStaticText)
            }
        }
        .confirmationDialog("Finish \(activeZone?.name ?? "this") drill?", isPresented: $showFinishConfirmation, titleVisibility: .visible) {
            Button("Keep Shooting", role: .cancel) { }
            Button("Finish Drill") {
                finishCurrentDrill()
                showCompletionSheet = true
            }
        } message: {
            Text("\(drill.makes) makes on \(drill.attempts) attempts.")
        }
        .sheet(isPresented: $showCompletionSheet) {
            completionSheet
                .presentationDetents([.height(session?.selectedZoneIDs.count == 2 ? 310 : 240)])
                .presentationDragIndicator(.visible)
        }
        .overlay(alignment: .bottom) {
            if showSwitchUndo, let previousDrill {
                HStack {
                    Text("Switched to \(activeZone?.shortName ?? "zone")")
                    Spacer()
                    Button("Undo") { undoSwitch(to: previousDrill) }
                        .fontWeight(.bold)
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: 8)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityElement(children: .combine)
            }
        }
        .task {
            if previousDrill != nil {
                withAnimation(reduceMotion ? .easeOut : .spring) {
                    showSwitchUndo = true
                }
                try? await Task.sleep(for: .seconds(4))
                withAnimation { showSwitchUndo = false }
            }
        }
    }

    private var trackerHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(zoneColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(activeZone?.name ?? "Zone")
                    .font(.title3.bold())
                Text("ZONE LOCKED")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tracking locked to \(activeZone?.name ?? "active zone")")
    }

    private var compactCourt: some View {
        CourtDiagramView(
            mode: .trackingLocked,
            selectedZoneIDs: Set(session?.selectedZoneIDs ?? []),
            activeZoneID: drill.zoneID,
            onZoneTapped: { _ in }
        )
        .frame(maxHeight: 150)
        .accessibilityLabel("Locked court, active zone \(activeZone?.name ?? "unknown")")
    }

    private var scoreCard: some View {
        HStack(spacing: 0) {
            scoreStat("\(drill.makes)", "MAKES")
            scoreStat("\(drill.attempts)", "ATTEMPTS")
            scoreStat(String(format: "%.0f%%", drill.percentage), "FG%")
        }
        .padding(.vertical, 14)
        .background(LinearGradient(colors: [zoneColor.opacity(0.9), zoneColor.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func scoreStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title.bold().monospacedDigit())
                .contentTransition(.numericText())
            Text(label).font(.caption2.bold()).opacity(0.82)
        }
        .frame(maxWidth: .infinity)
    }

    private func goalProgress(_ goal: Int) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Goal")
                Spacer()
                Text("\(drill.attempts) / \(goal)")
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            ProgressView(value: min(Double(drill.attempts) / Double(goal), 1))
                .tint(zoneColor)
                .scaleEffect(y: 1.7)
                .padding(.vertical, 4)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var shotControls: some View {
        HStack(spacing: 14) {
            shotButton("MISS", icon: "xmark", color: .red) { record(.miss) }
            shotButton("MAKE", icon: "checkmark", color: .green) { record(.make) }
        }
    }

    private func shotButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .frame(height: 98)
                .background(color)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
        .disabled(savingShot || goalReached)
        .accessibilityLabel("\(title), record in \(activeZone?.name ?? "active zone")")
    }

    private func zoneSwitcher(_ session: ShootingSession) -> some View {
        HStack(spacing: 8) {
            ForEach(session.selectedZoneIDs, id: \.self) { id in
                let isActive = id == drill.zoneID
                Button {
                    switchImmediately(to: id)
                } label: {
                    Text("\(zone(for: id)?.shortName ?? "Zone") · \(zoneTotals(for: id).makes)/\(zoneTotals(for: id).attempts)")
                        .font(.caption.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(isActive ? zoneColor : Color.primary.opacity(0.08))
                        .foregroundStyle(isActive ? .white : .primary)
                        .clipShape(Capsule())
                }
                .disabled(isActive || savingShot)
                .accessibilityLabel("\(zone(for: id)?.name ?? "Zone")\(isActive ? ", active" : ", switch to this zone")")
            }
        }
        .padding(5)
        .background(Color.primary.opacity(0.05))
        .clipShape(Capsule())
    }

    private var completionSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(zoneColor)
            Text(hasGoal ? "Goal complete" : "Drill complete")
                .font(.title2.bold())
            Text("\(drill.makes)/\(drill.attempts) • \(String(format: "%.0f%%", drill.percentage))")
                .foregroundStyle(.secondary)

            if let nextZoneID = session?.selectedZoneIDs.first(where: { $0 != drill.zoneID }) {
                Button("Next: \(zone(for: nextZoneID)?.shortName ?? "Zone")") {
                    showCompletionSheet = false
                    switchImmediately(to: nextZoneID)
                }
                .buttonStyle(.borderedProminent)
            }

            HStack {
                Button("Keep Shooting") {
                    resumeOpenShooting()
                    showCompletionSheet = false
                }
                .buttonStyle(.bordered)

                Button("Finish Workout") {
                    showCompletionSheet = false
                    onEndWorkout()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .multilineTextAlignment(.center)
    }

    private var streakText: String? {
        let ordered = drill.shots.sorted { $0.timestamp < $1.timestamp }
        guard let last = ordered.last else { return nil }
        let count = ordered.reversed().prefix { $0.result == last.result }.count
        guard count >= 2 else { return nil }
        return last.result == ShotResult.make.rawValue ? "\(count) make streak" : "\(count) misses in a row"
    }

    private var zoneColor: Color {
        switch activeZone?.category {
        case .three: .blue
        case .paint: .red
        default: .orange
        }
    }

    private func zoneTotals(for zoneID: Int) -> (makes: Int, attempts: Int) {
        let drills = session?.drills.filter { $0.zoneID == zoneID } ?? []
        return (drills.reduce(0) { $0 + $1.makes }, drills.reduce(0) { $0 + $1.attempts })
    }

    private func record(_ result: ShotResult) {
        guard drill.isActive, !savingShot, !goalReached, let session else { return }
        savingShot = true
        let shot = Shot(zone: drill.zoneID, result: result, session: session, drill: drill)
        modelContext.insert(shot)
        try? modelContext.save()

        #if canImport(UIKit)
        result == .make ? UINotificationFeedbackGenerator().notificationOccurred(.success) : UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .bouncy) {
            feedbackBadge = result == .make ? "+1 MAKE" : "MISS"
        }

        if let goal = drill.goalAttempts, drill.attempts == goal {
            finishCurrentDrill()
            feedbackBadge = "GOAL COMPLETE ✓"
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.15 : 0.55)) {
                showCompletionSheet = true
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { feedbackBadge = nil }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                savingShot = false
            }
        }
    }

    private func undoLastShot() {
        guard let shot = drill.shots.max(by: { $0.timestamp < $1.timestamp }) else { return }
        modelContext.delete(shot)
        try? modelContext.save()
    }

    private func switchImmediately(to zoneID: Int) {
        guard zoneID != drill.zoneID, let session, session.selectedZoneIDs.contains(zoneID) else { return }
        let target = session.resumableDrill(for: zoneID) ?? ShootingDrill(zoneID: zoneID, session: session)
        if target.modelContext == nil {
            modelContext.insert(target)
        }
        drill.statusRaw = DrillStatus.completed.rawValue
        drill.endedAt = Date()
        session.makeActive(target)
        try? modelContext.save()
        onSwitchToDrill(target, drill)
    }

    private func undoSwitch(to prior: ShootingDrill) {
        guard let session, prior.session?.id == session.id else { return }
        drill.statusRaw = DrillStatus.completed.rawValue
        drill.endedAt = Date()
        session.makeActive(prior)
        try? modelContext.save()
        onSwitchToDrill(prior, nil)
    }

    private func finishCurrentDrill() {
        drill.statusRaw = DrillStatus.completed.rawValue
        drill.endedAt = Date()
        try? modelContext.save()
        savingShot = false
    }

    private func resumeOpenShooting() {
        guard let session else { return }
        drill.goalAttempts = nil
        session.makeActive(drill)
        try? modelContext.save()
    }
}
