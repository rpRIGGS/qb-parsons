# Parsons care classification and MDT integration requirements

Status: Approved design direction; not a claim that all features are implemented.
Scope: qb-parsons operational implementation, with future SAMS.net and SADOJ.net handoffs.

## Architectural boundaries
- qb-parsons owns gameplay state: admission/check-in, legal-hold operational status, bedroom occupancy, security access, escorts, supervised movement, activity participation, and discharge execution.
- SAMS.net (shared PS-MDT backend) owns longitudinal medical records, psychiatric assessments, treatment plans, clinical observations, treatment progress and discharge summaries. Authorized doctors at other facilities may access relevant history according to medical permissions.
- SADOJ.net owns judicial orders, legal review, reporting obligations and decisions that alter court-ordered treatment.
- Bolingbroke prison and its script have **zero integration** with qb-parsons. Any incarceration after unsuccessful treatment is an external judicial/RP outcome, not a Parsons prison transfer workflow.
- No new medical job is requested.

## MLO care environments
- Four furnished, TV-equipped, windowed bedrooms upstairs: residential inpatient treatment; voluntary, medical and court-ordered substance-use patients may be housed here.
- Four secure basement bedrooms behind a separate locked section: secure psychiatric / forensic / high-supervision treatment.
- Two padded observation rooms: one outside the secure-bedroom section and one inside. Neither is a residential bed. Temporary observation does not itself change legal custody or permanent room assignment.
- Outpatient care does not require a residential room or routine belongings custody.

## Admission and transitions
- Legal authority (medical, voluntary, judicial), clinical level of care (residential, secure, outpatient, observation) and actual bedroom assignment are distinct fields/concepts.
- Court-ordered drug/alcohol treatment does **not** imply secure housing. No automatic basement assignment based solely on judicial status.
- An authorized clinical decision can recommend movement between care levels; judicial restrictions still require applicable court authorization. Recommendations are medical/court records in MDT, not duplicate clinical notes in qb-parsons.
- Clinical deterioration may require temporary padded observation and/or more restrictive housing. Improvement may allow supervised activities, residential placement or outpatient treatment while court reporting continues.
- Secure patients receive supervised meals, recreation, exercise, therapy and humane access to activities. Staff orderlies/psychiatric technicians may escort without being Gruppe Sechs armed security.

## Participation evidence
- Server-validated activity participation should capture patient identity, activity, start/completion timestamps, duration, outcome, and (where relevant) supervisor. Planned activities include yoga, swimming, exercise, cafeteria work, cooking/dishes and other assigned facility duties.
- qb-parsons may keep bounded operational participation data for gameplay and delivery; the authoritative longitudinal medical treatment history belongs to SAMS.net. Do not equate attendance with automatic clinical clearance or sentence reduction.
- Future MDT integration must support appropriate medical visibility and court-authorized reporting without exposing protected medical information to every law-enforcement user.

## Implementation checkpoints
1. Stage 1: classify admission independently of judicial hold; keep upstairs default for non-secure care and require authorized secure placement. Add explicit outpatient/observation flows without misusing residential room assignment.
2. Stage 1: make staff-authorized care-level changes and discharge respect court authorization; keep room ownership, inventory custody and legal hold consistent.
3. Stage 1: integrate qb-doorlock enforcement only against verified actual door IDs and compatible server-side doorlock API.
4. Stage 6: validate activity attendance server-side, persist bounded participation evidence and provide an authorized handoff path for SAMS.
5. Stage 7/8: supervised escorts, secure wing access, observation rooms and staff responsibilities.
6. Later: implement SAMS.net clinical records and SADOJ.net judicial workflow in the PS-MDT project, not as duplicate Parsons records.

## Current implementation cautions
- Existing BuildHold supports only medical and court holds; voluntary and outpatient pathways are not yet implemented.
- Existing AssignRoom defaults to standard rooms and secure transfers require trusted server caller; full classification/approval workflow is not complete.
- Existing activity engine does not yet constitute a permanent SAMS medical record.
- No original complete qb-doorlock config or in-server verification is present; door enforcement remains outstanding.

