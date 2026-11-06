# Stage 6 — Patient activities and facility interactions

**Status:** Initial framework committed; Parsons MLO coordinates and FiveM testing outstanding.

## Implemented
- Therapy, recreation, and rehabilitation definitions in `Config.Activities`.
- Server-only activity completion validation: active Parsons hold, mapped station proximity, elapsed duration and cooldown.
- Patient-only `qb-target` stations generated from `Config.Locations.activities`.
- Client session handling for start, finish and discharge cancellation.
- No monetary rewards, items, prison jobs or changes to commitment duration.

## Configure after mapping the MLO
Add a station under `Config.Locations.activities` using the same key as `Config.Activities`, for example:

```lua
therapy = {
    coords = vector3(0.0, 0.0, 0.0), -- REPLACE with real Parsons MLO position
    heading = 0.0,
    length = 2.0,
    width = 2.0,
    radius = 4.0
}
```

The example coordinates are NOT installed as active stations.

## Remaining Stage 6 work
- Map real therapy, recreation and rehabilitation locations.
- Test `qb-target` zones and server distance enforcement.
- Confirm the countdown/help-text UI, Backspace cancellation, and E-key fallback in FiveM.
- Test activity resynchronization after client reload, reconnect, resource restart, discharge and moving away mid-activity.
- Decide whether staff-led sessions need a separate authorization workflow.
- Define optional activity history/clinical documentation separately from the operational activity system.

## Stage 5 dependency
Stage 5 inventory/reconnect behavior still requires PowerMoves development-server verification. Stage 6 groundwork does not signify that Stage 5 has passed live testing.

## Additional safeguards committed

- The client cancels activity when the patient walks beyond the configured station radius.
- A server-side periodic check independently cancels sessions when the hold ends or the player leaves the station.
- Activity completion remains bound to a server-issued token and elapsed duration.

## qb-spawn installation integration note

The existing qb-spawn jail check must also recognize active `PlayerData.metadata.parsons_hold` (`type(hold) == 'table' and hold.active == true`). The original `injail` behavior must remain unchanged. Active Parsons patients should bypass normal spawn choices and return to Parsons. Add a precise patch/snippet after reviewing the server's actual qb-spawn version; do not overwrite qb-spawn from this repository.

## Further Stage 6 implementation

- Live help-text countdown and Backspace cancellation for active patient sessions.
- E-key interaction fallback when `UseTarget` is disabled; `qb-target` remains the preferred interaction.
- Server activity-status request permits client state resynchronization after admission or character load, without granting an activity or bypassing validation.
- The `README.md` now carries the `qb-spawn` installation requirement; the actual installed qb-spawn version must be inspected before writing a drop-in patch.

**Remaining:** Real MLO station positions, in-server testing, and a decision on whether staff-led therapy and clinical history belong in Stage 8 / SAMS integration rather than the patient activity engine. No claim of FiveM verification.

## Cross-stage status clarification (2026-11-06)

Stage 6 activity code is present but awaits mapped stations and runtime verification. Stage 7 introduces `ox_lib` as a dependency for security skill checks; activity UI is not thereby automatically converted to ox_lib. The upcoming Stages 1–4 admission refactor must keep activity eligibility limited to checked-in patients inside the configured facility polygon. No activities shorten commitment time. Security monitoring and police calls identify **Gruppe Sechs**, via optional PS Dispatch; these do not change activity scope.

## Current security implementation checkpoint — 2026-11-06

- Approved benchmark now configured: gate compromise **300 seconds**, electrical disruption **300 seconds**, and security alarm failsafe **300 seconds** (from the upstream qb-prison five-minute alarm reference; these remain adjustable). A timed electrical disruption is **not** yet a visual MLO blackout.
- Failed gate hacking raises a security alarm and sends a distinct PS Dispatch attempted-tampering incident. Successful hacking retains gate compromise and relock handling. Alarm acknowledgment/reset is independent of restoring gate or electrical equipment.
- `Config.Security.alarm.resetPoints = {}` accepts multiple qb-target alarm reset stations (guard shack and medical offices to be mapped). Server checks interaction proximity and on-duty QBCore job **type** `leo` or `ems`. A five-minute alarm failsafe prevents indefinite active alarms. No slash reset command is required.
- Aircraft exemption uses the on-duty pilot's QBCore job type `leo`, `ems`, or `fire`. The user's actual PowerMoves-PSDispatch fork exposes `CustomAlert`; Parsons is configured to use PS Dispatch only.
- Gruppe Sechs guard nightstick, defensive AI, injury/death alerts, respawn delay and player-clear radius are **approved but not yet operationally implemented**. `Config.Security.guard` holds provisional settings. The local-only blackout and actual MLO light control are **not yet implemented**; do **not** invoke global qb-weathersync blackout.
- Approved court-transport workflow: on-duty LEO may check out a patient temporarily through authorized guard interaction, with the commitment, room/belongings and treatment hold preserved. Returning from authorized transport must not be counted as escape. Separate judicially authorized permanent uncommit remains available. **Not implemented yet**; reconcile in Stages 1–4.
- Still require user-provided MLO PolyZone vertices/Z limits, actual qb-doorlock gate/room IDs, guard and reception vectors, electrical panels, and reset-station vectors. Do not substitute legacy prison coordinates. Source code is not yet live FiveM acceptance-tested.
