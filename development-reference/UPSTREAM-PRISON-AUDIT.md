# Upstream prison integration audit — 2026-11-06

**Scope:** Planning audit of public upstream `qbcore-fivem/qb-policejob`, `qbcore-fivem/qb-ambulancejob`, `qbcore-fivem/qb-core`, and the current `qb-parsons` fork. This is **not** a complete scan of PowerMoves' installed/customized police or ambulance forks. No gameplay code was modified.

## Confirmed jail authorization

**Only LEO is authorized by the upstream policejob server jailing handler.**

- `qb-policejob/server/interactions.lua`: `police:server:JailPlayer` validates `Player.PlayerData.job.type == 'leo'`, sets target `injail` metadata and `criminalrecord`, then fires `police:client:SendToJail`.
- `qb-policejob/client/main.lua`: `police:client:SendToJail` calls `prison:client:Enter`.
- `qb-policejob/client/interactions.lua`: `police:client:JailPlayer` collects jail time and sends `police:server:JailPlayer`.
- `qb-policejob/server/commands.lua`: `/jail` and `/unjail` are restricted to on-duty `leo` job type.
- `qb-ambulancejob/client/main.lua`: after leaving a hospital bed, if existing `injail` metadata is positive, it fires `prison:client:Enter` to resume a previously imposed jail sentence. This **does not** give EMS power to jail anyone.
- `qb-parsons/client/main.lua` (still original prison logic): `prison:client:Enter` permits invocation from qb-policejob and qb-ambulancejob. This is an invocation allowlist, **not** authorization to impose jail.
- `qb-core/config.lua`: default metadata includes `injail`, `jailitems`, and `criminalrecord`; these belong to criminal incarceration, not Parsons treatment.

## Files and references requiring conversion review

| Resource / path | Current prison-related behavior | Parsons action |
|---|---|---|
| `qb-parsons/fxmanifest.lua` | Prison description, prisonbreak and jobs scripts, PolyZone dependency | Rewrite manifest after auditing retained modules |
| `qb-parsons/config.lua` | Prison coordinates, prison jobs, prison uniforms and spawns | Replace with Parsons MLO, rooms, patient/staff locations |
| `qb-parsons/client/main.lua` | `inJail`, `jailTime`, `prison:client:Enter/Leave/UnjailPerson`, release desk, prison blips, inmate clothing, countdown | Distinct patient admission, room placement, real timestamps and authorized discharge |
| `qb-parsons/client/jobs.lua` | Prison work activities | Review for optional therapy/recreation; no sentence reduction |
| `qb-parsons/client/prisonbreak.lua` | Prison breakout and alerts | Remove or redesign for Parsons incident/unauthorized-departure RP |
| `qb-parsons/server/main.lua` | `prison:server:SetJailStatus`, `SaveJailItems`, `GiveJailItems`, `ResetJailItems`, lockdown, alarms, contraband and `injail` metadata | Namespaced Parsons admissions, belongings and incident state |
| `qb-parsons/locales/en.lua` | Prison and jail text | Rewrite every user-visible string in patient-centered language |
| `qb-parsons/locales/*.lua` | Additional locale translations | Audit all supported languages; avoid stale prison messages |
| `qb-policejob/server/interactions.lua` | LEO-only criminal jail event | **Do not modify qb-policejob**; Parsons commands belong in qb-ambulancejob |
| `qb-policejob/client/interactions.lua` | Jail-time dialog and server request | **Do not modify qb-policejob**; reuse flow concept in qb-ambulancejob |
| `qb-policejob/client/main.lua` | Jail transport event | Do not reuse prison:client:Enter for Parsons |
| `qb-policejob/server/commands.lua` | LEO /jail and /unjail | **Do not modify qb-policejob**; `/commit` and `/uncommit` belong in qb-ambulancejob |
| `qb-policejob/locales/en.lua` | Jail command labels and sentence notifications | **Do not modify qb-policejob**; Parsons labels belong in Parsons/ambulancejob |
| `qb-ambulancejob/client/main.lua` | Re-enters jail after hospital bed release | Preserve jail continuity; add distinct patient transport/handoff later |
| `qb-core/config.lua` | Criminal metadata defaults | Keep unchanged for prison; create separate Parsons patient/hold storage |

### Verified English locale examples

**Policejob:** `jail_time`, `jail_time_no`, `sent_jail_for`, `jail_time_input`, `jail_player`, `unjail_player`.

