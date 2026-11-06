# qb-parsons — Installation and Integration Reference

**Status (2026-11-06): active implementation, not a tested release.** Stage 7 security code and an optional PS Dispatch adapter exist; Stage 1–4 admission/reception/discharge restructuring and live MLO testing are pending. Do not deploy as a complete Parsons treatment system.

## Current upstream dependencies and integration points

- QBCore (`qb-core`) is required by the current resource.
- `fxmanifest.lua` loads `@ox_lib/init.lua`, PolyZone client files, Parsons security and PS Dispatch adapters, legacy modules, and `config.lua`. `ox_lib` is a required dependency.
- The current client code explicitly recognizes event invocation from `qb-policejob` and `qb-ambulancejob` for `prison:client:Enter`.
- The current code uses `injail` and `jailitems` metadata, prison-specific events and a prison countdown. These must not be reused for Parsons patient status.
- The PowerMoves target integration is QBCore, qb-target, custom qb-inventory and ox_lib.
- **Approved correction:** do not modify `qb-policejob` for Parsons. `/commit` and `/uncommit` are planned in the PowerMoves `qb-ambulancejob` fork, with separate authorization for LEO/medical roles. Preserve normal arrest/jail behavior.

## Intended admission and transport workflows

### Court-ordered commitment
1. A judge issues an applicable order under existing PowerMoves law.
2. A uniformed officer from the Division of Law Enforcement assigned to courtroom security takes responsibility for custody and coordinates transport.
3. Ambulance service is called for medical transport. Do not assume the courtroom officer is an ambulance driver or clinician.
4. Authorized responders transport the person to Parsons.
5. Parsons staff verify the order, receive the patient, complete intake, and record admission and applicable hold terms.

### Other entry paths
- A legally authorized clinician, including a properly credentialed grade 10 Psychiatrist, may initiate a permitted psychiatric evaluation hold.
- Law enforcement may request/coordinate transport where authorized, without automatically making the clinical determination.
- Voluntary patients are admitted with appropriate consent and are not treated as criminal prisoners.
- Hospital-to-Parsons referrals/transfers require clinical coordination and acceptance.
- Continued commitment, extensions and discharge require appropriate authority.

## Required installation / integration changes — checklist

### qb-parsons
- [ ] Replace prison-specific `prison:*` events with distinct Parsons APIs, including server-side authorization.
- [ ] Replace `injail`/`jailitems` with separate patient/hold/property records.
- [ ] Implement explicit admission requests, acceptance, transport handoff and discharge states.
- [ ] Validate officer, clinical and court authorization server-side; never trust a client event alone.
- [ ] Implement 72-hour real elapsed-time holds with restart/offline persistence.
- [ ] Configure MLO positions, patient rooms, qb-target and custom qb-inventory.
- [ ] Document dependency order and any SQL migrations once implemented.

### qb-policejob — no Parsons modifications authorized
- [ ] Inspect the actual PowerMoves qb-policejob fork/version and its jail/custody actions.
- [ ] Preserve existing criminal jail/booking flows; Parsons commands and their authorization belong in the separate qb-ambulancejob integration.
- [ ] Support an officer carrying out courtroom security duties after a judicial order.
- [ ] Preserve normal jail/prison booking and avoid redirecting criminal incarceration to Parsons.
- [ ] Use a secure server-side request/response interface with qb-parsons; record requesting officer and legal basis.
- [ ] Determine whether an existing interaction/menu can be extended rather than rewriting unrelated policejob features.

### Ambulance / medical transport integration (separate resource; changes not yet made)
- [ ] Inspect the installed ambulancejob fork and its dispatch/transport capabilities.
- [ ] Provide an ambulance request and coordinated handoff to Parsons; do not assume the ambulance service orders the commitment.
- [ ] Distinguish medical transport from clinical admission authority.
- [ ] Ensure that authorized clinicians can initiate permitted holds and transfers without a police officer being required in every case.

### Validation before release
- [ ] Court order -> officer custody -> ambulance request -> medical transport -> Parsons intake.
- [ ] Clinician-initiated hold -> transport -> intake.
- [ ] Voluntary admission and outpatient visit.
- [ ] Verify unauthorized officers and staff cannot commit, release or transfer patients.
- [ ] Confirm jail/prison gameplay remains unchanged.
- [ ] Confirm reconnect, server restart, hold expiry, extensions, escapes and belongings work.

## Deployment instructions (to complete after implementation)

- [ ] Document exact resource folder names and `server.cfg` ensure order.
- [ ] Document installation of database tables/migrations.
- [ ] Document the separate `qb-ambulancejob` `/commit` and `/uncommit` integration and its authorization rules.
- [ ] Document ambulance/dispatch integration and configuration.
- [ ] Document Parsons MLO requirements, qb-target zones and inventory setup.
- [ ] Document a reproducible end-to-end smoke test.

**Scope:** These are integration requirements, not completed changes to qb-policejob, ambulancejob, or other PowerMoves repositories.

## Current security integration (2026-11-06)

- `ox_lib` required for configured electrical and gate skill checks; QBCore, qb-target and customized qb-inventory retained.
- `electronickit` is the electrical sabotage item; `gatecrack` is the electronic gate item. No thermite or repair-kit substitution.
- **Gruppe Sechs** is the GTA security company providing the front-gate guard and reporting Parsons alarms.
- Optional PS Dispatch is implemented within qb-parsons; enable `Config.Security.PSDispatch.enabled` when `ps-dispatch` is installed. There is **no** legacy qb-policejob dispatch fallback. Calls and codes need live verification.
- Physical qb-doorlock gate unlock/restore remains a code integration item; actual door IDs and positions are mapping inputs, not code blockers.
- See [PARSONS-SERVER-MAPPING-CHECKLIST.md](PARSONS-SERVER-MAPPING-CHECKLIST.md) and [PARSONS-ADMISSION-SECURITY-WORKFLOW.md](PARSONS-ADMISSION-SECURITY-WORKFLOW.md).
