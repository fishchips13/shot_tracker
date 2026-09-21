# Watch Architecture

## Status: Planned / Not Implemented

No watchOS target, watch source, WatchConnectivity, or HealthKit code exists in the inspected source.

## Proposed architecture

- iPhone local SwiftData is canonical in V1.
- Watch is a fast companion display/input device.
- WatchConnectivity is planned for state snapshots and action events.
- Watch sends deduplicated shot actions.
- iPhone validates session, drill, and zone before persisting a Shot.
- HealthKit is optional future work.

## Planned payload

    ShotActionEvent
      eventID: UUID
      sessionID: UUID
      drillID: UUID
      zoneID: Int
      result: make | miss
      createdAt: Date

The phone must reject stale/mismatched actions and de-duplicate by eventID.

## Phases

1. Watch UI mock.
2. Phone-to-watch state synchronization.
3. Watch-to-phone shot event synchronization.
4. Offline action queue and event-ID de-duplication.
5. Optional HealthKit workout session.

Physical paired devices are required to validate WatchConnectivity.
