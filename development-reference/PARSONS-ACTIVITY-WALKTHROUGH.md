# Parsons Rehabilitation Center — detailed in-game activity mapping and development reconciliation

**Working checklist — 2026-11-06.** Open this file on a second monitor while touring the PowerMoves development server. Record **real** `vector4(x, y, z, heading)` values. For a multi-position activity, capture each usable interaction separately. Do not invent coordinates or use qb-prison placeholders.

## How to record each point
For every station: (1) stand where the patient/staff will interact and capture `vector4`; (2) note the prop or surface being targeted and whether it is a mapped object or a spawned prop; (3) note who may use it (patient, medical staff, kitchen staff, security); (4) note whether it is a single action or multiple pickup/work/return points; (5) note any relevant qb-doorlock entry and whether the door is normally open. **Heading is the fourth vector4 component**, not a separate field. If a location is unsuitable or the MLO has no matching prop, write **NOT PRESENT** rather than guessing.

## Already mapped — do NOT collect again
- [x] One 46-point facility polygon in `Config.FacilityZone`. Current `minZ=177.0` (basement doors approximately Z 177.15); `maxZ=189.31729125977` provisional. User may refine maxZ via devPoly. **Do not remap polygon unless testing shows an issue.**
- [x] Reception medical PED 1: `vector4(-1501.46, 849.16, 181.60, 249.10)`
- [x] Reception medical PED 2: `vector4(-1514.51, 848.23, 181.60, 114.20)`
- [x] Gruppe Sechs guard shack PED: `vector4(-1486.85, 881.13, 183.35, 341.37)`
- [x] Arrival: `vector4(-1523.8, 854.92, 181.59, 36.46)`
- [x] Release: `vector4(-1475.89, 881.74, 182.98, 301.48)`
- [x] Medical boss menu: `vector4(-1493.83, 860.13, 180.6, 115.0)` (**coordinate saved; interaction not yet wired**)
- [x] Existing qb-doorlock IDs from supplied Parsons configuration:
  - Standard bedrooms: `Parsons-Main Floor med ward 4`, `5`, `6`, `7` (four distinct full IDs, each prefixed as first).
  - Secure bedrooms: `Parsons-Basement 7`, `8`, `9`, `10`.
  - Padded observation: `Parsons-Basement 5`, `6`; **not** ordinary bed assignments.
  - Basement secure partition: `Parsons-Basement 11` (confirm physical gate in game).
  - Main perimeter gate: `Parsons-Security ring` (sliding gate, supplied locked by default).
  - Other doors include clinic, office, lobby, meeting rooms, storage, kitchen, laundry, and cafe.
- [x] `parsonsmed` job permission appears in supplied qb-doorlock config. **Do not change user's existing doorlock definitions merely to populate this checklist.**

## IMPORTANT — basement security and breakout route clarification (2026-11-06)

**Approved physical layout:** Four secure, windowless brick-walled basement rooms have solid doors, beds, sinks and separate toilets. These are the likely placement for higher-security/judicial patients; **judicial admission and security classification remain separate decisions** until policy is finalized. The secure ward also contains one padded observation room. A separate padded room is outside the secure partition. Do not assign padded rooms as ordinary bedrooms.

**Breakout barriers:** The perimeter sliding gate (`Parsons-Security ring`), the secure basement ward partition (`Parsons-Basement 11`, verify physical correspondence), and each assigned secure cell door (`Parsons-Basement 7` through `10`) are distinct security controls. A person breaking out a basement patient must have a physical route into the building and down to the ward; opening only the exterior gate does not free a patient behind locked basement doors. Document whether intermediate main-building doors require access and how the power/security system affects them.

**Electrical sabotage — two required mapping points, not optional omissions:**
- [ ] **Interior power station / electrical panel:** `vector4(x, y, z, heading)` — exact target prop and room/access route: `________________`
- [ ] **Exterior utility / power station:** `vector4(x, y, z, heading)` — exact target prop and access route: `________________`
- [ ] **Front gate electronics hack/bypass:** `vector4(x, y, z, heading)` — whether one or two points: `________________`
- [ ] **Security alarm reset at guard shack:** `vector4(x, y, z, heading)`: `________________`
- [ ] **Security alarm reset at medical office:** `vector4(x, y, z, heading)`: `________________`

