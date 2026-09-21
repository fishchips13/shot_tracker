import SwiftUI
import SwiftData

struct ZoneSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectionZoneIDs: Set<Int> = []
    @State private var showLimitAlert = false
    @State private var showGoalOptions = false
    @State private var goal = 0
    let onStart: (ShootingDrill) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose Your Zones").font(.largeTitle.bold())
                Text("Pick one or two spots. Start open, add a goal if you want one.")
                    .foregroundStyle(.secondary)

                CourtDiagramView(mode: .selection, selectedZoneIDs: selectionZoneIDs, activeZoneID: nil) { id in
                    if selectionZoneIDs.contains(id) {
                        selectionZoneIDs.remove(id)
                    } else if selectionZoneIDs.count < 2 {
                        selectionZoneIDs.insert(id)
                    } else {
                        showLimitAlert = true
                    }
                }

                if !selectionZoneIDs.isEmpty {
                    FlowLayout(ids: selectionZoneIDs.sorted())
                }

                DisclosureGroup("Attempt goal (optional)", isExpanded: $showGoalOptions) {
                    Picker("Attempt goal", selection: $goal) {
                        Text("Open shooting").tag(0)
                        Text("25 attempts").tag(25)
                        Text("50 attempts").tag(50)
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 8)
                }
                .font(.subheadline.weight(.semibold))

                Button {
                    startShooting()
                } label: {
                    Label("Start Shooting", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(selectionZoneIDs.isEmpty)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
        .alert("Choose up to two zones for this workout.", isPresented: $showLimitAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func startShooting() {
        let zoneIDs = selectionZoneIDs.sorted()
        guard let initialZoneID = zoneIDs.first else { return }
        let session = ShootingSession(zoneIDs: zoneIDs)
        session.statusRaw = SessionStatus.active.rawValue
        let drill = ShootingDrill(
            zoneID: initialZoneID,
            session: session,
            goalAttempts: goal == 0 ? nil : goal
        )
        modelContext.insert(session)
        modelContext.insert(drill)
        try? modelContext.save()
        onStart(drill)
    }
}

struct FlowLayout: View {
    let ids: [Int]

    var body: some View {
        HStack {
            ForEach(ids, id: \.self) { id in
                Text(zone(for: id)?.shortName ?? "Zone")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}
