# Parsons admission, checkout, rooms and security — approved design handoff

Status (2026-11-06): approved design plus partial Stage 7 implementation; not live-tested. Real Parsons MLO coordinates and actual qb-doorlock configuration are pending. Stages 1–4 require restructuring before Stage 8.

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
- Original upstream `qb-prison/client/escape.lua` has three gate points, electronic-kit/gatecrack item checks, hacking minigame, `qb-doorlock:server:updateState`, lockdown, alerts, and an escape check that **clears prison jail status and clears the jail-items record**. It does not return the belongings on escape.
- Parsons should **adapt**, not erase, that design: a smaller, facility-appropriate breach/escape scenario, using the actual Parsons gate and installed doorlock. Never port upstream jail-status clearing, belongings-record clearing on escape, or automatic discharge.
- Current `client/escape.lua` contains only perimeter monitoring; original hacking/gate functionality was removed from the fork. Stage 7 must intentionally rebuild/adapt it, with server-authoritative validation and no untrusted client ability to unlock doors.

## Activities and facility work

- Stage 6: pool, tennis, yoga, garden meditation, gardening, raking, laundry, and cafeteria occupational tasks; optional stress relief and admission-specific participation history. No sentence reductions.
- The cafeteria has a separate supply storage room: restocking and kitchen duties can be multi-step work activities. Patient meals are free and available regardless of whether a player is working in the cafeteria.
- Stage 8: room inventory and check-in/out workflows, staff-facing participation, free cafeteria service, medical workstations and pharmacy planning.
- Stage 9: clinical record integration with SAMS.net and authorized court-ordered commitment updates to SADOJ.net. Participation data is not an automatic clinical assessment.

## MLO config points to capture

Reception PED, inside-gate arrival, guard shack PED, outside checkout destination, patient rooms and doors, front gate and doorlock ID, security perimeter, activity stations, cafeteria kitchen and food-storage room. Existing prison coordinates are placeholders, not final Parsons positions.

## Verified upstream escape behavior (qbcore-fivem/qb-prison)

Reviewed upstream `config.lua`, `client/escape.lua`, `client/main.lua`, and `server/main.lua` on 2026-11-06:

- No configurable escape-time reset/continuation option was found in upstream `config.lua`.
- Crossing the prison's 200-unit perimeter in `client/escape.lua` clears the client's `inJail` and `jailTime`, triggers security lockdown and an alert, calls `prison:server:SetJailStatus(0)`, and calls `prison:server:GiveJailItems(true)`.
- The server's `GiveJailItems(true)` path clears the `jailitems` metadata **without returning the stored inventory**. This corrects the earlier mistaken description that escape returns belongings.
- `client/main.lua` returns a player to prison on character load only when `injail > 0`. The upstream escape path sets it to zero, so it does not automatically re-admit that escapee on reconnect.
- Other forks/versions may behave differently. Do not assume a configurable escape option exists without inspecting that fork.

**Parsons decision:** Unauthorized departure must not clear `parsons_hold`, erase `parsons_belongings`, discharge the patient, or grant items. Keep court/medical authority intact; return/recovery is a separate staff/security workflow. Treatment time pauses when a patient is outside the facility boundary, offline, or not yet checked in. The commitment and belongings records remain intact. Ensure the server—not the escaping client's self-report—validates departure and any timekeeping state.

## Approved facility boundary rule

Use a mapped PolyZone polygon instead of the legacy center-radius test. The user will provide polygon vertices and vertical limits for the facility and authorized outdoor grounds. The server must verify player position before counting treatment time. Time runs only for an online, checked-in patient within the polygon; it pauses outside or offline. The same polygon should inform unauthorized departure alerts. Departure never releases the patient or clears belongings. Until mapping is supplied, do not use old prison coordinates as a substitute. Existing timer and departure code still need implementation updates.

## Implementation progress — 2026-11-06