**Prison:** `injail`, `timeleft`, `freedom_blip`, `work_blip`, `police_alert_description`.

Do **not** replace all references to prison globally in policejob: criminal jail is still real gameplay. Instead, keep jail translations and add new Parsons-specific keys. In qb-parsons itself, replace correctional terminology with admission, evaluation hold, treatment, patient room, property, discharge and incident language.

## 5150-style authorization — important distinction

California Welfare and Institutions Code section 5150 permits peace officers and certain **designated/authorized facility staff and professionals** to initiate detention for psychiatric evaluation. It does **not** automatically grant that power to every licensed physician or every EMS employee solely because of their profession. California is inspiration; the existing PowerMoves law controls gameplay.

**Design proposal pending confirmation against PowerMoves law:**
- `leo`: authorized law enforcement initiation/custody/transport coordination under applicable law or court order.
- `ems`: **not blanket authority**. An appropriately qualified and designated medical doctor at a hospital may initiate a hold if PowerMoves law grants that authority, even if not a psychiatrist; the same applies to authorized psychiatric clinicians.
- Medical transport ambulance personnel can receive dispatch/transport requests without having clinical commitment authority.
- Court orders, clinician determinations, law-enforcement custody and Parsons facility acceptance are distinct steps and permissions.
- Grade 10 Parsons Psychiatrist has the already-planned independent clinical admission/hold authority when qualified and legally permitted.

**Technical design:** validate named clinical credential/authorization and legal basis server-side; do not infer from `job.type == 'ems'` alone. Keep patient status and 72-hour elapsed-time holds separate from `injail`, `jailitems`, and `criminalrecord`.

## Next audit / implementation tasks

- [ ] Review every line of current `qb-parsons/client/jobs.lua`, `client/prisonbreak.lua`, `server/main.lua` and all locales for prison-specific state/events/labels.
- [ ] Review all upstream policejob prison references and the exact PowerMoves-installed policejob version before changing another repository.
- [ ] Inspect upstream and installed ambulancejob for any additional jail/hospital crossovers.
- [ ] Check other QBCore resources that consume `injail` metadata (e.g. character login, radial menu, police menus, dispatch), without changing prison behavior.
- [ ] Obtain/confirm PowerMoves' existing 5150 law and exact physician/clinician designations before granting privileges.
- [ ] Specify separate server-validated `qb-parsons` API for hold request, legal basis, transport request, acceptance and discharge.
- [ ] Audit all English locale keys and other shipped locales; replace every prison-only label in qb-parsons.
- [ ] Update installation reference with tested file-by-file patches after implementation.

## Source repositories

- https://github.com/qbcore-fivem/qb-policejob
- https://github.com/qbcore-fivem/qb-ambulancejob
- https://github.com/qbcore-fivem/qb-core
- https://github.com/rpRIGGS/qb-parsons
- California statutory reference: https://codes.findlaw.com/ca/welfare-and-institutions-code/wic-sect-5150/

**Status:** Initial targeted upstream audit, not a claim of exhaustive repository-wide grep or completed integration.

## Task 1 complete — direct source-code audit (2026-11-06)

**Audited the actual current fork**: `fxmanifest.lua`, `config.lua`, `client/main.lua`, `client/jobs.lua`, `client/prisonbreak.lua`, `server/main.lua`, and `locales/en.lua`. This is a code-level audit, not an implementation or runtime test. The files still contain original prison gameplay.

### Reuse rather than rewrite

- `client/main.lua`: Keep the working fade-out, choose configured spawn, teleport, heading, optional clothing, fade-in sequence. Rename and adapt admission/discharge entry points; do not keep the `prison:client:Enter` event for Parsons.
- `client/main.lua`: Reuse the front-desk target/zone interaction pattern, but it must request **server-authorized discharge**; client `jailTime <= 0` must not authorize discharge.
- `server/main.lua`: Reuse inventory snapshot/clear/restore approach with **separate Parsons belongings** and safe idempotency. Preserve custom `qb-inventory` integration. Do not reuse `jailitems`.
- `config.lua`: Keep structured spawn and location configuration, replacing prison coordinates only after actual Parsons MLO locations are supplied. Do not guess MLO coordinates.
- `fxmanifest.lua`: Keep QBCore/locale and required dependency patterns; review module dependencies before removing scripts.

### Conversion blockers discovered

