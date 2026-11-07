# Task 2 — Stage 7 security and escape audit (2026-11-07)

## Implemented this pass
- Verified escape is detected from server-observed facility polygon; the client departure event is only a hint.
- Departure incident now carries the server-observed player coordinates for responder context.
- Sabotage action completion requires server-verified proximity, required item and minimum elapsed time. Client skill-check success is **not cryptographic proof** and remains a game-play trust boundary.
- Security incident dispatch intentionally selects **one** authorized on-duty client to call `ps-dispatch:CustomAlert` because that export creates a shared dispatch alert; broadcasting it to every responder would duplicate calls.
- Removed unsafe qb-doorlock `updateState` event spoofing with `unlockAnyway` and `sentSource`. Physical gate movement is **deferred** to the qb-doorlock fork integration, while alarm and gate-compromised incident state still function.
- Power outage logic does not invoke a server-wide weather blackout.

## Remaining Stage 7 work
- Verify actual electrical and gate hack interaction coordinates: `Config.Security.electrical.inside/outside` and `gate.hack` are currently `nil`, so those interactions cannot yet start.
- Map alarm reset points (currently empty).
- Review server-side rate limits and replay behavior for security actions; test outage and alarm transitions.
- Test aircraft warnings, guard incident trusted bridge, escaped patient handling, and ps-dispatch integration in the running server.
- Later fork integration: physical gate lock/unlock and secure wing/bedroom enforcement; **not** part of Stage 7 code scope until fork is ready.

This is a progress audit, **not** a Stage 7 completion claim.

## Security implementation follow-up — 2026-11-07

- Added per-player server-side sabotage retry cooldown, including cleanup on disconnect.
- Configured the already mapped guard shack as the first alarm-reset station; additional medical-office locations remain unmapped.
- Added client startup and player-login security state requests, with active alarm state replay.
- Alarm failsafe expiry now broadcasts the cleared security state to clients.
- Action results now identify electrical interruption versus gate-compromise alarm without falsely claiming a physical gate unlock.
- Kept a single on-duty responder as the PS Dispatch CustomAlert emitter to prevent duplicated shared calls.
- No new map coordinates were guessed. The two electrical-panel locations and gate hack point are still disabled because their coordinates are nil.
- Actual local light blackout has no configured controllable lights, so the server currently tracks an interruption/dispatch event but cannot visually darken mapped fixtures. No global weather blackout is invoked.
- Guard incident reporting requires a trusted server integration; client-local guard damage is not treated as verified.
- Live FiveM testing has not occurred.

**Status:** Stage 7 core code paths reviewed and corrected, but the playable sabotage stations and local blackout effects are **not complete** without MLO coordinates/light mappings. The future physical gate adapter is separately deferred. Do not mark Task 2 fully complete until those limitations are resolved or expressly accepted as out-of-scope.

## Continued Task 2 fixes — 2026-11-07

- Fixed an additional disconnect edge case in `server/main.lua`: a checked-in residential patient who disconnects now receives `reentryInventoryPending`, so reconnecting inside cannot silently bypass reentry inventory clearance.
- Client sabotage flow now runs an ox_lib progress step after a successful skill check, meeting the server's minimum elapsed-time requirement; interrupted progress is reported as failure.
- Server minimum elapsed time applies to **successful** hacks. A quickly failed gate skill check can still raise a verified attempted-tampering alarm, provided the player remains at the mapped interaction point with the configured item.
- QB admin menu weather/time/blackout controls were reported nonfunctional by the server owner. That issue is separate from Stage 7 and is **not** a valid Parsons blackout test. Whether this MLO responds to game-wide blackout natives is unverified; no global blackout is being triggered by Parsons.
- Remaining integration inputs: actual electrical and gate hack coordinates, confirmation of how the MLO lights behave, and live FiveM validation. Do not invent coordinates or claim visual blackout functionality until verified.

## Coordinate placeholders and implementation policy

Task 2 is **not** blocked on obtaining map coordinates. The complete qb-target sabotage interaction pipeline is implemented and parameterized. `Config.Security.electrical.inside`, `electrical.outside`, and `gate.hack` are intentionally left as clearly labeled `nil` placeholders; replacing each with a captured `vector4(x,y,z,heading)` enables that station without a code rewrite. The guard-shack alarm reset already has a mapped position.

The server owner confirms that the Parsons MLO responds to GTA blackout behavior from prior development testing. Do not reopen that factual question. The Parsons resource deliberately does not trigger a global blackout, and visual blackout scope remains a separate integration choice rather than a reason to defer the security code.

Stage 7 code implementation is ready for the eventual server validation pass, apart from the explicitly deferred physical qb-doorlock adapter. **No live server test has been run in this session.**