- Server treatment timer now checks the configured polygon and `hold.checkedIn == true` before counting. It requires consecutive eligible samples to avoid charging an interval spent outside the facility.
- Server unauthorized-departure verification uses the same polygon instead of the old center-radius test.
- Client departure hints now use PolyZone with configured vertices and Z limits. No polygon is active until the real MLO is mapped.
- **Important pending dependency:** Current admission flow has not yet been refactored into pending arrival plus reception check-in, so no existing hold has `checkedIn == true`; the timer intentionally does not advance until that workflow is implemented. Room assignment, inventory custody at reception, patient clothes, guard shack checkout, and live FiveM verification remain outstanding.
- Existing `AdmitPatient` still stores belongings immediately and client admission still teleports to prison placeholders. Do not deploy as complete.

## Return after unauthorized departure — confirmed

A patient who previously completed reception check-in does NOT repeat intake when returned after an unauthorized departure. Keep `checkedIn = true`, the same admission and remaining treatment time, assigned room and door permissions, patient clothing, secured belongings and participation history. Outside the facility polygon the treatment clock is paused; on server-verified re-entry while online, it resumes automatically without a reception interaction. Recovery/transport is a security and medical workflow, not a new admission, discharge or inventory transfer. Only initial reception check-in creates the room assignment and secures belongings; only authorized guard-shack checkout ends the admission and returns them. The current implementation still requires reception and room-access integration; this is an approved behavior specification.

## Room reservation on unauthorized absence

Approved: 48 real-world hours, configurable as Config.EscapeRoomGraceHours. An escaped patient retains their reserved room during that grace period. Once the absence exceeds 48 hours, the room can be released and door access revoked, while the commitment, belongings and participation history remain. At reception, Return to Treatment restores patient clothing and assigns the old room if vacant, otherwise another available room. If no room is free, staff must resolve capacity; no double-booking. Re-entry resumes treatment time without requiring a new admission. Persist the departure timestamp across disconnects and restarts. Actual room and doorlock integration remains pending MLO identifiers and API verification.

## Revised stage sequence — 2026-11-06

- Stages 1–4: commitment and belongings foundations exist, but admission must move to a two-phase pending-arrival and reception-check-in workflow. Do not call the entire workflow complete.
- Stage 5: safeguards written; live FiveM testing remains pending.
- Stage 6 (current): activities and participation foundations. Activity finish resync corrected; recreation and occupational activity definitions added. Station coordinates, animation integration, participation history, and live tests remain.
- Stage 7: perimeter and unauthorized-departure PolyZone foundations committed. Gate breach adaptation, security response, and recovery remain.
- Stage 8: reception, return-to-treatment, 48-hour room grace, room/bed allocation, patient clothing, door access, guard-shack checkout, cafeteria, and facility operations. The 48-hour absence tracking exists but room release and reassignment are not operational yet.
- Stage 9: qb-ambulancejob, SAMS.net, SADOJ.net, qb-spawn, and prescription-system integration after checking installed APIs.

Development order: complete Stage 6 non-MLO logic; implement pending admission and reception as prerequisite for playable time; finish Stage 7 recovery and Stage 8 room and staff flows; then Stage 9 integrations and comprehensive tests. Never claim old prison coordinates are usable Parsons locations.

## Stage 6 code checkpoint

The activity subsystem now uses server-side completion, validates the patient's active checked-in hold and station proximity, maintains per-admission participation history (last 100 completions), enforces cooldowns, and supports optional configured stress relief. All activity station coordinates remain deliberately unmapped. Stage 6 cannot be considered live-verified until the facility is mapped and the FiveM runtime is tested. Future presentation work may add activity-specific animations and props without changing server authority.

## Stage 6 implementation complete — pending in-game validation

