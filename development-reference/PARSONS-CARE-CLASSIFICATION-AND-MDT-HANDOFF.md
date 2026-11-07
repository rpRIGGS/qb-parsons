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
