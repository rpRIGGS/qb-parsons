# qb-parsons

**Parsons Rehabilitation Center — Psychiatric & Rehabilitation Facility**

A PowerMoves RP-specific QBCore FiveM resource adapted from the original [qb-prison](https://github.com/qbcore-fivem/qb-prison) project.

> **PowerMoves RP only:** This adaptation is being designed and configured specifically for the PowerMoves RP server, its Parsons Rehabilitation Center interior, and its gameplay systems. It is **not** intended as a drop-in, general-purpose resource for other FiveM servers. This describes the project's intended support and compatibility, **not** a restriction on rights granted by the original GPL license.

## Overview

qb-parsons is planned to transform prison mechanics into a small psychiatric and rehabilitation facility with voluntary treatment, involuntary evaluation holds, court-ordered commitments, counseling, and secure patient accommodation.

**Development status (2026-11-06):** Active implementation. Stage 7 security logic includes the facility polygon checks, temporary sabotage/gate compromise states, `electronickit` and `gatecrack` item requirements, ox_lib skill checks, and an optional PS Dispatch adapter identifying Gruppe Sechs as reporting security company. These features are **not yet live-tested**; MLO mapping and the mapped gate door IDs and in-server qb-doorlock validation remain pending. Next development priority: review and restructure Stages 1–4 admission, reception check-in, rooms and authorized guard-shack checkout, before Stage 8. Some earlier qb-prison code remains and must not be treated as complete Parsons behavior.

## Planned Features

### Admissions and commitments
- Voluntary residential admissions and outpatient treatment
- Involuntary 72-hour psychiatric evaluation holds
- Court-ordered commitments and authorized extensions
- Intake, patient status, referrals, transfers, and discharge
- Real elapsed-time hold tracking, including while a player is offline
- No hold-time reductions from facility activities

### Patient rooms and belongings
- Individual room assignments
- Personal storage and secure handling of restricted belongings
- Patient clothing and wardrobe access
- Property return during authorized discharge

### Treatment and rehabilitation
- Individual and group counseling
- Substance-use and gambling-related treatment roleplay
- Recreational activities and supervised daily routines
- Outpatient appointments and follow-up visits

### Facility operations and security
- On-duty Parsons medical staff and authorized clinical admissions
- Controlled doors, perimeter gate, and guard shack
- Patient movement and access management
- Incident records and unauthorized departure / escape handling

## Parsons reception and security workflow (planned)

- **Arrival:** `/commit` transfer to an inside-gate arrival point with directions to reception, or physical transport to reception. Arrival alone does not start the playable commitment clock.
- **Medical reception:** Verify the commitment and room availability, secure belongings, assign a room, change into patient clothing, and complete check-in. Only then start the commitment's playable-time clock.
- **Guard shack:** Separate security guard PED for checking remaining time and processing **authorized** checkout. Reception can also provide status. Judicial clearance remains required for court commitments.
- **Checkout:** After authorization, return belongings, restore normal clothing, release the room, and place the patient outside the secured gate.
- **Security:** Adapt upstream qb-prison gate and breach mechanics to Parsons and its installed qb-doorlock; an unauthorized departure never clears the Parsons commitment or stored belongings. Unlike upstream qb-prison, escape must not auto-release a patient.
- **Rooms:** Limited capacity, persistent assignments, patient-specific door access subject to the installed qb-doorlock implementation. Patient rooms and MLO positions remain to be mapped.

**Implementation warning:** Existing admission code still starts the clock at `AdmitPatient`, teleports to old prison spawn placeholders, and uses one desk. These behaviors must be refactored before deployment. See [admission and security workflow](development-reference/PARSONS-ADMISSION-SECURITY-WORKFLOW.md).

## Framework and Planned Integrations

- QBCore (`qb-core`)
- `qb-target`
- PowerMoves RP customized `qb-inventory`
- `ox_lib`

The adaptation will retain the PowerMoves RP QBCore ecosystem; no migration to `ox_target` or `ox_inventory` is planned. Exact dependencies and setup steps will be documented as implementation progresses.

## Installation integration — qb-spawn (required before deployment)

The PowerMoves `qb-spawn` character-login spawn selector currently checks the QBCore `injail` metadata. **Preserve that check.** Add a separate Parsons check for an active `parsons_hold` so committed patients cannot select an unrestricted spawn location.

Illustrative condition for the existing spawn decision (adapt to the actual `qb-spawn` file and its variable names):

```lua
local metadata = PlayerData.metadata or {}
local hold = metadata.parsons_hold
local isParsonsPatient = type(hold) == 'table' and hold.active == true
-- Keep the existing injail branch unchanged; handle isParsonsPatient as
-- an additional branch before opening the ordinary spawn selector.
```

On an active Parsons hold, bypass ordinary spawn choices and use the Parsons admission/reconnect placement flow. Do **not** replace the original jail check, use `injail` for Parsons, or copy the placeholder prison coordinates into qb-spawn. This is an integration instruction, **not yet a tested drop-in patch**: inspect the installed PowerMoves `qb-spawn` version and confirm its event flow before editing it. Final Parsons MLO coordinates are still pending.

## Credits and License

Adapted from [QBCore qb-prison](https://github.com/qbcore-fivem/qb-prison). Original authors and contributors retain their respective credits. PowerMoves RP is responsible for its own adaptation.

The PowerMoves RP-only statement above is a compatibility and project-scope notice, not a change to the open-source license. The original license notice follows.

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>


## Current implementation references

- [Admission and security workflow / stage status](development-reference/PARSONS-ADMISSION-SECURITY-WORKFLOW.md)
- [Server mapping and integration checklist](development-reference/PARSONS-SERVER-MAPPING-CHECKLIST.md)

**Security integration:** `ox_lib` is required for current security skill checks. `qb-target` remains the target integration (E-key fallback when target mode is disabled). `ps-dispatch` is optional, controlled by `Config.Security.PSDispatch.enabled`, and has no legacy qb-policejob dispatch fallback. Security reports identify **Gruppe Sechs**; the front-gate security guard is planned as a Gruppe Sechs NPC. Item names and skill-check difficulty are configurable. No MLO coordinates or door IDs have been invented.

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

## Temporary court transport source checkpoint — 2026-11-06

Temporary court transport now has server-validated `parsons:server:TransportAction` checkout/return, guarded by on-duty `leo` job **type**, valid patient server ID, both parties within five meters of configured guard shack, and checked-in patient hold. The qb-target Gruppe Sechs guard offers checkout/return prompts using ox_lib inputDialog. The patient commitment, stored belongings and room reservation remain intact; transport pauses playable treatment time and does not count as unauthorized departure. Return requires both officer and patient at the guard shack. Trusted resources may inspect `GetTransportStatus`. Actual guard coordinates and FiveM testing remain pending. **Not yet complete:** defensive NPC behavior/assault alerts/respawn, patient door access, offline room-grace reconciliation and full admission acceptance tests. Court-ordered permanent discharge remains a distinct judicially authorized operation.

## Offline room-grace recovery checkpoint — 2026-11-06

Server room reservations now store a persistent absence timestamp per room. A once-per-minute server sweep releases configured room ownership when an absence reaches the 48-hour grace period, including when the patient is disconnected. The patient's commitment and belongings remain intact. On reconnect, missing room ownership marks the room reservation expired, pauses treatment eligibility, and reception can assign a new available room without taking belongings again. Authorized court transport does not start an unauthorized-absence timer. **Still requires testing:** disconnect/restart edge cases, resource KVP/player metadata consistency, doorlock access revocation, and MLO coordinates. Room allocation uses configured IDs only and must not be represented as a fully transactional database reservation system.

## Room integrity and Gruppe Sechs guard source checkpoint — 2026-11-06

Corrected reconnect reconciliation so an expired room reservation cannot recreate its old absence timestamp. Implemented initial local Gruppe Sechs guard AI at configured guard shack: nightstick, vulnerable ped, close defensive combat settings, assault/guard-down incident hooks, PS Dispatch labels/codes, 300-second respawn delay and 35-meter player-clear check. Guard positions remain nil until MLO mapping. **Not runtime-verified:** defensive combat/pursuit behavior, multi-client NPC synchronization, guard respawn, qb-target lifecycle and server verification of assault/down reports. Current guard threat endpoint validates reporting player's proximity and rate-limits alerts but cannot independently prove NPC damage; harden before production. Doorlock patient-room access and crash-safe room/metadata transaction recovery remain outstanding.