- Activity definitions cover therapy, recreation, rehabilitation, swimming, tennis, yoga, meditation, gardening, groundskeeping, laundry, kitchen preparation, dishwashing, restocking and cleaning.
- Target and E-key interactions share the same server-authoritative station checks, active admission checks, duration and cooldown logic.
- Server completes elapsed sessions while the patient remains eligible and at the station, stores the most recent 100 participation entries on the admission, and optionally reduces stress by a capped configured amount. Activities never pay or shorten commitments.
- Configurable GTA scenario presentation is supported where assigned; presentation is cleaned up on cancellation, completion, character unload and resource stop. Unmapped or unsupported scenarios can remain unset.
- Activity station locations are inactive placeholders. In-game verification remains outstanding, not a reason to reopen the Stage 6 code milestone. Proceed to Stage 7 security and recovery implementation.

## Stage 7 implementation checkpoint

Server-side polygon sampling now detects verified inside-to-outside departures and outside-to-inside returns, independently of client hints. Active commitments and belongings remain intact. Reconnecting no longer forcibly teleports an escaped patient to upstream prison spawns. A restricted server export provides recovery status for future authorized staff integration. A new departure requires an observed transition from inside, preventing initial loading outside from being mistaken for a fresh escape. The 48-hour room grace remains tied to persisted absence timestamps. Still outstanding: mapped gate interactions, doorlock integration, dispatch presentation, staff recovery interaction, and live runtime verification. Existing initial admission/reception workflow remains a blocker to operational testing.

## Approved Stage 7 security design — November 6, 2026

One and only one facility PolyZone encloses the fenced Parsons property, including authorized recreation grounds and the gate. Its minZ/maxZ govern patient presence and the low-aircraft detection ceiling; no second aircraft polygon. An aircraft driven by a player and observed within this 3D volume for the configurable verification interval emits a suspicious-aircraft incident, with a cooldown to avoid repeated alerts. The system does not assume a helicopter landing or patient escape.

Normal security remains unlocked from lockdown unless a genuine breach warrants it. Both an interior-accessible electrical panel and an exterior utility box may be configured, depending on the MLO; direct gate hacking remains a separate option. Power disruption can affect gate electronics, monitoring and perimeter lighting where map assets support it; never promise baked MLO lights can be switched off. A power/communications failure should generate an initial law-enforcement security-check call attributed to private security monitoring, without declaring a patient escaped. A verified departure escalates to unauthorized-patient-departure and authorized SAMS notification. Return closes or updates the same operational incident. The guard shack NPC is a check-in/out interaction, not a simulated security workforce. Dispatch and MDT adapters must use verified installed APIs and respect medical confidentiality.

### Current implementation and remaining work
- Existing server-side polygon transitions preserve patient commitments and belongings; treatment clock only runs while checked in and inside.
- `server/security.lua` now performs server-observed player-piloted aircraft detection in the **same** polygon, with a verification delay and cooldown; emits `parsons:security:Incident` server event. Departure and return events also produce security incident records. This is an integration event, **not yet a delivered police dispatch or MDT alert**.
- `Config.Security` provides unmapped electrical and gate interaction placeholders and timing options. Sabotage gameplay, power effects, gate-hack minigame, dispatch/MDT adapters, doorlock integration and in-server validation are still pending.
- Stages 1–4: admissions, discharge and belongings foundations; reception check-in refactor pending. Stage 5: safeguards groundwork, testing pending. Stage 6: code milestone complete, runtime validation pending. **Stage 7: active, expanded security implementation.** Stage 8: reception/rooms/48-hour grace/guard shack/cafeteria. Stage 9: qb-ambulancejob, SAMS/SADOJ, spawn and medical integrations.

## Stage 7 security implementation continuation

