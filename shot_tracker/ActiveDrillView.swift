import SwiftUI
import SwiftData
#if canImport(UIKit)
import UIKit
#endif

struct ActiveDrillView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let drill: ShootingDrill
    let onFinish: () -> Void
    let onEndWorkout: () -> Void
    let onSwitchToDrill: (ShootingDrill) -> Void

    @State private var savingShot = false
    @State private var showFinish = false
    @State private var pendingZoneID: Int?
    @State private var showSwitchConfirmation = false
    @State private var feedbackBadge: String?
    @State private var completedGoal = false

    private var session: ShootingSession? { drill.session }
    private var activeZone: CourtZone? { zone(for: drill.zoneID) }
    private var streakText: String? {
        let ordered = drill.shots.sorted { $0.timestamp < $1.timestamp }
        guard let last = ordered.last else { return nil }
        let count = ordered.reversed().prefix { $0.result == last.result }.count
        guard count >= 2 else { return nil }
        return last.result == ShotResult.make.rawValue ? "\(count) make streak" : "\(count) misses in a row"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                if let session, session.selectedZoneIDs.count == 2 {
                    zoneSwitcher(session)
                }
                lockedCourt
                scoreCard
                if let goal = drill.goalAttempts { goalCard(goal) }
                shotControls
                if let streakText {
                    Text(streakText).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
                }
                Button("Undo Last Shot") { undoLastShot() }
                    .buttonStyle(.bordered)
                    .disabled(drill.shots.isEmpty || savingShot)
                Button("Finish Drill") { showFinish = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .background(Color.orange.opacity(0.035))
        .navigationTitle("Live Drill")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("End Workout", role: .destructive) { onEndWorkout() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .overlay(alignment: .top) {
            if let feedbackBadge {
                Text(feedbackBadge)
                    .font(.headline.bold())
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                    .padding(.top, 10)
            }
        }
        .confirmationDialog("Finish \(activeZone?.name ?? "this") drill?", isPresented: $showFinish, titleVisibility: .visible) {
            Button("Keep Tracking", role: .cancel) { }
            Button("Finish Drill") { completeDrill() }
        } message: {
            Text("\(drill.makes) makes on \(drill.attempts) attempts.")
        }
        .confirmationDialog("Switch zones?", isPresented: $showSwitchConfirmation, titleVisibility: .visible) {
            Button("Cancel", role: .cancel) { pendingZoneID = nil }
            Button("Switch") { switchToPendingZone() }
        } message: {
            Text("Your shots stay assigned to \(activeZone?.name ?? "this zone").")
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(zoneColor)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text("Tracking: \(activeZone?.name ?? "Zone")").font(.title3.bold())
                Text("Zone locked").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var lockedCourt: some View {
        CourtDiagramView(mode: .trackingLocked, selectedZoneIDs: Set(session?.selectedZoneIDs ?? []), activeZoneID: drill.zoneID, onZoneTapped: { _ in })
            .frame(maxHeight: 250)
            .accessibilityLabel("Court locked to \(activeZone?.name ?? "active zone")")
    }

    private var scoreCard: some View {
        HStack(spacing: 0) {
            liveStat("\(drill.makes)", "MAKES")
            liveStat("\(drill.attempts)", "ATTEMPTS")
            liveStat(String(format: "%.0f%%", drill.percentage), "FG%")
        }
        .padding(.vertical, 14)
        .background(LinearGradient(colors: [zoneColor.opacity(0.9), zoneColor.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: zoneColor.opacity(0.22), radius: 10, y: 5)
    }

    private func liveStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title.bold().monospacedDigit()).contentTransition(.numericText())
            Text(label).font(.caption2.bold()).opacity(0.82)
        }.frame(maxWidth: .infinity)
    }

    private func goalCard(_ goal: Int) -> some View {
        let progress = min(Double(drill.attempts) / Double(goal), 1)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Attempt goal", systemImage: "target")
                Spacer()
                Text("\(drill.attempts) / \(goal) attempts").monospacedDigit()
            }.font(.subheadline.weight(.semibold))
            ProgressView(value: progress)
                .tint(zoneColor)
                .scaleEffect(y: 1.8)
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
                .frame(maxWidth: .infinity).frame(height: 94)
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
                    requestSwitch(to: id)
                } label: {
                    Text("\(zone(for: id)?.shortName ?? "Zone") · \(zoneTotals(for: id).makes)/\(zoneTotals(for: id).attempts)")
                        .font(.caption.bold()).lineLimit(1).minimumScaleFactor(0.65)
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(isActive ? zoneColor : Color.primary.opacity(0.08))
                        .foregroundStyle(isActive ? .white : .primary)
                        .clipShape(Capsule())
                }
                .disabled(isActive)
                .accessibilityLabel("\(zone(for: id)?.name ?? "Zone")\(isActive ? ", active" : ", switch zone")")
            }
        }
        .padding(5)
        .background(Color.primary.opacity(0.05))
        .clipShape(Capsule())
    }

    private func zoneTotals(for zoneID: Int) -> (makes: Int, attempts: Int) {
        let drills = session?.drills.filter { $0.zoneID == zoneID } ?? []
        return (
            drills.reduce(0) { $0 + $1.makes },
            drills.reduce(0) { $0 + $1.attempts }
        )
    }

    private var goalReached: Bool {
        guard let goal = drill.goalAttempts else { return false }
        return drill.attempts >= goal
    }

    private var zoneColor: Color {
        switch activeZone?.category {
        case .three: .blue
        case .paint: .red
        default: .orange
        }
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
            completedGoal = true
            withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .bouncy) {
                feedbackBadge = "GOAL COMPLETE ✓"
            }
            completeDrill(after: reduceMotion ? 0.15 : 0.7)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                withAnimation { feedbackBadge = nil }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { savingShot = false }
        }
    }

    private func undoLastShot() {
        guard let shot = drill.shots.max(by: { $0.timestamp < $1.timestamp }) else { return }
        modelContext.delete(shot)
        try? modelContext.save()
    }

    private func requestSwitch(to zoneID: Int) {
        guard zoneID != drill.zoneID, session?.selectedZoneIDs.contains(zoneID) == true else { return }
        pendingZoneID = zoneID
        if drill.attempts > 0 {
            showSwitchConfirmation = true
        } else {
            switchToPendingZone()
        }
    }

    private func switchToPendingZone() {
        guard let zoneID = pendingZoneID, let session else { return }
        if drill.isActive {
            drill.statusRaw = DrillStatus.completed.rawValue
            drill.endedAt = Date()
        }
        let target: ShootingDrill
        if let existing = session.resumableDrill(for: zoneID) {
            // Legacy duplicates remain intact; the newest unfinished drill is resumed.
            session.makeActive(existing)
            target = existing
        } else {
            target = ShootingDrill(zoneID: zoneID, session: session)
            modelContext.insert(target)
        }
        try? modelContext.save()
        #if DEBUG
        print("Switch drill — session: \(session.id), target zone: \(zoneID), drill: \(target.id), attempts: \(target.attempts)")
        #endif
        pendingZoneID = nil
        onSwitchToDrill(target)
    }

    private func completeDrill() {
        completeDrill(after: 0)
    }

    private func completeDrill(after delay: TimeInterval) {
        drill.statusRaw = DrillStatus.completed.rawValue
        drill.endedAt = Date()
        try? modelContext.save()
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            onFinish()
        }
    }
}
