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
| `qb-policejob/server/interactions.lua` | LEO-only criminal jail event | Add **separate** Parsons referral/custody request, preserve jail |
| `qb-policejob/client/interactions.lua` | Jail-time dialog and server request | Add separate Parsons request UX; not a prison sentence field |
| `qb-policejob/client/main.lua` | Jail transport event | Do not reuse prison:client:Enter for Parsons |
| `qb-policejob/server/commands.lua` | LEO /jail and /unjail | Preserve criminal incarceration; Parsons should use qb-target/menu workflow |
| `qb-policejob/locales/en.lua` | Jail command labels and sentence notifications | Keep original jail labels for jail; add distinct Parsons labels where needed |
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
