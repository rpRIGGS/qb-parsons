# Deferred qb-doorlock fork integration — Parsons

**Status:** Reference snippet only. Do not install yet. Keep this work in the future qb-doorlock fork/integration stage alongside qb-ambulancejob. No qb-doorlock repository is modified by this file.

## Why this is needed

The current stock `qbcore-fivem/qb-doorlock/server.lua` handles `qb-doorlock:server:updateState` with an `unlockAnyway` bypass and a caller-supplied `sentSource`. Simply adding a check inside `isAuthorized` would not protect every state change. The enforcement hook must run in the **server updateState handler before** its existing `if not unlockAnyway and not isAuthorized(...)` statement.

Parsons already exports `AuthorizeDoorInteraction(src, doorID)`: `nil` means unmanaged, `true` allows, `false` denies. It covers configured bedrooms, observation doors, and secure-wing gate. Its staff and patient policies remain inside Parsons.

## Minimal hook for future fork

**A.** In the future qb-doorlock fork's `server.lua`, define a **static fail-closed set** of actual Parsons door IDs (copy from the verified running config; the examples below are placeholders and MUST be replaced):

```lua
-- Example structure ONLY; populate from actual Config.DoorList identifiers.
local ParsonsManagedDoorIds = {
    -- ['Parsons-Main Floor med ward 4'] = true,
    -- ['Parsons-Basement 11'] = true,
}
```

**B.** In the `qb-doorlock:server:updateState` handler, immediately **after** validating that `Config.DoorList[doorID]` exists, insert this block **before** the original authorization check:

```lua
    if ParsonsManagedDoorIds[doorID] then
        -- Client-supplied sentSource and unlockAnyway are never authority.
        -- Restrict this event to the actual invoking player for managed doors.
        local actualSource = source
        if type(actualSource) ~= 'number' or actualSource <= 0 then return end
        if GetResourceState('qb-parsons') ~= 'started' then return end

        local ok, allowed = pcall(function()
            return exports['qb-parsons']:AuthorizeDoorInteraction(actualSource, doorID)
        end)
        if not ok or allowed ~= true then return end

        -- Force the identity and suppress ordinary bypass flags.
        playerId = actualSource
        Player = exports['qb-core']:GetPlayer(actualSource)
        if not Player then return end
        unlockAnyway = false
        usedLockpick = false

        -- Parsons policy already authorized this specific state change.
        -- Skip the generic isAuthorized test ONLY for this managed door.
    end
```

**C.** Replace the stock check:

```lua
    if not unlockAnyway and not isAuthorized(Player, Config.DoorList[doorID], usedLockpick) then
```

with:

```lua
    if not unlockAnyway
        and not ParsonsManagedDoorIds[doorID]
        and not isAuthorized(Player, Config.DoorList[doorID], usedLockpick) then
```

Keep the existing warning and `return` body unchanged. This makes the Parsons decision authoritative for managed doors, while leaving ordinary qb-doorlock behavior unchanged for other doors. When Parsons is stopped or throws an error, its doors cannot be changed via this event.

## Integration checklist for later stage

- Confirm **real** `Config.DoorList` IDs and map them to `Config.PatientRooms[].doorIds`, observation door IDs and `Config.SecureWardGateDoorIds` in Parsons. The two sets must match exactly; do not invent identifiers.
- Review all other server-side door-state mutation paths in the actual fork, including admin/resource calls and door creation. The snippet above protects the stock updateState event only.
- Decide whether staff emergency override and secure patient escort require distinct server-authorized workflows; do not grant generic bypasses.
- Test assigned vs unassigned patients, on-duty staff, escaped/transported patients, secure gate, observation rooms, lockpicks, malicious `sentSource` and `unlockAnyway`, and Parsons restart/unavailability.
- Review how clients present interactions: server-side denial is essential, but client UI may still show a door as interactable.
- Validate that the existing Parsons export handles all intended IDs and no nil/mismatch grants a fallback.

**Do not mark physical door access as implemented until the future fork is patched, deployed, and tested.** This reference is intentionally isolated so current Parsons Task 1 can close without starting the separate qb-doorlock expansion.
