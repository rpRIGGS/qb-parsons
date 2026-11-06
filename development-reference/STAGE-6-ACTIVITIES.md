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
- Add an explicit cancellation UI and progress presentation.
- Test reconnect, resource restart, discharge and moving away mid-activity.
- Decide whether staff-led sessions need a separate authorization workflow.
- Define optional activity history/clinical documentation separately from the operational activity system.

## Stage 5 dependency
Stage 5 inventory/reconnect behavior still requires PowerMoves development-server verification. Stage 6 groundwork does not signify that Stage 5 has passed live testing.