**Open design decision, not implemented:** A successful electrical attack may temporarily release designated electronic security locks (front gate, secure ward partition, selected secure cell doors) for a configurable period, followed by restoration/relock. This is a proposed behavior from the latest walkthrough, **not yet approved as a precise unlock set or coded**. Use only the explicitly approved Parsons patient-security doors. Verify the installed qb-doorlock's state-change interface and power-loss/recovery behavior before implementing; an ordinary power failure should not be represented as automatically opening every lock.

**Laundry and cafeteria:** Existing qb-doorlock entries `Parsons-Service Building 1` (laundry), `2` (laundry-to-kitchen), `3` (kitchen storage), `4` (kitchen main), and `5` (cafe double doors) are already supplied. No need to remap the doors. Cafeteria patient meals/drinks are intended to use qb-shops, so collect only the actual shop/target counter positions and any necessary supply/work activity points, **not** invented cafeteria-employee NPC coordinates.

## A. Pool, sport, relaxation — Stage 6 activity locations

### A1. Swimming (`Config.Locations.activities.swimming`)
- [ ] Pool entry/start interaction `vector4`: `________________`
- [ ] Safe in-water activity point, if separate `vector4`: `________________`
- [ ] Identify pool ladder/edge, safe access, whether ped can actually swim; don't use a generic animation that leaves a player on dry ground.
- **Existing activity:** 180-second supervised swimming, 300-second cooldown. Needs live validation of movement, safety, cancellation and session eligibility.

### A2. Tennis (`tennis`)
- [ ] Court 1 start/interaction `vector4`: `________________`
- [ ] Court 2 or opposing player start, if usable `vector4`: `________________`
- [ ] Note playable court surface, net, equipment props, whether activity is a timed participation interaction or actual tennis gameplay (not yet implemented).
- **Existing:** 180-second activity, 300-second cooldown; no complete playable tennis mechanics are promised.

### A3. Yoga (`yoga`)
- [ ] Yoga mat or designated position 1 `vector4`: `________________`
- [ ] Additional positions, if present: `________________`
- [ ] Note facing/clearance so `WORLD_HUMAN_YOGA` does not clip into furniture.
- **Existing:** 150 seconds, 240-second cooldown, configured scenario, optional stress relief.

### A4. Meditation (`meditation`)
- [ ] Garden bench or meditation area `vector4`: `________________`
- [ ] Additional bench/quiet position: `________________`
- [ ] Note whether seated bench scenario is needed; current configuration reuses yoga scenario and may need changing for the actual setting.
- **Existing:** 120 seconds, 180-second cooldown, optional stress relief.

## B. Grounds and facility duties — Stage 6

### B1. Gardening (`gardening`)
- [ ] Garden bed/planting point 1 `vector4`: `________________`
- [ ] Additional beds/plots `vector4` values: `________________`
- [ ] Note whether garden props support repeated work, whether tools/items are desired, and patient access.
- **Existing:** 180 seconds, 240-second cooldown, gardening scenario. No invented harvest/reward items.

### B2. Raking / groundskeeping (`raking`)
- [ ] Lawn or leaf area 1 `vector4`: `________________`
- [ ] Other suitable outdoor areas: `________________`
- [ ] Note whether visual rake prop exists; current configured scenario is a **leaf blower**, not a rake. Decide animation/prop after viewing MLO.
- **Existing:** 150 seconds, 240-second cooldown.

### B3. Facility cleaning (`cleaning`)
- [ ] Cleaning station/closet `vector4`: `________________`
- [ ] Actual cleaning destinations (hall, restroom, common room) `vector4` per location: `________________`
- [ ] Note if supplies are taken from a closet and returned, or if each spot is independent.
- **Existing:** 150 seconds, 240-second cooldown, janitor scenario.

