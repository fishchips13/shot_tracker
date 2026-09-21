# Agent Rules

## Before editing

1. Read README.md, PROJECT_CONTEXT.md, ARCHITECTURE.md, DATA_MODEL.md, WORKOUT_FLOW.md, this file, and relevant feature docs.
2. Inspect only Swift files relevant to the request.
3. State a short plan before changing app code.
4. Identify SwiftData schema/migration impact.
5. Preserve zone-lock and event-source invariants.

## During editing

1. Keep changes scoped; avoid unrelated refactors.
2. Use native SwiftUI and SwiftData; do not add dependencies without approval.
3. Do not add cloud services, Firebase, Google Cloud, CloudKit, WatchConnectivity, or HealthKit unless requested.
4. Use String(format: "%.0f%%", value), not interpolation with specifier.
5. Avoid complicated SwiftData predicates unless necessary.
6. Never hide a build error by excluding source from a target.
7. Preserve local data; use migration-safe defaults/optionals for stored-model changes.
8. Never make the court tappable during active tracking.
9. Before Make/Miss, Undo, goals, completion, or switching, identify the persisted authoritative drill/session object.
10. Before creating a drill, search the session for a resumable drill with the target zoneID.
11. Add regression coverage in TEST_PLAN.md for changed Make/Miss, undo, goal, switch, or completion behavior.
12. For schema changes, document migration risk, compatibility strategy, and upgrade/relaunch testing.

## After editing

1. Build the appropriate target.
2. Report exact build result and changed files.
3. Explain model/migration effects.
4. Update CHANGELOG plus relevant architecture, flow, and test docs.
5. Provide manual regression tests.
6. Do not claim behavior works without a build or clear unverified labeling.

## Invariants

- Shot is an immutable event with result, timestamp, zone, and applicable parents.
- Shot events are authoritative.
- Drill owns one tracking zone.
- Saved shots use activeDrill.zoneID, not temporary UI state.
- Active court is tracking-locked.
- Sessions select one or two zones.
- Switching reuses resumable drills and preserves counts.
- Completed workouts drive default History and Stats.
- Older optional/defaulted records must fail safely.
