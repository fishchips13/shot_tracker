import SwiftUI
import SwiftData

struct ZoneStatsView: View {
    @Query private var sessions: [ShootingSession]

    private var completed: [ShootingSession] { sessions.filter { $0.status == .completed || $0.endedAt != nil } }
    private var completedShots: [Shot] { completed.flatMap(\.shots) }
    private var attempts: Int { completedShots.count }
    private var makes: Int { completedShots.filter { $0.result == ShotResult.make.rawValue }.count }
    private var percentage: Double { attempts == 0 ? 0 : Double(makes) / Double(attempts) * 100 }

    private var records: [ZoneRecord] {
        courtZones.map { zone in
            let shots = completedShots.filter { $0.zone == zone.id }
            let makes = shots.filter { $0.result == ShotResult.make.rawValue }.count
            return ZoneRecord(zone: zone, attempts: shots.count, makes: makes)
        }
    }
    private var ranked: [ZoneRecord] { records.filter { $0.attempts >= 5 } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                dashboard
                Text("Court Heat Map").font(.title3.bold())
                CourtDiagramView(mode: .readOnly, selectedZoneIDs: [], activeZoneID: nil, onZoneTapped: { _ in }, zoneIntensity: Dictionary(uniqueKeysWithValues: records.map { ($0.zone.id, $0.percentage / 100) }))
                    .accessibilityLabel("Career shooting heat map")
                rankingSection("Strengths", icon: "flame.fill", entries: ranked.sorted { $0.percentage > $1.percentage }.prefix(3), empty: "Log at least 5 attempts in a zone to unlock rankings.")
                rankingSection("Keep Working", icon: "figure.basketball", entries: ranked.sorted { $0.percentage < $1.percentage }.prefix(3), empty: "Log at least 5 attempts in a zone to unlock rankings.")
                zoneBreakdown
            }.padding()
        }
        .background(Color.orange.opacity(0.035))
        .navigationTitle("Stats")
    }

    private var dashboard: some View {
        HStack(spacing: 0) {
            dashboardStat(String(format: "%.0f%%", percentage), "CAREER FG%")
            dashboardStat("\(makes)", "MAKES")
            dashboardStat("\(attempts)", "ATTEMPTS")
            dashboardStat("\(completed.count)", "WORKOUTS")
        }
        .padding(.vertical, 15)
        .background(LinearGradient(colors: [.orange, .orange.opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private func dashboardStat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.headline.bold().monospacedDigit())
            Text(label).font(.system(size: 9, weight: .bold)).opacity(0.85)
        }.frame(maxWidth: .infinity)
    }

    private func rankingSection(_ title: String, icon: String, entries: ArraySlice<ZoneRecord>, empty: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon).font(.title3.bold())
            if entries.isEmpty {
                Text(empty).font(.subheadline).foregroundStyle(.secondary)
            } else {
                ForEach(entries) { entry in
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(entry.zone.name).font(.subheadline.weight(.semibold))
                            Spacer()
                            Text(String(format: "%.0f%%", entry.percentage)).font(.subheadline.bold().monospacedDigit())
                        }
                        ProgressView(value: entry.percentage / 100).tint(color(for: entry.zone))
                    }
                }
            }
        }
        .padding(16).background(.background).clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var zoneBreakdown: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zone Breakdown").font(.title3.bold())
            ForEach(records.filter { $0.attempts > 0 }) { entry in
                HStack {
                    Circle().fill(color(for: entry.zone)).frame(width: 9, height: 9)
                    Text(entry.zone.shortName)
                    Spacer()
                    Text("\(entry.makes)/\(entry.attempts)  \(String(format: "%.0f%%", entry.percentage))")
                        .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                }.padding(.vertical, 4)
            }
        }
        .padding(16).background(.background).clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func color(for zone: CourtZone) -> Color {
        switch zone.category {
        case .three: .blue
        case .paint: .red
        case .midrange: .orange
        }
    }
}

private struct ZoneRecord: Identifiable {
    let zone: CourtZone
    let attempts: Int
    let makes: Int
    var id: Int { zone.id }
    var percentage: Double { attempts == 0 ? 0 : Double(makes) / Double(attempts) * 100 }
}
