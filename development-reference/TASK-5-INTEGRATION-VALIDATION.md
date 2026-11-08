# Task 5 — Integration and validation ledger

## Code integration reviewed and corrected
- qb-target is mandatory in config and reception/activity interactions; removed legacy non-target keypress fallbacks.
- Activity state refresh no longer invalidates the active client timer before comparing session identity.
- Activity start and completion validate active residential check-in, escape/transport/reentry restrictions, living ped, configured station, and facility polygon.
- Activity sessions remain server-owned and citizen-ID bound; cooldowns and completion history are server-authoritative.
- Stage 8 patient operations callbacks validate on-duty medical staff at reception. Staff assignments and shift notes are admission-scoped.
- Missing station coordinates are intentional disabled configuration entries, not guessed in code.
- Existing Stage 7 server-owned guard and scoped light fixture mapping remain in place; no global blackout or unverified qb-doorlock unlock event.

## FiveM deployment test matrix — outstanding, NOT performed by assistant
| Area | Test | Expected |
| --- | --- | --- |
| Startup | Ensure dependencies, start qb-parsons | No Lua/native errors; qb-target zones registered |
| Admissions | Medical, voluntary, outpatient, court admissions | Correct intake and custody rules |
| Reception | Check in residential patient | Room and belongings state persists |
| Rooms | Occupy, transfer, release, reconnect | Persistent KVP ownership and no duplicate allocation |
| Escape | Leave polygon, return, wait 48h | Incident, paused timer, inventory clearance, room expiry |
| Security | Sabotage, gate minigame, alarm reset | Server checks items, proximity, duration, duty |
| Lighting | Map MLO fixtures, trigger local sabotage | Parsons fixtures only; no global blackout |
| Guards | Attack/kill network ped, wait until area clears | Server incident and delayed respawn |
| Aircraft | Unauthorized low flight over polygon | Verified dispatch event and cooldown |
| Operations | On/off-duty staff at/away from reception | Authorized dashboard only |
| Assignments | Assign, clear, reconnect, readmit | Scoped to current admission, audited |
| Shift notes | Write/read, malformed input, readmit | Persist current admission only |
| Activities | Complete, cancel, disconnect, escape, cooldown | Server-verified history; no hold reduction |
| Resource restart | Restart with players online | Client state refresh, no duplicated peds/targets |
| Doorlock | Future separate qb-doorlock fork | No claim of physical gate or room enforcement |

## Mapping required from the actual Parsons MLO
- Security: inside/outside electrical panels, gate electronic panel.
- Lighting: fixture entity models and positions for local-only effects.
- Rehabilitation: each activity station position and bounds.
- Doorlock integration is explicitly a separate fork and is not represented as complete.

**Status:** Static integration corrections committed. Live deployment QA cannot be completed without a running PowerMoves FiveM server and the mapped MLO. Do not mark Task 5 as gameplay-tested.