- Optional `Config.Security.PSDispatch.enabled` (default false) and configurable dispatch codes/jobs; the client adapter uses Project Sloth's verified `exports['ps-dispatch']:CustomAlert` interface, and the server selects an on-duty police responder to publish each alert once. This is a configurable police alert, not yet an SAMS/SADOJ record integration.
- Electrical and gate actions now have configurable qb-target/E-key interaction points, an ox_lib skill-check minigame, required `electronickit` or `gatecrack`, and server-verified distance, inventory, action identity and elapsed time. A cancelled attempt does not alter security state. The skill checks use configurable electrical/gate difficulty and input keys; actual gate-door unlock is intentionally delegated to `parsons:security:GateStateChanged` until the mapped qb-doorlock ID and installed API are known.
- Security state has timed power/gate compromise and restoration, server event updates, a limited history, and correlated incident identifiers. Patient departure/return security events now fire after metadata persistence.
- The same property polygon checks player-piloted low aircraft, without a second zone.
- **Stage 7 remaining runtime-dependent work:** configure the Parsons property polygon, electrical/gate positions, doorlock identifiers and map lighting capabilities; wire verified qb-doorlock API; validate server-side aircraft natives, PS Dispatch calls, game interaction and staff/medical alert behavior in FiveM. Do not describe Stage 7 as fully live-tested or operational before these checks.
- **Required next development milestone before Stage 8:** restructure Stages 1–4 into pending arrival, reception check-in/belongings and authorized guard-shack checkout. This is an explicit user-approved order.

## Latest decisions — 2026-11-06

- **Security company:** Rockstar's **Gruppe Sechs** (not Group Six). The guard-shack NPC at the front gate must represent Gruppe Sechs. Police dispatch alerts must identify **Gruppe Sechs as the reporting company**, rather than inventing a generic security-check caller. Group-wide notifications beyond Parsons are future scope.
- **Items:** electrical tampering requires configurable `electronickit`; gate hacking requires configurable `gatecrack`. No thermite or general repair kit for these actions.
- **ox_lib:** loaded in `fxmanifest.lua` and required for the configurable security `lib.skillCheck` minigames; planned for reception and guard-shack menus when Stages 1–4 are rebuilt. QBCore, qb-target and customized qb-inventory remain.
- **Dispatch:** PS Dispatch adapter is coded inside qb-parsons (`server/security.lua`, `client/dispatch.lua`), optional through `Config.Security.PSDispatch.enabled`. No automatic qb-policejob legacy fallback. The client CustomAlert bridge and configured codes require live server validation.
- **Current outstanding code:** gate qb-doorlock runtime verification, remaining security validation/feedback review, and end-to-end incident review. Missing MLO positions and installed door IDs are separately tracked as runtime mapping dependencies, not reasons to block source-code progress.

**Source terminology update (2026-11-06):** `client/escape.lua` replaces upstream `client/prisonbreak.lua`; `client/activities.lua` replaces `client/jobs.lua`. Activity definitions use `Config.Activities` and stations use `Config.Locations.activities`. The original prison spawn/desk placeholders and remaining admission lifecycle terms are intentionally reserved for the Stages 1–4 conversion; do not deploy them as Parsons coordinates.

**Stage 7 gate adapter update (2026-11-06):** `Config.Security.gate.doorIds = {}` is deliberately empty until actual Parsons gate door IDs are mapped. On verified gate compromise, `server/security.lua` now invokes the upstream `qb-doorlock:server:updateState` API to unlock configured IDs and requests relock on expiry; electrical outages do not unlock gates. The installed doorlock fork/API, permission behavior, disconnect/restart edge cases and live relock behavior require in-server verification before operational signoff.

## Stage 7 code milestone — 2026-11-06

- Source implementation is complete for the **configured** security interactions, server incident reporting, one property polygon, aircraft checks, gate compromise/relock adapter, and PS Dispatch reporting. `Config.Security.PSDispatch.enabled = true` is the approved default, with no legacy policejob fallback.
- `electronickit` and `gatecrack` use ox_lib skill checks. Server validates action token, elapsed time, inventory and proximity, and acknowledges the applied result. A client skill-check result cannot be independently proven by the server; do not describe it as cheat-proof.
- Gate relock retries when a doorlock resource or player is temporarily unavailable; best-effort relock is attempted on Parsons resource stop. Unexpected process crashes/restarts and installed qb-doorlock variations still need live testing and operational recovery procedures.
- **Stage 7 code milestone is complete; runtime acceptance is not.** Before enabling mapped interactions in production: supply actual gate door IDs and Parsons MLO positions, test dispatch/doorlock/aircraft behavior in FiveM, and verify recovery after disconnects/restarts. Next source-development focus is the approved Stages 1–4 admission/reception/checkout refactor, not Stage 8.