### B4. Laundry (`laundry`)
- [ ] Dirty-laundry pickup `vector4`: `________________`
- [ ] Washer interaction `vector4`: `________________`
- [ ] Dryer/folding station `vector4`: `________________`
- [ ] Clean-laundry return `vector4`: `________________`
- [ ] Note physical machines and whether a multi-step cycle is desired.
- **Existing:** 180-second laundry activity. A real pickup/wash/fold/return workflow is **not yet implemented**.

## C. Kitchen, cafeteria and supplies — Stages 6/8

### C1. Kitchen food preparation (`foodprep`)
- [ ] Prep counter `vector4`: `________________`
- [ ] Stove/oven or cooking appliance, if used `vector4`: `________________`
- [ ] Note staff-only vs approved patient work areas; do not grant blanket access through locked doors.
- **Existing:** 180-second participation activity; recipes/ingredients not established.

### C2. Dishwashing (`dishwashing`)
- [ ] Dirty dishes return `vector4`: `________________`
- [ ] Sink/dishwasher `vector4`: `________________`
- [ ] Clean-dish placement `vector4`: `________________`
- **Existing:** 120-second activity; actual dish-item handling is not yet built.

### C3. Cafeteria restocking (`restocking`)
- [ ] Food supply/storage pickup `vector4`: `________________`
- [ ] Cafeteria restock/drop-off `vector4`: `________________`
- [ ] Note supply room door ID and which roles can access it.
- **Existing:** 180-second participation activity; multi-step inventory logistics not yet built.

### C4. Free meals and drinks — separate from work
- [ ] Patient food pickup/shop counter `vector4`: `________________`
- [ ] Patient drinks pickup/shop counter `vector4`: `________________`
- [ ] Staff food-service interaction, if distinct `vector4`: `________________`
- [ ] Note whether food/drink are existing qb-inventory items and which qb-shops integration is installed.
- **Approved:** Patient meals and drinks are free, not conditional on cafeteria labor. **Not yet wired as shops.**

## D. Clinical and patient-care locations — capture only if usable in MLO

### D1. Group therapy (`therapy`)
- [ ] Meeting room/group seating interaction `vector4`: `________________`
- [ ] Staff facilitator position, if different `vector4`: `________________`
- [ ] Note relevant meeting-room doorlock ID.
- **Existing:** Generic 120-second therapy activity. Staff-authored clinical session records are separate from automatic participation.

### D2. Individual counseling
- [ ] Private counseling chair/desk `vector4`: `________________`
- [ ] Clinician position `vector4`: `________________`
- **Planning:** Separate clinical encounter workflow; no claim that individual counseling is already a standalone coded station.

### D3. Medical examination and medication
- [ ] Examination/treatment bed `vector4`: `________________`
- [ ] Medication dispensing/pharmacy point `vector4`: `________________`
- [ ] Any locked clinic/office door ID: `________________`
- **Planning:** Medical interactions require medical staff permissions and later SAMS/qb-ambulancejob integration; do not invent medicine, dosage or patient records.

### D4. General recreation (`recreation`) and rehabilitation (`rehabilitation`)
- [ ] Any **additional** common-room or supervised activity station `vector4`: `________________`
- [ ] Distinct rehabilitation program area, if present `vector4`: `________________`
- **Existing:** Generic activity categories; avoid duplicating pool/tennis/yoga stations without a specific reason.

