import Foundation
import SwiftData

enum ShotResult: String, Codable {
    case make
    case miss
}

enum SessionStatus: String {
    case draft
    case active
    case completed
}

enum DrillStatus: String {
    case active
    case completed
}

@Model
final class PlayerProfile {
    var id: UUID = UUID()
    var name: String = "Player"
    var createdAt: Date = Date()

    init(name: String = "Player") {
        self.name = name
    }
}

@Model
final class ShootingSession {
    var id: UUID = UUID()
    var title: String = "Shooting Workout"
    var startedAt: Date = Date()
    var endedAt: Date?
    var statusRaw: String = SessionStatus.draft.rawValue
    var selectedZoneIDsCSV: String = ""

    @Relationship(deleteRule: .cascade, inverse: \Shot.session)
    var shots: [Shot] = []

    @Relationship(deleteRule: .cascade, inverse: \ShootingDrill.session)
    var drills: [ShootingDrill] = []

    init(title: String = "Shooting Workout", zoneIDs: [Int] = []) {
        self.title = title
        setSelectedZoneIDs(zoneIDs)
    }

    var status: SessionStatus { SessionStatus(rawValue: statusRaw) ?? .draft }
    var selectedZoneIDs: [Int] {
        selectedZoneIDsCSV.split(separator: ",").compactMap { Int($0) }
    }
    var attempts: Int { shots.count }
    var makes: Int { shots.filter { $0.result == ShotResult.make.rawValue }.count }
    var misses: Int { attempts - makes }
    var percentage: Double {
        guard attempts > 0 else { return 0 }
        return Double(makes) / Double(attempts) * 100
    }
    var activeDrill: ShootingDrill? {
        drills.first(where: { $0.isActive })
    }

    /// Returns the single drill to resume for a selected zone without deleting legacy duplicates.
    func resumableDrill(for zoneID: Int) -> ShootingDrill? {
        let matches = drills.filter { $0.zoneID == zoneID }
        return matches
            .filter { $0.endedAt == nil }
            .sorted { $0.startedAt > $1.startedAt }
            .first
            ?? matches.sorted { $0.startedAt > $1.startedAt }.first
    }

    /// Keeps legacy data intact while enforcing a single resumable drill for this zone.
    func makeActive(_ drill: ShootingDrill) {
        drills
            .filter { $0.zoneID == drill.zoneID && $0.id != drill.id && $0.isActive }
            .forEach {
                $0.statusRaw = DrillStatus.completed.rawValue
                $0.endedAt = Date()
            }
        drill.statusRaw = DrillStatus.active.rawValue
        drill.endedAt = nil
    }

    func setSelectedZoneIDs(_ ids: [Int]) {
        selectedZoneIDsCSV = Array(Set(ids)).sorted().prefix(2).map(String.init).joined(separator: ",")
    }
}

@Model
final class ShootingDrill {
    var id: UUID = UUID()
    var zoneID: Int = 0
    var startedAt: Date = Date()
    var endedAt: Date?
    var statusRaw: String = DrillStatus.active.rawValue
    var goalAttempts: Int?
    var session: ShootingSession?

    @Relationship(deleteRule: .cascade, inverse: \Shot.drill)
    var shots: [Shot] = []

    init(zoneID: Int, session: ShootingSession, goalAttempts: Int? = nil) {
        self.zoneID = zoneID
        self.session = session
        self.goalAttempts = goalAttempts
    }

    var attempts: Int { shots.count }
    var makes: Int { shots.filter { $0.result == ShotResult.make.rawValue }.count }
    var misses: Int { attempts - makes }
    var percentage: Double {
        guard attempts > 0 else { return 0 }
        return Double(makes) / Double(attempts) * 100
    }
    var isActive: Bool { statusRaw == DrillStatus.active.rawValue && endedAt == nil }
    var isCompleted: Bool { !isActive }
}

@Model
final class Shot {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var zone: Int = 0
    var result: String = ShotResult.miss.rawValue
    var session: ShootingSession?
    var drill: ShootingDrill?

    init(zone: Int, result: ShotResult, session: ShootingSession, drill: ShootingDrill? = nil) {
        self.zone = drill?.zoneID ?? zone
        self.result = result.rawValue
        self.session = session
        self.drill = drill
    }
}

struct CourtZone: Identifiable, Hashable {
    let id: Int
    let name: String
    let shortName: String
    let category: ZoneCategory
}

enum ZoneCategory {
    case three
    case midrange
    case paint
}

let courtZones: [CourtZone] = [
    CourtZone(id: 1, name: "Left Corner Three", shortName: "L Corner 3", category: .three),
    CourtZone(id: 2, name: "Left Wing Three", shortName: "L Wing 3", category: .three),
    CourtZone(id: 3, name: "Top / Above-the-Break Three", shortName: "Top 3", category: .three),
    CourtZone(id: 4, name: "Right Wing Three", shortName: "R Wing 3", category: .three),
    CourtZone(id: 5, name: "Right Corner Three", shortName: "R Corner 3", category: .three),
    CourtZone(id: 6, name: "Left Midrange", shortName: "L Mid", category: .midrange),
    CourtZone(id: 7, name: "Center Midrange / Free Throw Area", shortName: "Center", category: .midrange),
    CourtZone(id: 8, name: "Right Midrange", shortName: "R Mid", category: .midrange),
    CourtZone(id: 9, name: "Left Short Midrange", shortName: "L Short", category: .midrange),
    CourtZone(id: 10, name: "Right Short Midrange", shortName: "R Short", category: .midrange),
    CourtZone(id: 11, name: "Left Restricted Area", shortName: "L Rim", category: .paint),
    CourtZone(id: 12, name: "Restricted Area / Paint", shortName: "Paint", category: .paint),
    CourtZone(id: 13, name: "Right Restricted Area", shortName: "R Rim", category: .paint),
    CourtZone(id: 14, name: "Free Throw Line", shortName: "Free Throw", category: .midrange),
    CourtZone(id: 15, name: "Layup", shortName: "Layup", category: .paint),
    CourtZone(id: 16, name: "Dunk", shortName: "Dunk", category: .paint)
]

func zone(for id: Int) -> CourtZone? {
    courtZones.first(where: { $0.id == id })
}
