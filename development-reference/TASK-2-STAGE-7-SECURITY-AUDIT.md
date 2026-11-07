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
