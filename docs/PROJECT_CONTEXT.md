# Project Context

## Product

shot_tracker is a native iPhone basketball shooting tracker for middle-school and high-school players. The current MVP supports one- or two-zone practice, individual make/miss events, completed-workout history, and career zone stats.

## Vision

The intended experience is premium, athletic, game-like, and rewarding without being childish. It should use sports-forward hierarchy and visible progress, not Notes-app-style data entry.

## Current scope and non-goals

Current scope is local iPhone tracking with SwiftUI and SwiftData. No watchOS target, WatchConnectivity, HealthKit, cloud sync, Firebase, Google Cloud, authentication, player social profiles, sharing, friends, or challenges are verified in source.

## Principles and invariants

1. A Shot is an immutable event with result, timestamp, zone ID, and applicable parent relationships.
2. Shot events, not cached counters, are the source of truth.
3. A ShootingDrill represents focused tracking in exactly one zone.
4. New Make/Miss events use the active drill zoneID, never generic selection UI state.
5. Active tracking uses a tracking-locked court; court taps cannot change a future shot zone.
6. A session supports one or two selected zones.
7. Users cannot start with zero zones, select more than two, or record outside selected zones.
8. Switching reuses a resumable target drill when available and preserves recorded counts.
9. History and career stats use completed sessions by default.
10. Older persisted records must fail safely when newer optional/defaulted fields are absent.

## Current versus future

| Capability | Status |
|---|---|
| Local iPhone tracking | Implemented in source |
| Zone-locked drills | Implemented in source |
| Apple Watch companion | Planned |
| HealthKit metrics | Planned / optional |
| Cloud, authentication, social | Planned |
