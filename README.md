# shot_tracker

shot_tracker is a native, local-first iPhone basketball shooting tracker. Players choose one or two court zones, record individual makes and misses in zone-locked drills, and review completed workouts and career zone statistics. The product direction is athletic and game-like rather than notes-style data entry.

## Technology

| Area | Current technology |
|---|---|
| Language | Swift |
| UI | SwiftUI |
| Persistence | SwiftData |
| IDE | Xcode |
| Development runtime | iPhone Simulator |

## Quick start

1. Open shot_tracker.xcodeproj in Xcode.
2. Select an iPhone simulator.
3. Build and run the shot_tracker scheme.

The app is local-first; GitHub is not required to build or run it.

## Source-verified features

- One- or two-zone workout selection.
- Local persistence of sessions, drills, and individual shot events.
- Zone-locked Make/Miss recording from the current drill.
- Locked court during active tracking.
- Explicit selected-zone switching that reuses a resumable drill.
- Optional 25- and 50-attempt goals.
- Completed-workout History and completed-session Stats.

## Known limitations

- Zone restoration is source-verified but still requires the manual regression test in docs/TEST_PLAN.md.
- No watchOS target, WatchConnectivity, HealthKit, cloud sync, authentication, or social features are present in the inspected source.
- Legacy duplicate drills are retained; the newest unfinished matching drill is preferred for resumption.

## Documentation

- [Project context](docs/PROJECT_CONTEXT.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Data model](docs/DATA_MODEL.md)
- [Workout flow](docs/WORKOUT_FLOW.md)
- [UI flows](docs/UI_FLOWS.md)
- [Watch architecture](docs/WATCH_ARCHITECTURE.md)
- [Agent rules](docs/AGENT_RULES.md)
- [Changelog](docs/CHANGELOG.md)
- [Roadmap](docs/ROADMAP.md)
- [Test plan](docs/TEST_PLAN.md)
