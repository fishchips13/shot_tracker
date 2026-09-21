# Test Plan

Run manually on an iPhone simulator/device. These tests protect the invariants in PROJECT_CONTEXT.md.

## 1. One-zone workout

**Setup:** Choose one zone.  
**Actions:** Start, record makes/misses, finish drill, finish workout.  
**Expected:** Every shot uses the drill zone; summary and total match events.  
**Invariants:** Shot events; locked drill zone.

## 2. Two-zone restoration

**Setup:** Choose Left Wing Three and Left Midrange.  
**Actions:**

    Record 3/5 in Left Wing Three.
    Switch to Left Midrange.
    Record 2/4 in Left Midrange.
    Switch back to Left Wing Three.
    Finish the workout.

**Expected:** Left Wing Three shows 3/5, not 0/0; Left Midrange shows 2/4; final total is 5/9.  
**Invariants:** Resumable drill identity; no duplicate empty drill.

## 3. No silent court switch

**Setup:** Active drill.  
**Actions:** Tap court zones.  
**Expected:** Court is locked; active drill and future shot zone do not change.  
**Invariants:** activeDrill.zoneID authority.

## 4. Goal 25

**Setup:** Start goal-25 drill.  
**Actions:** Record exactly 25 shots.  
**Expected:** Final shot saves once; drill completes once; summary opens; workout stays active.  
**Invariants:** Goal completion ordering.

## 5. Goal 50

**Setup:** Start goal-50 drill.  
**Actions:** Record exactly 50 shots.  
**Expected:** Same as goal 25.  
**Invariants:** Goal completion ordering.

## 6. Undo

**Setup:** Active drill with multiple shots; another zone may have shots.  
**Actions:** Undo once.  
**Expected:** Only newest active-drill shot is removed.  
**Invariants:** Drill-scoped events.

## 7. Finish Drill confirmation

**Setup:** Active drill.  
**Actions:** Tap Finish Drill, cancel, then confirm.  
**Expected:** Cancel preserves drill; confirm completes it.  
**Invariants:** Completion requires intent.

## 8. Finish Workout confirmation

**Setup:** Active or summary state.  
**Actions:** Tap Finish Workout, cancel, then confirm.  
**Expected:** Cancel preserves session; confirm completes it and opens summary.  
**Invariants:** Completed-session boundary.

## 9. Relaunch persistence

**Setup:** Record shots, terminate, relaunch.  
**Actions:** Resume workout.  
**Expected:** Stored session/drill/shot values return safely.  
**Invariants:** Local SwiftData persistence.

## 10. History filtering

**Setup:** Have draft and completed sessions.  
**Actions:** Open History.  
**Expected:** Completed sessions only by default.  
**Invariants:** Reporting boundary.

## 11. Zone stats

**Setup:** Complete workouts with known zone shots.  
**Actions:** Open Stats.  
**Expected:** Totals and heat intensity derive from completed shot events.  
**Invariants:** Event aggregation.

## 12. Older data safety

**Setup:** Existing data missing newer drill/zone metadata.  
**Actions:** Launch and open History/Stats.  
**Expected:** No crash; safe empty/fallback behavior.  
**Invariants:** Migration compatibility.

## 13. Rapid Make/Miss

**Setup:** Active drill.  
**Actions:** Tap Make or Miss rapidly.  
**Expected:** The short saving guard prevents accidental duplicate events.  
**Invariants:** Event-entry debounce.

## Planned / Not Yet Implemented: Watch tests

After watchOS code exists, validate paired-device state sync, offline queueing, event-ID retry de-duplication, stale-zone rejection, and optional HealthKit behavior.
