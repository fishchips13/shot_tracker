# Data Model

## SwiftData models

| Model | Persisted fields |
|---|---|
| PlayerProfile | id, name, createdAt |
| ShootingSession | id, title, startedAt, endedAt, statusRaw, selectedZoneIDsCSV, shots, drills |
| ShootingDrill | id, zoneID, startedAt, endedAt, statusRaw, goalAttempts, session, shots |
| Shot | id, timestamp, zone, result, session, drill |

Session computed values include selectedZoneIDs, status, attempts, makes, misses, FG%, and activeDrill. Drill computed values include attempts, makes, misses, FG%, isActive, and isCompleted.

## Relationships

    ShootingSession 1 ──< ShootingDrill 1 ──< Shot
           │
           └──────────────────────────────< Shot

Session-to-shots, session-to-drills, and drill-to-shots use cascade delete rules with inverse relationships.

## Authoritative source of truth

| Concern | Authoritative source |
|---|---|
| Shot result and location | Individual Shot event |
| Active tracking zone | Active ShootingDrill.zoneID |
| Workout totals | Aggregate of associated Shot events |
| Zone/career stats | Aggregate of Shot events from completed sessions |
| Temporary selection UI | SwiftUI state only; never authoritative for saved shots |

Shot events are the source of truth. Do not use temporary SwiftUI zone-selection state as the source of truth for a saved Shot.

## Compatibility

Stored properties have defaults where practical. Shot.session, Shot.drill, ShootingDrill.session, endedAt, and goalAttempts are optional where source code permits. This is the intended migration-safety approach; historical-store upgrade behavior still requires relaunch testing.

## Resumable drills

ShootingSession.resumableDrill(for:) chooses the newest unfinished matching drill, otherwise the newest matching legacy drill. makeActive closes other active duplicates for that zone without deleting them.

## Planned Watch event de-duplication

Planned, not implemented: Watch shot actions should include immutable event IDs; the phone should persist the first accepted event and ignore retries.
