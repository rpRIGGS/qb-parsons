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
- [ ] Confirm the installed hacking minigame resource/API if a skill-based hack is desired rather than the existing timed interaction.
- [ ] Confirm actual QBCore items `electronickit` and `gatecrack` are available.
- [ ] For Stage 9, confirm qb-ambulancejob, SAMS.net, SADOJ.net and qb-spawn interfaces.

## Not required from you right now
No new architectural decisions, second PolyZone, NPC security department, or extra coordinates. The 48-hour room grace and patient hold preservation are already approved. Unmapped features must remain disabled safely rather than use prison coordinates.
