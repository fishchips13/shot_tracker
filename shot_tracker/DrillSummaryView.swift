import SwiftUI

struct DrillSummaryView: View {
    let drill: ShootingDrill
    let onSwitchToZone: (Int) -> Void
    let onAnother: () -> Void
    let onFinishWorkout: () -> Void

    private var otherZoneID: Int? {
        drill.session?.selectedZoneIDs.first(where: { $0 != drill.zoneID })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: drill.goalAttempts == nil ? "basketball.fill" : "checkmark.seal.fill")
                    .font(.system(size: 54)).foregroundStyle(zoneColor)
                Text(drill.goalAttempts == nil ? "Drill Complete" : "Goal Complete")
                    .font(.largeTitle.bold())
                summaryCard
                if let otherZoneID {
                    Button("Switch to \(zone(for: otherZoneID)?.shortName ?? "Other Zone")") {
                        onSwitchToZone(otherZoneID)
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .frame(maxWidth: .infinity)
                } else {
                    Button("Finish Workout", action: onFinishWorkout)
                        .buttonStyle(.borderedProminent).controlSize(.large)
                        .frame(maxWidth: .infinity)
                }
                if otherZoneID != nil {
                    Button("Finish Workout", action: onFinishWorkout)
                        .buttonStyle(.bordered)
                } else {
                    Button("Start Another Drill", action: onAnother)
                        .buttonStyle(.bordered)
                }
            }.padding()
        }
        .background(Color.orange.opacity(0.04))
        .navigationBarBackButtonHidden()
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            Text(zone(for: drill.zoneID)?.name ?? "Zone").font(.title2.bold())
            HStack(spacing: 0) {
                StatView(value: "\(drill.makes)", label: "MAKES")
                StatView(value: "\(drill.attempts)", label: "ATTEMPTS")
                StatView(value: String(format: "%.0f%%", drill.percentage), label: "FG%")
            }
            .padding(.vertical, 6)
            if let goal = drill.goalAttempts {
                Label("\(goal)-shot goal complete", systemImage: "target")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(zoneColor)
            }
            if let streak = bestMakeStreak {
                Text("Best make streak: \(streak)").font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(22).frame(maxWidth: .infinity)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(zoneColor.opacity(0.35), lineWidth: 2) }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
    }

    private var bestMakeStreak: Int? {
        let values = drill.shots.sorted { $0.timestamp < $1.timestamp }.map(\.result)
        var best = 0
        var current = 0
        for value in values {
            current = value == ShotResult.make.rawValue ? current + 1 : 0
            best = max(best, current)
        }
        return best > 1 ? best : nil
    }

    private var zoneColor: Color {
        switch zone(for: drill.zoneID)?.category {
        case .three: .blue
        case .paint: .red
        default: .orange
        }
    }
}
