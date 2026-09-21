import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ShootingSession.startedAt, order: .reverse) private var sessions: [ShootingSession]

    private var completed: [ShootingSession] {
        sessions.filter { $0.status == .completed || $0.endedAt != nil }
    }
    private var attempts: Int { completed.reduce(0) { $0 + $1.attempts } }
    private var makes: Int { completed.reduce(0) { $0 + $1.makes } }
    private var percentage: Double { attempts == 0 ? 0 : Double(makes) / Double(attempts) * 100 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                if completed.isEmpty {
                    ContentUnavailableView("No Completed Workouts", systemImage: "basketball", description: Text("Finish a workout to build your training feed."))
                        .frame(maxWidth: .infinity).padding(.top, 45)
                } else {
                    Text("Recent Workouts").font(.title3.bold()).padding(.horizontal, 4)
                    LazyVStack(spacing: 12) {
                        ForEach(completed) { session in
                            NavigationLink {
                                WorkoutSummaryView(session: session, onDone: { })
                            } label: {
                                workoutCard(session)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }.padding()
        }
        .background(Color.orange.opacity(0.035))
        .navigationTitle("History")
    }

    private var header: some View {
        HStack(spacing: 0) {
            headerStat("\(completed.count)", "WORKOUTS")
            headerStat("\(attempts)", "ATTEMPTS")
            headerStat(String(format: "%.0f%%", percentage), "CAREER FG%")
        }
        .padding(.vertical, 16)
        .background(LinearGradient(colors: [.orange, .orange.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func headerStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.bold().monospacedDigit())
            Text(label).font(.caption2.bold()).opacity(0.85)
        }.frame(maxWidth: .infinity)
    }

    private func workoutCard(_ session: ShootingSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(session.startedAt, format: .dateTime.month(.abbreviated).day().year())
                        .font(.headline)
                    Text(durationText(for: session)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Text(String(format: "%.0f%%", session.percentage))
                    .font(.title3.bold().monospacedDigit()).foregroundStyle(.orange)
            }
            HStack {
                Label("\(session.makes)/\(session.attempts)", systemImage: "basketball.fill")
                Spacer()
                Text("FG%").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            }.font(.subheadline.weight(.semibold))
            HStack {
                ForEach(session.selectedZoneIDs.prefix(2), id: \.self) { id in
                    Text(zone(for: id)?.shortName ?? "Zone")
                        .font(.caption.bold()).lineLimit(1)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(zoneColor(id).opacity(0.15))
                        .foregroundStyle(zoneColor(id))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16).background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.07), radius: 8, y: 4)
    }

    private func durationText(for session: ShootingSession) -> String {
        guard let end = session.endedAt else { return "Workout" }
        return Duration.seconds(end.timeIntervalSince(session.startedAt)).formatted(.units(allowed: [.minutes]))
    }

    private func zoneColor(_ id: Int) -> Color {
        switch zone(for: id)?.category {
        case .three: .blue
        case .paint: .red
        default: .orange
        }
    }
}
