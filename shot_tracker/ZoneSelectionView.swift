import SwiftUI
import SwiftData

struct ZoneSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectionZoneIDs: Set<Int> = []
    @State private var showLimitAlert = false
    let onContinue: (ShootingSession) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose Your Zones").font(.largeTitle.bold())
                Text("Choose one or two areas to train in this workout.").foregroundStyle(.secondary)
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
                Button("Continue") {
                    let session = ShootingSession(zoneIDs: selectionZoneIDs.sorted())
                    session.statusRaw = SessionStatus.active.rawValue
                    modelContext.insert(session)
                    try? modelContext.save()
                    onContinue(session)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
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
}

struct FlowLayout: View {
    let ids: [Int]
    var body: some View {
        HStack {
            ForEach(ids, id: \.self) { id in
                Text(zone(for: id)?.name ?? "Zone")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 7)
                    .background(.orange.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }
}
