# Task 2 — Stage 7 security and escape implementation status

## Implemented in qb-parsons

- Server-observed patient perimeter checks, unauthorized departure and return incidents, 48-hour real-time room reservation grace, and paused treatment time outside the facility or during authorized transport.
- Escaped patients retain acquired inventory until reentry; reentry inventory clearance is required before treatment time resumes. Original belongings remain separately recorded.
- Configurable qb-target stations for interior/exterior electrical tampering, gate electronics, and mapped guard-shack alarm reset.
- ox_lib minigames, server-issued action tokens, elapsed-time checks, equipment/proximity revalidation, action cooldowns, and explicit denial feedback.
- Server-owned timed security state, gate-compromise alarm, monitoring/communications interruption incidents, alarm reset authorization, state sync and expiration.
- PS Dispatch bridge selects one eligible on-duty responder to create a shared alert, avoiding duplicated dispatch calls.
- Server-observed unauthorized aircraft detection and trusted server-resource guard incident bridge.
- No server-wide blackout or unsafe qb-doorlock event spoofing.

## Ready-to-fill MLO configuration

Capture and fill these placeholders in `config.lua` whenever in the game:
- `Config.Security.electrical.inside = vector4(x, y, z, heading)`
- `Config.Security.electrical.outside = vector4(x, y, z, heading)`
- `Config.Security.gate.hack = vector4(x, y, z, heading)`

Each unmapped station stays disabled until populated; the code requires no rewrite. The guard-shack alarm reset point is already mapped. The server owner has personally confirmed that the Parsons MLO responds to GTA blackout behavior. This resource does not trigger global blackout because that would affect the rest of the server.

## Explicitly separate integration and live validation

- Physical gate unlock/lock and secure bedroom/wing enforcement await the planned qb-doorlock fork; they are not falsely represented as functioning.
- Local-only MLO lighting effects need a scoped light-control integration; `Config.Security.power.controllableLights` is currently empty. Security state, incident and monitoring behavior work independently of visual effects.
- Guard NPCs are client-local, so damage/death cannot be trusted for server-wide incidents. The trusted `ReportVerifiedGuardIncident` export is available for a future network-owned guard integration.
- In-server QA is still required for player escape/reentry, alarm/dispatch, sabotage and aircraft behavior. No live FiveM test has been performed by the assistant.

**Development status:** Stage 7's configured security and escape logic is implemented, with MLO coordinate placeholders. Deferred integration points and live QA are tracked separately rather than repeatedly reopening earlier task stages.