## Task 1 implementation update (2026-11-07)
- Trusted `AdmitPatient` accepts `voluntary` with `residential_7` (7 days) or `residential_28` (28 days). These are staff-authorized programs, not 5150/involuntary holds. `medical` durations remain separately constrained.
- `outpatient` (`evaluation` or `treatment`) is an operational enrollment without residential room, custody intake or residential countdown. Reception check-in refuses outpatient enrollment. Scheduling/clinical notes remain external.
- `ClassifyPendingAdmission` selects standard versus secure housing independently of hold authority. Authorized secure/residential room transfers update classification, not the court order.
- Every residential admission stores the incoming item snapshot and clears the inventory. Return from escape clears newly acquired inventory without overwriting the original snapshot. Discharge clears treatment-acquired inventory, retains only configured `Config.DischargeExcludedItems` by item name, then restores original admission items. The notebook/commissary/vending scripts are out of scope.
- `Config.DischargeExcludedItems` defaults to empty. The user may add exact item names from shared items.lua. The original inventory item's ordinary QB metadata is preserved by inventory APIs; Parsons does not interpret notebook content.
- On any interrupted inventory transition, the system blocks automatic replay and requires explicit staff reconciliation to prevent duplicated grants. `GetBelongingsRecord` and `ConfirmBelongingsReconciled` remain trusted-server-only.
- $20 vending cash allowance, pay phones, physical cash migration and QB Shops commissary are *ideas/independent configuration*, not implemented in qb-parsons.
- Door policy export `CanAccessRoomDoor` is implemented but is **not** actual qb-doorlock enforcement. Await verified original doorlock config and server API; do not fabricate integration or claim the doors are secured.
- Live in-game behavior remains unverified. No special qb-inventory compatibility concern exists: the user's custom UI uses standard QBCore qb-inventory APIs.

## Sequencing decision — qb-doorlock fork (2026-11-07)
- User plans a separate fork of qb-doorlock in the development projects folder, with its own chat and broader feature requirements. Do **not** start or expand that project inside qb-parsons.
- **Defer installation and implementation of the qb-doorlock integration patch** until the later qb-ambulancejob integration stage (exact task number to confirm against the master checklist). Batch the Parsons door authorization hook with the user's planned qb-doorlock fork improvements to avoid duplicate work.
- Parsons retains the server-side `AuthorizeDoorInteraction` policy export and existing room-access logic as preparation. Neither export currently enforces physical qb-doorlock state. Treat live door authorization as **pending integration and in-game validation**, not as complete.
- The existing `QB-DOORLOCK-SERVER-ADAPTER.md` is an exploratory reference only; it is **not** an approved drop-in patch and must be re-reviewed against the actual fork and all bypass paths before deployment.
- Continue current Task 1 admissions, classification, belongings, and discharge work, then proceed with the agreed task sequence. Do not make qb-doorlock a Task 1 blocker; retain it as a tracked later-stage dependency.

## Task 1 reentry correction (2026-11-07)
- Fixed a real race: `UpdateAbsence` could reset `absentSince` automatically on crossing back inside before reception had cleared escaped inventory. `reentryInventoryPending` now persists independently until successful reception processing.
- While pending, treatment countdown and patient-specific bedroom access are suspended. A room reservation is not itself revoked until the configured grace expiration; original admission inventory custody is not overwritten.
- The physical qb-doorlock hook remains a later-stage fork integration, already documented separately. This does not block Task 1's operational workflow implementation.

## Task 1 code-level closeout (2026-11-07)
**Status: Task 1 implementation complete for agreed code scope; in-game QA pending.** Do not conflate this with live server certification.

Final review caught and corrected:
- `NormalizeHold` had still rejected all `voluntary` and `outpatient` records despite `BuildHold` accepting them. Fixed in `server/main.lua`.
- Outpatient enrollment previously reused residential `Admit` client event, teleporting patients to Parsons. It now uses `OutpatientEnrolled` with no residential transport, intake, or clothing changes.
- Outpatient closure no longer forces residential exit teleport or restores residential clothing.
- Secure and residential transfer exports now reject transfers while `reentryInventoryPending` is set, consistent with countdown and room-door policy.
- Earlier final-pass fix retains the reentry inventory clearance obligation after automatic absence tracking clears `absentSince`.

Task 1 scope: authorized admission hold types, pending classification, room assignment and transfers, intake belongings custody, escaped reentry clearance, discharge and authorized return of belongings. The deferred qb-doorlock enforcement and broader ambulancejob integration remain later-stage work. In-game QA should cover all hold types, room allocation/reassignment, escaped reentry, custody interruption/reconciliation, and discharge; any discovered regression is a defect, not a reason to expand Task 1 scope.
