# Parsons — in-server mapping and integration checklist

**This is the consolidated list of inputs to collect when you are at the PowerMoves development server.** None of these placeholders blocks the Stage 7 code milestone. Keep the actual coordinates out of upstream qb-prison.

## 1. Single fenced-property PolyZone
- [ ] Export the complete fence/gate perimeter polygon vertices in order (vector2 X/Y).
- [ ] Record **minZ** for accessible grounds and **maxZ** as the shared property/low-aircraft detection ceiling.
- [ ] Verify all authorized outdoor areas and rooms fall inside; low aircraft within the same 3D volume should trigger detection.

## 2. Security interaction positions
- [ ] Internal electrical panel interaction (optional) — vector4, or explicitly disable.
- [ ] External utility/substation interaction (optional) — vector4, or explicitly disable.
- [ ] Gate electronics hacking point — vector4.
- [ ] Gate bypass point, if separate — vector4.
- [ ] Actual qb-doorlock gate door identifier(s) and the installed qb-doorlock version/API.
- [ ] Which nearby light fixtures can really be controlled by scripts (versus baked MLO lighting).

## 3. Facility admission and operations (Stages 1–4, 8)
- [ ] Inside-gate arrival position — vector4.
- [ ] Reception desk/NPC position — vector4.
- [ ] Guard-shack NPC/checkout position — vector4.
- [ ] Outside-gate discharge position — vector4.
- [ ] Patient room list, doorlock IDs, bed/interaction points, and room capacity.
- [ ] Activity station positions (therapy, recreation, rehabilitation, swimming, tennis, yoga, meditation, gardening, raking, laundry, food preparation, dishwashing, restocking, cleaning).
- [ ] Cafeteria shop/food pickup and staff interaction positions.

## 4. Installed integrations to verify
- [x] Reference fork identified: `rpRIGGS/PowerMoves-PSDispatch`; verified `client/alerts.lua` exports `CustomAlert` with `coords`, `dispatchCode`, `code`, `jobs`, `priority`, `sprite`, and `length`. `Config.Security.PSDispatch.enabled` is true.
- [ ] Verify that the development server is running this fork under resource name `ps-dispatch`, and check actual law-enforcement job filters/codes in-game.
- [x] Checked upstream qb-doorlock `server.lua`: `qb-doorlock:server:updateState` is available with `sentSource` and `unlockAnyway` arguments; Parsons adapter uses it.
- [ ] Verify installed server doorlock fork and gate IDs in-game.
- [ ] Verify the installed `ox_lib` version supports `lib.skillCheck` and test configured electrical/gate difficulties in-game (the skill-check integration is already coded).
- [ ] Confirm actual QBCore items `electronickit` and `gatecrack` are available in the installed customized qb-inventory.
- [ ] For Stage 9, confirm qb-ambulancejob, SAMS.net, SADOJ.net and qb-spawn interfaces.

## Not required from you right now
No new architectural decisions, second PolyZone, NPC security department, or extra coordinates. The 48-hour room grace and patient hold preservation are already approved. Unmapped features must remain disabled safely rather than use prison coordinates.

## Approved reporting and NPC identity

- Front security gate guard: **Gruppe Sechs** uniform/NPC; confirm suitable Rockstar ped model in-game.
- Parsons police alerts: **Gruppe Sechs** is the reporting security company, via optional PS Dispatch. No legacy dispatch fallback.
- The security minigames use `ox_lib` (not an additional hacking resource); no new sabotage items are required.

**Stage 7 gate adapter update (2026-11-06):** `Config.Security.gate.doorIds = {}` is deliberately empty until actual Parsons gate door IDs are mapped. On verified gate compromise, `server/security.lua` now invokes the upstream `qb-doorlock:server:updateState` API to unlock configured IDs and requests relock on expiry; electrical outages do not unlock gates. The installed doorlock fork/API, permission behavior, disconnect/restart edge cases and live relock behavior require in-server verification before operational signoff.

## Stage 7 code milestone — 2026-11-06

- Source implementation is complete for the **configured** security interactions, server incident reporting, one property polygon, aircraft checks, gate compromise/relock adapter, and PS Dispatch reporting. `Config.Security.PSDispatch.enabled = true` is the approved default, with no legacy policejob fallback.
- `electronickit` and `gatecrack` use ox_lib skill checks. Server validates action token, elapsed time, inventory and proximity, and acknowledges the applied result. A client skill-check result cannot be independently proven by the server; do not describe it as cheat-proof.
- Gate relock retries when a doorlock resource or player is temporarily unavailable; best-effort relock is attempted on Parsons resource stop. Unexpected process crashes/restarts and installed qb-doorlock variations still need live testing and operational recovery procedures.
- **Stage 7 code milestone is complete; runtime acceptance is not.** Before enabling mapped interactions in production: supply actual gate door IDs and Parsons MLO positions, test dispatch/doorlock/aircraft behavior in FiveM, and verify recovery after disconnects/restarts. Next source-development focus is the approved Stages 1–4 admission/reception/checkout refactor, not Stage 8.

## Approved decisions already applied

The following are **not** open design placeholders: Gruppe Sechs reporting identity, PS Dispatch adapter, `electronickit` electrical item, `gatecrack` hacking item, ox_lib skill checks, qb-target interaction support, one property polygon, no automatic power-outage gate opening, and 48-hour room reservation grace. Source values are already present in `config.lua`. Do not ask for these decisions again.

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

## Temporary court transport source checkpoint — 2026-11-06

Temporary court transport now has server-validated `parsons:server:TransportAction` checkout/return, guarded by on-duty `leo` job **type**, valid patient server ID, both parties within five meters of configured guard shack, and checked-in patient hold. The qb-target Gruppe Sechs guard offers checkout/return prompts using ox_lib inputDialog. The patient commitment, stored belongings and room reservation remain intact; transport pauses playable treatment time and does not count as unauthorized departure. Return requires both officer and patient at the guard shack. Trusted resources may inspect `GetTransportStatus`. Actual guard coordinates and FiveM testing remain pending. **Not yet complete:** defensive NPC behavior/assault alerts/respawn, patient door access, offline room-grace reconciliation and full admission acceptance tests. Court-ordered permanent discharge remains a distinct judicially authorized operation.

## Offline room-grace recovery checkpoint — 2026-11-06

Server room reservations now store a persistent absence timestamp per room. A once-per-minute server sweep releases configured room ownership when an absence reaches the 48-hour grace period, including when the patient is disconnected. The patient's commitment and belongings remain intact. On reconnect, missing room ownership marks the room reservation expired, pauses treatment eligibility, and reception can assign a new available room without taking belongings again. Authorized court transport does not start an unauthorized-absence timer. **Still requires testing:** disconnect/restart edge cases, resource KVP/player metadata consistency, doorlock access revocation, and MLO coordinates. Room allocation uses configured IDs only and must not be represented as a fully transactional database reservation system.
