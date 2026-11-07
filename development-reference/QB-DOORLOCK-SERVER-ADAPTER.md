# qb-doorlock server authorization adapter (Task 1)

This integration targets the verified upstream `qbcore-fivem/qb-doorlock/server.lua` implementation. Parsons cannot enforce doorlock state by itself. **Install this patch in the running qb-doorlock resource**, or merge it into its fork. The Parsons export is already committed.

## 1. Add the following at the beginning of `isAuthorized(Player, door, usedLockpick)`, before `door.allAuthorized`, admin access, lockpick access, or any job checks:

```lua
    -- Parsons-managed doors must never fall through to generic doorlock grants.
    if GetResourceState('qb-parsons') == 'started' then
        local ok, decision = pcall(function()
            return exports['qb-parsons']:AuthorizeDoorInteraction(Player.PlayerData.source, door.id)
        end)
        if not ok then return false end
        if decision ~= nil then return decision == true end
    end
```

**Important:** Upstream `isAuthorized` receives a door object, not the doorID, and stock configs may not set `door.id`. The correct production implementation passes the actual doorID into the authorization function (see next step); do not use the snippet above without that adjustment.

## 2. Use this verified replacement signature and call:

```lua
local function isAuthorized(Player, door, usedLockpick, doorID)
    -- Reject any Parsons-managed door before admin/lockpick/job bypasses.
    if GetResourceState('qb-parsons') == 'started' then
        local ok, decision = pcall(function()
            return exports['qb-parsons']:AuthorizeDoorInteraction(Player.PlayerData.source, doorID)
        end)
        if not ok then return false end
        if decision ~= nil then return decision == true end
    end
    -- Original qb-doorlock isAuthorized body follows unchanged.
end
```

Change the existing updateState authorization call from:
```lua
isAuthorized(Player, Config.DoorList[doorID], usedLockpick)
```
to:
```lua
isAuthorized(Player, Config.DoorList[doorID], usedLockpick, doorID)
```

For safety, the resource must fail closed for known Parsons doors when qb-parsons is stopped. Set up a static `ParsonsDoorIds` table in qb-doorlock using the exact configured door IDs, and deny them when Parsons is unavailable. Otherwise qb-doorlock could fall through to normal authorization during a Parsons restart. This table must be reconciled with the **actual** installed qb-doorlock door IDs.

## 3. Prevent event bypasses

The upstream `qb-doorlock:server:updateState` handler accepts `unlockAnyway` and `sentSource` parameters. Do not permit either to bypass Parsons authorization. Immediately after verifying `Config.DoorList[doorID]`, before the `if not unlockAnyway and not isAuthorized(...)` guard, add:

```lua
    local parsonsDecision
    if GetResourceState('qb-parsons') == 'started' then
        local ok, decision = pcall(function()
            return exports['qb-parsons']:AuthorizeDoorInteraction(source, doorID)
        end)
        if not ok then return end
        parsonsDecision = decision
    end
    if parsonsDecision ~= nil then
        if source == 0 or parsonsDecision ~= true then return end
        -- Do not trust sentSource or unlockAnyway on managed doors.
        playerId = source
        Player = exports['qb-core']:GetPlayer(playerId)
        if not Player then return end
        unlockAnyway = false
        usedLockpick = false
    end
```

**Caution:** Because `sentSource` can affect player identity before this guard, full production integration should resolve the actual source and protect any other privileged update paths. Do not deploy without reviewing other qb-doorlock call sites and doorlock restart behavior.

## Scope and readiness

- `Config.PatientRooms` door IDs: upstairs four, secure basement four.
- `Config.ObservationRooms` and `Config.SecureWardGateDoorIds`: staff only.
- On-duty configured medical staff can access managed doors; patient access only to their own currently reserved bedroom.
- Escaped/transported patients cannot unlock assigned rooms.
- No new map coordinates or door identifiers are invented.
- **Not yet installed in qb-doorlock; this is a reviewed integration guide, not a claim of live enforcement.**
