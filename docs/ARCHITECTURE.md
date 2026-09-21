# Architecture

## Component map

| File | Responsibility |
|---|---|
| MyApp.swift | Creates and injects the SwiftData container. |
| Models.swift | Models, statuses, zone catalog, and resumable-drill helpers. |
| ContentView.swift | Track/History/Stats tabs and UUID-based workout routing. |
| ZoneSelectionView.swift | Temporary one/two-zone selection and session creation. |
| DrillStartView.swift | Goal selection and start/resume action. |
| ActiveDrillView.swift | Locked tracking, shots, undo, goals, and switching. |
| DrillSummaryView.swift | Completed drill result and next action. |
| WorkoutSummaryView.swift | Read-only completed workout result. |
| HistoryView.swift | Completed-workout feed. |
| ZoneStatsView.swift | Completed-session skill dashboard. |
| CourtDiagramView.swift | Court drawing and interaction modes. |

## Navigation

    ZoneSelectionView
           ↓
    DrillStartView
           ↓
    ActiveDrillView
           ↓
    DrillSummaryView
           ↓
    WorkoutSummaryView
           ↓
    HistoryView / ZoneStatsView

ContentView owns a Track/History/Stats TabView. Track uses NavigationStack and WorkoutFlowStep values. Routes carry persisted UUIDs and resolve the matching session or drill from the query.

## Persistence data flow

    UI action
      → active ShootingDrill
      → Shot using drill.zoneID
      → ModelContext insert/save
      → local SwiftData store
      → History/Stats aggregates

MyApp registers PlayerProfile, ShootingSession, ShootingDrill, and Shot in one local ModelContainer.

## Court modes

| Mode | Actual behavior |
|---|---|
| selection | Tappable; forwards zone ID to caller. |
| readOnly | Buttons disabled; may show heat intensity. |
| trackingLocked | Buttons disabled; active zone highlighted. |

The source verifies that ActiveDrillView supplies trackingLocked. Runtime navigation edge cases remain subject to the manual regression plan.
