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
- [ ] Confirm PS Dispatch installed version; optional `Config.Security.PSDispatch.enabled` defaults to false. Review dispatch codes and law-enforcement job filters.
- [ ] Confirm the gate doorlock export/event actually used on the development server.
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
