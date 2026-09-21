import SwiftUI

struct WorkoutSummaryView: View {
    let session: ShootingSession
    let onDone: () -> Void

    var body: some View {
        List {
            Section {
                Text(session.title).font(.title2.bold())
                Text(session.startedAt, format: .dateTime.month().day().year().hour().minute())
                HStack {
                    StatView(value: "\(session.makes)", label: "Makes")
                    StatView(value: "\(session.attempts)", label: "Attempts")
                    StatView(value: String(format: "%.0f%%", session.percentage), label: "FG%")
                }
            }
            Section("Drills") {
                if session.drills.isEmpty {
                    Text("No focused drills were recorded for this older workout.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(session.drills.sorted(by: { $0.startedAt < $1.startedAt })) { drill in
                        VStack(alignment: .leading) {
                            Text(zone(for: drill.zoneID)?.name ?? "Zone")
                            Text("\(drill.makes)/\(drill.attempts) • \(String(format: "%.0f%%", drill.percentage))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Section {
                Button("Done", action: onDone).frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Workout Summary")
    }
}
