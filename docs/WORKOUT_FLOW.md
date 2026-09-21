# Workout Flow

## State machine

    No active workout
      → Zone selection
      → Drill setup
      → Active drill ⇄ explicit selected-zone switch
      → Goal-complete drill / Finish Drill
      → Drill summary
      → Workout completion
      → Workout summary

## Invariant matrix

| Flow state | Court behavior | May record shots? | Authoritative zone | May change zones? |
|---|---|---:|---|---|
| Zone selection | Tappable | No | Selection set | Yes, maximum 2 |
| Drill setup | Read-only | No | Chosen drill zone | Explicit choice only |
| Active drill | Tracking-locked | Yes | activeDrill.zoneID | Explicit switch only |
| Drill summary | Read-only | No | Completed drill | Start/resume valid selected zone |
| Workout summary | Read-only | No | Not applicable | No |

## Transitions

| Action | From → To | Persisted work | Confirmation | Court |
|---|---|---|---|---|
| Continue | Selection → Setup | Creates session | No | Selection |
| Start | Setup → Active | Creates or resumes drill | No | Locked |
| Make/Miss | Active → Active | Inserts one Shot at drill zone | No | Locked |
| Undo | Active → Active | Deletes newest active-drill Shot | No | Locked |
| Finish Drill | Active → Summary | Completes drill | Yes | Locked |
| Goal reached | Active → Summary | Saves final Shot then completes drill | No extra confirmation | Locked |
| Switch | Active → Active | Completes current; resumes/creates target | If current has shots | Locked |
| Finish Workout | Active/Summary → Summary | Completes drill/session | Yes | Read-only |

## Goals and zone restoration

The setup UI offers No goal, 25, and 50 attempts. Source code verifies that reaching the exact target saves the final shot, completes the drill, and routes to summary without ending the workout. Manual validation remains required.

Source code also verifies a resumable-drill lookup and reactivation path. Intended runtime result: returning to a tracked zone restores makes, attempts, FG%, goal progress, streak, and last-shot state rather than showing a new empty 0/0 drill.

## Resume

An unfinished session routes to its active drill when one exists, zone selection when it has no selected zones, or drill setup otherwise.
