# Parsons admission, checkout, rooms and security — approved design handoff

Status: design specification for Stages 7–9, not yet implemented. Real Parsons MLO coordinates and actual qb-doorlock configuration are pending.

## Separate physical locations

- **Reception:** medical/reception staff PED. Patient check-in and room assignment take place here. Not at the security gate.
- **Guard shack:** security guard PED. Patients check remaining commitment time and, once authorized clearance exists, check out. A status inquiry alone never releases a patient.
- **Arrival point:** inside the secured front gate. `/commit` may teleport the patient here with a notification instructing them to check in at reception. Physical transport may bring a patient here without teleportation.
- **Outside:** exit destination after approved checkout. Do not confuse this with arrival or reception.
- **Middle:** current center for perimeter distance calculations; not a reception or interaction point. Replace the circular placeholder with an MLO-appropriate boundary when mapped.

## Commitment and check-in lifecycle

1. Trusted medical/judicial integration establishes commitment authority. Do not use qb-prison `injail` or change existing prison behavior.
2. A patient transported or teleported to Parsons is **pending reception check-in**. The commitment order can exist before check-in, but playable commitment time **does not begin** until successful reception processing.
3. At reception, verify commitment and capacity, secure belongings, assign an available patient room, change to patient clothing, and mark check-in complete. The playable-time clock starts at successful check-in, not when `/commit` is issued.
4. Assignments persist across disconnects and reserve room capacity. A full facility must not silently overbook. Determine failed/aborted check-in rollback and transfer handling before implementation.
5. Reception may show remaining commitment time as well as perform check-in. The guard shack independently provides status checks and authorized checkout.
6. Only after authorized clearance, the guard-shack checkout returns belongings, restores normal clothing, releases the room and transfers the patient outside the gate. Court-ordered holds require judicial clearance. An elapsed timer by itself is not clearance.
7. Disconnecting, leaving the facility, or triggering a security incident does not discharge a patient or clear their belongings.

**Implementation gap:** Current `server/main.lua` starts counting when `AdmitPatient` is called; current `client/main.lua` teleports directly to a random old prison spawn and has a single desk interaction. Both must be refactored to support the two-phase arrival/check-in and separate checkout workflow. Do not describe these as implemented.

## Doors and escape adaptation

- Integrate room access and the front security gate with the installed `qb-doorlock`, after checking its actual door identifiers and individual-access support.
- A patient may access only their assigned room; medical staff retain authorized access. Remove patient access on discharge.
- Original upstream `qb-prison/client/prisonbreak.lua` has three gate points, electronic-kit/gatecrack item checks, hacking minigame, `qb-doorlock:server:updateState`, lockdown, alerts, and an escape check that **clears prison jail status and clears the jail-items record**. It does not return the belongings on escape.
- Parsons should **adapt**, not erase, that design: a smaller, facility-appropriate breach/escape scenario, using the actual Parsons gate and installed doorlock. Never port upstream jail-status clearing, belongings-record clearing on escape, or automatic discharge.
- Current `client/prisonbreak.lua` contains only perimeter monitoring; original hacking/gate functionality was removed from the fork. Stage 7 must intentionally rebuild/adapt it, with server-authoritative validation and no untrusted client ability to unlock doors.

## Activities and facility work

- Stage 6: pool, tennis, yoga, garden meditation, gardening, raking, laundry, and cafeteria occupational tasks; optional stress relief and admission-specific participation history. No sentence reductions.
- The cafeteria has a separate supply storage room: restocking and kitchen duties can be multi-step work activities. Patient meals are free and available regardless of whether a player is working in the cafeteria.
- Stage 8: room inventory and check-in/out workflows, staff-facing participation, free cafeteria service, medical workstations and pharmacy planning.
- Stage 9: clinical record integration with SAMS.net and authorized court-ordered commitment updates to SADOJ.net. Participation data is not an automatic clinical assessment.

## MLO config points to capture

Reception PED, inside-gate arrival, guard shack PED, outside checkout destination, patient rooms and doors, front gate and doorlock ID, security perimeter, activity stations, cafeteria kitchen and food-storage room. Existing prison coordinates are placeholders, not final Parsons positions.

## Verified upstream escape behavior (qbcore-fivem/qb-prison)

Reviewed upstream `config.lua`, `client/prisonbreak.lua`, `client/main.lua`, and `server/main.lua` on 2026-11-06:

- No configurable escape-time reset/continuation option was found in upstream `config.lua`.
- Crossing the prison's 200-unit perimeter in `client/prisonbreak.lua` clears the client's `inJail` and `jailTime`, triggers security lockdown and an alert, calls `prison:server:SetJailStatus(0)`, and calls `prison:server:GiveJailItems(true)`.
- The server's `GiveJailItems(true)` path clears the `jailitems` metadata **without returning the stored inventory**. This corrects the earlier mistaken description that escape returns belongings.
- `client/main.lua` returns a player to prison on character load only when `injail > 0`. The upstream escape path sets it to zero, so it does not automatically re-admit that escapee on reconnect.
- Other forks/versions may behave differently. Do not assume a configurable escape option exists without inspecting that fork.

**Parsons decision:** Unauthorized departure must not clear `parsons_hold`, erase `parsons_belongings`, discharge the patient, or grant items. Keep court/medical authority intact; return/recovery is a separate staff/security workflow. Treatment time pauses when a patient is outside the facility boundary, offline, or not yet checked in. The commitment and belongings records remain intact. Ensure the server—not the escaping client's self-report—validates departure and any timekeeping state.

## Approved facility boundary rule

Use a mapped PolyZone polygon instead of the legacy center-radius test. The user will provide polygon vertices and vertical limits for the facility and authorized outdoor grounds. The server must verify player position before counting treatment time. Time runs only for an online, checked-in patient within the polygon; it pauses outside or offline. The same polygon should inform unauthorized departure alerts. Departure never releases the patient or clears belongings. Until mapping is supplied, do not use old prison coordinates as a substitute. Existing timer and departure code still need implementation updates.
