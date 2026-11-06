# Stage 5 — Admission, discharge and inventory verification

**Status:** Code hardening in progress. Not development-server tested or production-ready.

## Required checks before Stage 5 verification can be signed off

1. **Fresh admission:** Authorized server resource admits a patient. Verify `parsons_hold` persists, the patient transfers, and every original inventory item is represented in `parsons_belongings` with the correct amount, metadata and slot. Confirm the live inventory is empty.
2. **Duplicate admission:** Attempt admission again. It must reject without altering the existing hold or custody record.
3. **Reconnect/restart:** Disconnect and reconnect, then restart the resource/server. Hold duration must not decrease during offline time. The player must return to the facility if outside its perimeter. Stored belongings must remain stored.
4. **Medical extension:** Extend 3 to 7 and 7 to 28 total online days. Verify already-served time is retained. Reject invalid or backward extensions.
5. **Court hold:** Verify indefinite and fixed-term court commitments. Reject nonjudicial discharge.
6. **Discharge:** Authorized discharge clears the hold, returns each item once and transfers the patient outside. Verify no old `parsons_belongings` metadata remains after a complete return.
7. **Inventory clear failure:** Simulate an unavailable/failed clear operation. Admission must stop. Inspect the `storing` custody record and manually reconcile; never re-admit until resolved.
8. **Interrupted return:** Stop the resource after at least one item grant. On restart, verify `pending_return` is retained and the complete snapshot is **not** automatically granted again.
9. **Return capacity failure:** Force `AddItem` to fail. Verify discharge reports belongings needing assistance and that staff can inspect the checkpoint and current inventory.
10. **Reconciliation:** Authorized staff compare custody snapshot and actual inventory, correct discrepancies, then explicitly acknowledge through the trusted server integration. Confirm the record is cleared and a subsequent admission is possible.
11. **Reception:** Status checks must work at the reception desk and reject remote attempts.
12. **Unauthorized departure:** Verify server-side distance validation, 120-second reporting cooldown and retained active hold.

## Manual custody recovery rules

- **`storing`**: The snapshot was recorded but inventory clearing may have been interrupted. Compare original snapshot to current inventory; decide what still needs to be secured. Never blindly clear or re-grant the snapshot.
- **`stored`**: The patient has a stored custody snapshot awaiting an authorized discharge.
- **`pending_return`**: Restoration began; `returnIndex` identifies the most recently attempted item. That item may or may not have been granted. Compare every item and slot with the current inventory before correcting anything.
- **`ConfirmBelongingsReconciled(targetId, true)`** only acknowledges an already completed manual recovery. It does not grant items. It must be invoked only from the trusted server integration after staff authorization.

## Blockers outside Stage 5 code

- Actual Parsons MLO coordinates are still placeholders.
- The `qb-ambulancejob` command/authorization integration has not been implemented.
- The actual PowerMoves customized qb-inventory and FiveM runtime have not been exercised here.

Do not mark this stage fully verified until these tests pass on the development server.

## Upstream qb-prison API comparison (2026-11-06)

Source: https://github.com/qbcore-fivem/qb-prison/blob/main/server/main.lua

- Upstream stores `Player.PlayerData.items` in `jailitems`, then uses `Player.ClearInventory()`.
- Upstream returns belongings with `exports['qb-inventory']:AddItem(src, name, amount, false, info, reason)` and then clears `jailitems` without checking each result.
- Parsons now calls `Player.ClearInventory()` and `exports['qb-inventory']:AddItem(...)` to match the upstream API. It retains a separate `parsons_belongings` snapshot and checks grant results to avoid silently discarding unreturned items.
- Confirm the customized PowerMoves qb-inventory accepts the same export signature during development-server testing.
