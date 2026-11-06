# Stage 6 — Patient activities and facility interactions

**Status:** Initial framework committed; Parsons MLO coordinates and FiveM testing outstanding.

## Implemented
- Therapy, recreation, and rehabilitation definitions in `Config.Jobs`.
- Server-only activity completion validation: active Parsons hold, mapped station proximity, elapsed duration and cooldown.
- Patient-only `qb-target` stations generated from `Config.Locations.jobs`.
- Client session handling for start, finish and discharge cancellation.
- No monetary rewards, items, prison jobs or changes to commitment duration.

## Configure after mapping the MLO
Add a station under `Config.Locations.jobs` using the same key as `Config.Jobs`, for example:

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