## E. Patient rooms and facility staff interactions — Stages 1–4/8
- [ ] Standard room 1 bed/rest point `vector4`: `________________`
- [ ] Standard room 2 bed/rest point `vector4`: `________________`
- [ ] Standard room 3 bed/rest point `vector4`: `________________`
- [ ] Standard room 4 bed/rest point `vector4`: `________________`
- [ ] Secure cell 1 bed/rest point `vector4`: `________________`
- [ ] Secure cell 2 bed/rest point `vector4`: `________________`
- [ ] Secure cell 3 bed/rest point `vector4`: `________________`
- [ ] Secure cell 4 bed/rest point `vector4`: `________________`
- [ ] Observation room interaction, if any, **outside** secure partition `vector4`: `________________`
- [ ] Observation room interaction, if any, **inside** secure partition `vector4`: `________________`
- [ ] Confirm physical secure partition door is `Parsons-Basement 11`; note any other barred gate controlling access.
- [x] Boss menu location already mapped. **Development task:** wire qb-target + correct installed management API, verify rank/duty checks; location alone is not a functioning boss menu.
- [ ] If needed: staff participation/clinical administration terminal `vector4`: `________________` (not required if boss menu or existing desk handles it).

## F. Security interactions — Stage 7; property and door ID are ALREADY supplied
- [x] Front gate ID: `Parsons-Security ring`. **Development task:** connect configured gate ID to the existing gate-compromise/relock adapter and validate actual qb-doorlock fork/API.
- [ ] Gate electronics hacking interaction `vector4`: `________________`
- [ ] Gate physical bypass interaction `vector4`: `________________` (write **SAME AS HACK** if one point)
- [ ] **REQUIRED:** Interior electrical/sabotage panel `vector4`: `________________` (or **NOT PRESENT**)
- [ ] **REQUIRED:** Exterior electrical/utility panel `vector4`: `________________` (or **NOT PRESENT**)
- [ ] Guard shack alarm-reset console `vector4`: `________________`
- [ ] Medical office alarm-reset console `vector4`: `________________`
- [ ] Identify any actually switchable local lighting/fixture objects; user will test qb-weathersync blackout separately. **No global blackout** should be triggered by this resource.
- [ ] In game: test 300-second gate compromise/relock, failure dispatch, power disruption, alarm reset, unauthorized departure/return, aircraft detection, and restart recovery. Guard incident dispatch remains disabled until guard damage can be verified authoritatively.

## G. Developer-owned reconciliation — user should NOT have to supply more locations for these
- [ ] **Stages 1–4:** audit and finish admission authority, pending arrival, two-PED reception, room allocation, inventory custody and rollback, patient clothes, discharge authorization, guard checkout, return after escape, court transport, persistent hold/room metadata, and capacity edge cases. Test the entire sequence.
- [ ] **Door permissions:** integrate the existing `CanAccessRoomDoor` server policy with the **installed** qb-doorlock access mechanism; assigned patient only, on-duty authorized medical staff, revoke after discharge or 48-hour room expiration. Do not assume the export automatically enforces locks.
- [ ] **Secure housing:** implement authorized staff-controlled classification and assignment. A court commitment alone must not force secure housing. Padded rooms are observation only, never auto-assigned bedrooms.
- [ ] **Stage 6:** configure real activity points after mapping, verify qb-target/E-key, cancellation, animations, duration/cooldown, proximity, participation history and no time reduction/pay.
- [ ] **Stage 7:** wire gate ID now; once actual interaction vectors arrive, wire hacking, bypass, electrical and reset targets. Test local lighting limitations and PS Dispatch.
- [ ] **Stage 8:** actual boss menu, room rest/wardrobe, free food/drink shops, staff-facing participation and clinical workstations as APIs permit.
- [ ] **Stage 9:** inspect real installed qb-spawn, qb-ambulancejob, SAMS.net and SADOJ.net before integrating; do not change qb-prison `injail` behavior.
- [ ] **Acceptance:** inspect server logs and test in FiveM. GitHub commits alone are **not** evidence that gameplay works.

## Recording format to send back
```lua
-- Activity / station name; actual location and purpose:
vector4(x, y, z, heading)
-- Nearby object/door ID:
-- Patient/staff access:
-- Additional notes:
```

**Scope guardrails:** QBCore + qb-target + customized qb-inventory; ox_lib is supported. No ox_target or ox_inventory conversion. No fabricated points, no automatic sentence reductions, no automatic pay or item rewards, and no discharge on escape.