## Current security implementation checkpoint — 2026-11-06

- Approved benchmark now configured: gate compromise **300 seconds**, electrical disruption **300 seconds**, and security alarm failsafe **300 seconds** (from the upstream qb-prison five-minute alarm reference; these remain adjustable). A timed electrical disruption is **not** yet a visual MLO blackout.
- Failed gate hacking raises a security alarm and sends a distinct PS Dispatch attempted-tampering incident. Successful hacking retains gate compromise and relock handling. Alarm acknowledgment/reset is independent of restoring gate or electrical equipment.
- `Config.Security.alarm.resetPoints = {}` accepts multiple qb-target alarm reset stations (guard shack and medical offices to be mapped). Server checks interaction proximity and on-duty QBCore job **type** `leo` or `ems`. A five-minute alarm failsafe prevents indefinite active alarms. No slash reset command is required.
- Aircraft exemption uses the on-duty pilot's QBCore job type `leo`, `ems`, or `fire`. The user's actual PowerMoves-PSDispatch fork exposes `CustomAlert`; Parsons is configured to use PS Dispatch only.
- Gruppe Sechs guard nightstick, defensive AI, injury/death alerts, respawn delay and player-clear radius are **approved but not yet operationally implemented**. `Config.Security.guard` holds provisional settings. The local-only blackout and actual MLO light control are **not yet implemented**; do **not** invoke global qb-weathersync blackout.
- Approved court-transport workflow: on-duty LEO may check out a patient temporarily through authorized guard interaction, with the commitment, room/belongings and treatment hold preserved. Returning from authorized transport must not be counted as escape. Separate judicially authorized permanent uncommit remains available. **Not implemented yet**; reconcile in Stages 1–4.
- Still require user-provided MLO PolyZone vertices/Z limits, actual qb-doorlock gate/room IDs, guard and reception vectors, electrical panels, and reset-station vectors. Do not substitute legacy prison coordinates. Source code is not yet live FiveM acceptance-tested.

## Stages 1–4 implementation reconciliation — 2026-11-06

Commits `05400d2`, `2ad1c7e`, `7374c03`, `50ccba5` begin the actual code reconciliation. The live config no longer contains legacy qb-prison arrival/desk/spawn/outside coordinates. New commitments remain pending reception check-in; `AdmitPatient` no longer clears inventory on order creation. Client admission teleports only to mapped `Config.Arrival`, and discharge only to mapped `Config.Release`. Reception offers a check-in action, but the server **intentionally blocks final check-in** until safe room allocation/custody transaction is implemented. This prevents an incomplete intake from taking belongings or starting treatment time. Do not represent reception, patient rooms, temporary LEO transport or checkout as finished. Further code reconciliation and MLO mapping remain required.

## Reception and room allocation code checkpoint — 2026-11-06

Implemented in source: mapped `Config.PatientRooms` allocation on reception check-in, per-room resource KVP ownership across disconnects/restarts, custody capture only after an available room is selected, server-confirmed patient clothing, and room release on discharge or processed 48-hour absence expiry. Disconnect records absence without issuing an escape incident. Intake refuses to proceed without mapped rooms or on failed custody storage. **Not yet production-ready:** actual room/doorlock vectors and access controls, offline room-grace reconciliation while the patient remains disconnected, crash-safe atomicity between resource KVP and player metadata, temporary LEO transport, and FiveM runtime verification. Room IDs must be stable unique strings in `Config.PatientRooms`. Do not claim these remaining features are implemented.