1. **Client controls criminal metadata:** `prison:server:SetJailStatus` directly accepts a client-supplied time and writes `injail`; client can also request `GiveJailItems`. Parsons needs server-authoritative admission, expiry and discharge with separate state. Never expose a client event that can freely set or clear a hold.
2. **Prison timer is online-only:** `client/main.lua` subtracts one minute every 60 seconds and saves remaining minutes. Replace with server-persisted real-world start/expiry timestamps, real-life day units, and non-expiring judicial status; do not let offline time freeze the hold.
3. **Job loss is automatic:** `server/main.lua` changes anyone with an active prison sentence to `unemployed`. This is **not** an approved Parsons consequence; do not carry it over.
4. **Inventory duplication/loss risk:** The current `SaveJailItems` snapshot, `ClearInventory`, and `GiveJailItems` events depend on `injail`, are client-invoked, and restore items without a full transactional guard. Parsons must protect against repeated intake/discharge, disconnects, restarts and unauthorized calls. Do not grant prison's $80 jail money.
5. **Work reduces sentence:** `client/jobs.lua` calls `jailTime -= math.random(1, 2)` on work completion and may give a phone. Remove time reduction entirely; any later Parsons activities must be treatment/recreation only, not hold reductions.
6. **Escape clears legal custody:** `client/prisonbreak.lua` resets `inJail` and `jailTime`, triggers `SetJailStatus(0)`, and clears belongings on escape. Parsons escape RP must **not** clear an active medical hold or judicial order. The prison gate coordinates, gate IDs, alarms, and minigames are unrelated to the Parsons MLO; don't migrate them blindly.
7. **Old prison resource dependencies:** `client/main.lua` calls global `CreateJobBlip` from `client/jobs.lua`, so deleting jobs from `fxmanifest.lua` without first adapting main would break admission. `client/prisonbreak.lua` also defines the prison alarm events used during login. Remove these references together in a controlled conversion.
8. **Old client-side unjail:** `prison:client:UnjailPerson` handles property return and release client-side. Parsons `/uncommit` must be validated by the server against current hold authority and court orders.
9. **Old coordinate bug:** `client/prisonbreak.lua` references `Config.Locations['middle'].coords` even though `config.lua` defines `middle` as a direct `vector4`. This is an upstream inconsistency, not a Parsons design to preserve.
10. **Localization:** `locales/en.lua` includes prison months, sentence reduction, criminal escape and jail front desk messages. Rename into patient/hold/discharge terminology alongside the corresponding code, rather than cosmetically changing strings while old prison flows remain active.

### Approved implementation sequence after audit

- [x] **Task 1:** Inspect source and identify safe reuse and blockers (this audit).
- [ ] **Task 2:** Convert Parsons-specific naming, configuration, and client admission/discharge flow together; retain prison's working teleport and intake foundation. Do not ship a manifest that calls missing prison jobs or alarm functions.
- [ ] **Task 3:** Replace online prison minutes with server-authoritative, persisted real-day holds (3/7/28-day total medical windows, court-defined real days, and indefinite judicial status).
- [ ] **Task 4:** Adapt prison belongings and admission/release mechanics to Parsons state with idempotent, authorized server events; ensure court orders cannot be discharged medically.
- [ ] **Task 5:** Integrate and test the initial Parsons foundation, then make the completion commit(s). Actual MLO spawn/desk coordinates and PS-MDT authorization contracts are external dependencies, not reasons to invent placeholders as tested locations.

**Transport clarification:** Transport is optional RP **before** `/commit`; the command directly admits the nearby patient. No scripted transport selection or `99999` prison sentence convention. The prison `/jail` and `/unjail` remain untouched.

## Current fork implementation delta (2026-11-06)

The earlier upstream audit sections document the **state at audit time** and should not be read as today's live code inventory. Parsons now has `server/security.lua`, `client/security.lua`, and `client/dispatch.lua`, a configurable facility polygon, `ox_lib` skill checks, and `electronickit`/`gatecrack` requirements. The PS Dispatch adapter is optional and has no legacy policejob fallback; security reports are from **Gruppe Sechs**. The existing qb-policejob criminal jail flow is intentionally untouched. Physical gate qb-doorlock hookup, remaining Stage 7 hardening and runtime verification are pending. Approved order is to finish Stage 7 code, then restructure Stages 1–4 admission/reception/checkout before Stage 8. This addendum supersedes old audit claims that no security implementation exists, but does not erase historical findings.
