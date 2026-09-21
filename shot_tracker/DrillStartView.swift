import SwiftUI
import SwiftData

struct DrillStartView: View {
    @Environment(\.modelContext) private var modelContext
    let session: ShootingSession
    let onStart: (ShootingDrill) -> Void
    @State private var zoneID: Int
    @State private var goal = 0

    init(session: ShootingSession, onStart: @escaping (ShootingDrill) -> Void) {
        self.session = session
        self.onStart = onStart
        _zoneID = State(initialValue: session.selectedZoneIDs.first ?? 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Start a Drill").font(.largeTitle.bold())
                Text("Choose the exact zone for this focused block.").foregroundStyle(.secondary)
                Picker("Zone", selection: $zoneID) {
                    ForEach(session.selectedZoneIDs, id: \.self) { id in
                        Text(zone(for: id)?.name ?? "Zone").tag(id)
                    }
                }
                .pickerStyle(.inline)
                Picker("Attempt goal", selection: $goal) {
                    Text("No goal").tag(0)
                    Text("25 attempts").tag(25)
                    Text("50 attempts").tag(50)
                }
                .pickerStyle(.segmented)
                Button("Start \(zone(for: zoneID)?.name ?? "Drill")") {
                    guard session.selectedZoneIDs.contains(zoneID) else { return }
                    let drill = session.resumableDrill(for: zoneID)
                        ?? ShootingDrill(zoneID: zoneID, session: session, goalAttempts: goal == 0 ? nil : goal)
                    if drill.modelContext == nil {
                        modelContext.insert(drill)
                    }
                    session.makeActive(drill)
                    try? modelContext.save()
                    #if DEBUG
                    print("Start/resume drill — session: \(session.id), zone: \(zoneID), drill: \(drill.id), attempts: \(drill.attempts)")
                    #endif
                    onStart(drill)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(zoneID == 0)
            }.padding()
        }
        .navigationTitle("Drill Setup")
    }
}
