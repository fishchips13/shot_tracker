# Roadmap

## Now

1. Verify zone-switch restoration: returning to a tracked selected zone must restore original drill ID, shots, makes, attempts, FG%, goal progress, and streak rather than 0/0.
2. Verify 25/50 goals: final shot saves once, completes drill once, routes to summary, and leaves workout active.
3. Refine realistic court visuals if validation identifies a usability need.
4. Continue History and Stats sports-dashboard/heat-map improvements.

## Next

1. Build a watchOS companion target.
2. Add WatchConnectivity state sync.
3. Add reliable Watch Make/Miss/Undo events.
4. Add offline event queue and event-ID de-duplication.
5. Validate two-zone switching from Watch.

## Later

- Optional HealthKit.
- Cloud sync.
- Authentication/player profile.
- Sharing, friends, challenges, leaderboards.
- Share-card/export.
- Richer analytics, trends, streaks, and personal bests.

## Explicitly Deferred

- Android.
- Web dashboard.
- Team/coach accounts.
- Payments.
- Backend/cloud architecture until local and Watch workflows are stable.

Recommended order: local correctness first, phone/watch event consistency second, optional health/cloud/social features last.
