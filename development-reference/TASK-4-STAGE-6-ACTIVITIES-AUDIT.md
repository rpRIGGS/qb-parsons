# Task 4 — Stage 6 rehabilitation activities

## Implemented
- Configured therapy, rehabilitation, recreation, swimming, tennis, yoga, meditation, gardening, groundskeeping, laundry, kitchen, cleaning and other activities.
- qb-target-only stations; each station is disabled until its actual MLO position is configured.
- Server-authoritative activity start, minimum duration, completion, interruption, cooldown, and bounded history.
- Eligibility checks reject unadmitted, escaped, transported, reentry-pending and room-expired patients, as well as dead player peds.
- Sessions are tied to patient citizen ID and server-issued token; changing player identity cannot complete a previous session.
- Client progress and optional scenario animations are presentation only; server determines whether participation completes.
- Completion and cancellation publish server events for authorized integration; completion records are visible to staff through the Stage 8 operations dashboard.
- No hold time reduction, payouts, or inventory rewards. Only configured stress relief applies.

## MLO setup
For each station, fill `Config.Locations.activities.<id>` with `coords = vector4(x,y,z,heading)`, and optional `radius`, `length`, `width`, `heading`, `minZ`, `maxZ`. No guessed positions are shipped.

## Deployment validation outstanding
- Capture station positions and check qb-target registration and scenario animations.
- Verify activity timer, cooldown, cancellation on walking away/death/escape/transport and completion history.
- Verify reentry clearance, patient reconnect and resource restart.
- Verify Stage 8 staff activity-history access.
- Check FiveM console for runtime errors.

**Development status:** Stage 6 resource-side implementation is complete, pending MLO mapping and in-game QA. No claim of live verification.
