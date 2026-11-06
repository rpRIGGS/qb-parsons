# qb-parsons Development Reference

Implementation and planning reference for PowerMoves RP Parsons Rehabilitation Center. **As of 2026-11-06, Stage 7 security code is partially implemented but not runtime-tested; finish its remaining code before revisiting Stages 1–4 and before Stage 8.** Checked items below may be broader release milestones, not an indication that no code exists.

## Foundation
- [ ] Audit original qb-prison functionality and dependencies.
- [ ] Separate Parsons operational admission state from prison sentences and metadata; PS-MDT owns clinical and judicial records.
- [ ] Keep QBCore, qb-target, custom qb-inventory and ox_lib.
- [ ] Map custom MLO gate, guard shack, rooms and activity spaces.

## Patient management
- [ ] Voluntary admissions and outpatient visits.
- [ ] Involuntary 72-hour evaluations and judicial commitments measured in real-life days.
- [ ] Online-only commitment countdown persisted through disconnects; no activity-based time reduction.
- [ ] Extensions, discharge authorization and hospital referrals.
- [ ] Patient rooms, storage, belongings and clothing.
- [ ] Unauthorized departures and escape-related RP.

## Treatment
- [ ] Individual and group counseling.
- [ ] Substance use and gambling treatment.
- [ ] Recreation and daily activities.

## Staff
- [ ] Use existing parsonsmed job and duty system.
- [ ] Grade 10 Psychiatrist independently evaluates and admits patients when authorized.
- [ ] Psychiatrist consultations at other hospitals and referrals.
- [ ] Separate clinical credentials from administrative boss ranks.

## PS-MDT records and certifications integration
- [ ] Keep only essential operational admission/hold/room/belongings/transport state in qb-parsons.
- [ ] Define server-side integration with SAMS.net medical documentation and SADOJ.net judicial orders; do not duplicate their record systems.
- [ ] Link hospital referrals, evaluations, treatment and discharge documentation to PS-MDT.
- [ ] Read/validate applicable clinician credentials and court authority through the approved integration.

## Verification
- [ ] Test persistence, permissions, room access, holds, releases and escapes.
- [ ] Document installation and configuration.

## Reference
See the Parsons planning notes in PowerMoves-PSMDT at planning-reference/parsons-sams-integration.md. This resource remains independently scoped.

## Detailed planning decisions

### Facility and admission types
Parsons is a small psychiatric rehabilitation facility operated independently by licensed `parsonsmed` staff, under SAMS oversight. The custom MLO includes a fenced perimeter, controlled gate, guard shack and individual patient rooms. Exact coordinates and room counts remain to be mapped.

Admissions to support:
- Voluntary residential patients, who are not automatically confined.
- Involuntary emergency psychiatric holds up to 72 real hours.
- SAMS-authorized medical extensions to seven days total for evaluation or 28 days total for treatment.
- SADOJ court-ordered long-term, indefinite or lifetime commitments.
- Outpatient counseling and follow-up without residential confinement.

### Hold and discharge behavior
- Persist remaining online commitment time across disconnects and restarts; offline time does not count.
- Do not shorten holds for work, therapy, or recreational activities.
- At hold expiry, check whether a lawful extension/order exists; never release solely on a countdown when an active order supersedes it.
- Persist operational discharge status and return of stored belongings; send formal discharge documentation to PS-MDT.
- Escapes and unauthorized departures are possible RP events, not an automatic erasure of the patient's hold or record.
- Changing voluntary status to involuntary requires a separately authorized clinical/legal decision.

### Existing Parsons job ranks

| Grade | Title |
|---|---|
| 0 | Awaiting SAMS |
| 1 | Behavioral Health Trainee |
| 2 | Behavioral Health Technician |
| 3 | Psychiatric Technician |
| 4 | Substance Abuse Counselor |
| 5 | Mental Health Counselor |
| 6 | Certified Nursing Assistant (CNA) |
| 7 | Licensed Practical Nurse (LPN) |
| 8 | Registered Nurse (RN) |
| 9 | Psychiatric Nurse Practitioner |
| 10 | Psychiatrist |
| 11 | Clinical Coordinator |
| 12 | Assistant Medical Director |
| 13 | Medical Director |

The existing job uses QBCore type `ems`, default duty enabled and no off-duty pay. Grades 11–13 have boss flags. Psychiatrist grade 10 has independent clinical admission authority when appropriately credentialed, including hospital consultation, referrals and transfers. Administrative seniority alone is not clinical licensure. Do not change pay rates here.

### Planned gameplay
- Staff intake and assigned patient rooms, beds, wardrobes and personal stashes.
- Restricted property storage and return on discharge, with different rules for voluntary and involuntary patients.
- Controlled staff-only doors, gate and perimeter access.
- Individual and group counseling; substance-use and gambling treatment; recreation and supervised routines.
- Optional outpatient appointment workflow.
- Staff management of current patients, hold statuses, room assignments, incidents and authorized discharge.

### Operational state vs authoritative records
- **qb-parsons operational persistence:** character identifier, admission/hold type and status, applicable hold start/end timestamps, assigned room, belongings storage, pending/in-progress/arrived transport status, and the minimum order/reference identifiers needed to enforce restrictions.
- **PS-MDT / SAMS.net:** psychiatric evaluations, treatment plans, counseling and progress notes, nursing observations, referrals, clinician credentials, medical hold extension decisions and medical discharge documentation.
- **PS-MDT / SADOJ.net:** judicial orders, court proceedings, long-term/indefinite/lifetime commitment authority, modifications and judicial release.
- Use defined server-side events/exports or callbacks and record identifiers; avoid a duplicate Parsons clinical/legal database. Queue/reconcile integration events if PS-MDT is temporarily unavailable; do not silently lose changes.

### Credentials and certifications to account for
- Psychiatrist medical license and psychiatric specialization.
- Psychiatric nurse practitioner authorization; RN, LPN and CNA credentials.
- Mental health and substance-use counselor qualifications and supervision.
- Behavioral health/psychiatric technician training.
- Facility orientation, safety/de-escalation training, credential status and renewals.

PS-MDT is the authoritative system for confidential medical and judicial records. qb-parsons only maintains the operational state necessary for reliable gameplay and applies appropriate access controls.

## Open design questions
- MLO coordinates, number of rooms, stash locations and secure doors.
- Which original qb-prison activities are reusable or should be removed.
- Handling admissions and discharges with no Parsons staff online.
- Whether escapes need automated detection or only incident reporting.
- Which counseling mechanics are scripted versus player-driven RP.
- Outpatient scheduling and voluntary check-out.

## Source links
- Original foundation: https://github.com/qbcore-fivem/qb-prison
- Existing Parsons job definitions: https://github.com/rpRIGGS/PowerMoves-PSMDT/blob/main/planning-reference/development-jobs.lua
- Previous Parsons records and credentials notes: https://github.com/rpRIGGS/PowerMoves-PSMDT/blob/main/planning-reference/parsons-sams-integration.md

**Status:** Partial gameplay code is committed in qb-parsons; the checklist includes future work and runtime verification. This file does not authorize work on other repositories.

## Law enforcement, courtroom and medical transport integration

- [ ] Integrate new Parsons `/commit` and `/uncommit` commands through the existing PowerMoves `qb-ambulancejob` fork for on-duty `ems` or `leo`; do not modify `qb-policejob`.
- [ ] Support judicially ordered commitments initiated by a Division of Law Enforcement officer assigned to courtroom security.
- [ ] Allow optional officer or EMS/Parsons transport through RP before `/commit`; the command itself performs direct admission without a transport menu.
- [ ] Support legally authorized clinician-initiated holds and hospital referrals without requiring an officer for every admission.
- [ ] Validate order/hold authority and Parsons intake server-side; do not reuse prison `injail` state or assume job name `police`.
- [ ] Test optional officer/medical transport through RP before `/commit`, followed by direct Parsons admission; no scripted transport mode.

See [INSTALLATION.md](INSTALLATION.md) for the earlier dependency audit (some policejob modification proposals are superseded by the decisions below) and the future deployment checklist. **The separate qb-ambulancejob command integration has not been completed. Parsons Stage 7 and PS Dispatch code are present.**

## Upstream dependency audit

- [ ] Complete the file-by-file prison-reference audit and remove prison-specific language from qb-parsons without breaking actual jail gameplay.
- [ ] Keep the upstream LEO-only criminal jail permission separate from Parsons clinical hold authorization.
- [ ] Confirm whether PowerMoves law designates qualified non-psychiatrist hospital physicians to initiate 5150-style holds; never grant authority to every EMS employee automatically.
- [ ] Keep ambulance transport permissions distinct from clinical hold decisions.

See [UPSTREAM-PRISON-AUDIT.md](UPSTREAM-PRISON-AUDIT.md) for verified upstream paths, English locale keys and outstanding integration work.

## Approved commitment and admission architecture (2026-11-06; corrected)

These decisions supersede conflicting earlier planning text in this file and other references. The 2023 PowerMoves 51-50 policy is historical context; the revised SAMS/SADOJ policy remains to be written. **Operational hold and belongings foundations implemented; external authorization, facility interactions and live testing remain pending.**

### Hold types, units and authority

**Parsons uses real-life days and real-life days of accumulated online time, excluding offline time.** It does not use prison RP months, accelerated prison sentence time, or the prison `99999` (“the 9's”) convention.

| Type | Actual duration | Responsible authority |
| --- | --- | --- |
| Emergency psychiatric evaluation | Up to 72 real hours / 3 real days | Authorized LEO or appropriately credentialed medical professional may initiate |
| Extended evaluation | Up to 7 real days **total** from initial hold | SAMS / appropriately authorized medical personnel |
| Extended psychiatric treatment | Up to 28 real days **total** from initial hold | SAMS / appropriately authorized medical personnel |
| Long-term judicial commitment | Court-specified duration in **real days** | SADOJ |
| Indefinite / lifetime judicial commitment | No expiration timer; release or modification requires appropriate court authorization | SADOJ |
| Voluntary admission or outpatient treatment | Not automatically a custodial hold | Authorized clinical process |

- SAMS handles medical evaluation and extensions through 28 days; LEO cannot independently extend medical holds.
- SADOJ controls long-term, indefinite and lifetime judicial commitments, including their modification and release.
- A SAMS discharge cannot override an active SADOJ confinement order.
- Parsons Grade 10 Psychiatrist may independently evaluate and admit within appropriate credentials; administrative grade or command access alone is not clinical/legal authorization.
- Activities do not shorten hold time. Preserve lawful extensions or court orders when an earlier timer expires.
- For timed holds, persist accumulated eligible **online, checked-in, inside-property** time, not wall-clock expiry or a client-side prison countdown. A legal hold's effective start may precede arrival when transport occurs; define this from the legal authorization, not a transportation menu.

### Transport is RP before the command, not a script mode

**Follow the existing PowerMoves prison RP workflow.** Participants may choose to skip physical transportation or roleplay it first, with an officer, EMS or Parsons personnel. Interception, escape, recapture and coordination are handled in the world through RP. Do **not** add a transport selection UI, pending/in-transit state machine or scripted interception system solely for `/commit`.

Once the person is ready to be admitted, an authorized person executes `/commit` near the target, and qb-parsons performs the direct facility transfer and intake using adapted qb-prison foundations. For RP transport, execute `/commit` **after** arrival; for skipped transport, execute it where the patient is. The command must not automatically assume a vehicle was used.

An outstanding lawful commitment/hold should not be invalidated merely because RP transport was interrupted. Formal authority and documentation belong in PS-MDT, not a duplicate Parsons medical database. The detailed legal effective-time rule for interrupted or delayed transport must be defined in the revised policy.

### Resource responsibilities

- **qb-ambulancejob:** Planned `/commit` and `/uncommit` command entry points for on-duty `job.type == 'ems' or job.type == 'leo'`, with server-side validation and Parsons-specific events. This does **not** grant LEO general ambulance treatment privileges or grant FIRE automatic commitment authority. Preserve the fork's existing EMS/FIRE medical plans.
- **qb-parsons:** Facility transfer, admission, assigned rooms, belongings, operational hold state, real-time expiry and authorized discharge. Do not reuse prison `injail`, `jailitems`, criminal records or prison events for Parsons.
- **PowerMoves PS-MDT:** SAMS.net owns medical records and SAMS hold-extension decisions; SADOJ.net owns judicial records/orders and long-term/indefinite/lifetime commitments. Use a defined server-side event/export/callback interface and record references, not a parallel medical record system.
- **qb-policejob:** No edits. Preserve `/jail`, `/unjail`, prison metadata, existing sentence conversion and translations.

### Next implementation tasks

- [ ] Define the `/commit` and `/uncommit` input flow, including how hold type, real-day duration and court authority are represented without prison-style sentence units.
- [ ] Define qb-parsons server event/export contracts and server-side authorization checks.
- [ ] Define PS-MDT SAMS/SADOJ reference and validation integration; handle unavailable MDT without silently losing relevant changes.
- [ ] Inspect/reuse qb-prison admission, transfer, belongings, persistence and release foundations without mixing prison metadata.
- [ ] Implement and test direct `/commit` admission first; leave physical transport to player RP before the command.
- [ ] Test 3/7/28-day real-time holds, court-specified real-day terms, indefinite/lifetime holds, offline passage, restart, reconnect and authorized discharge.

**Status:** Approved planning only; no gameplay implementation in this change.

## Current implementation status (2026-11-06)

- [x] Operational medical and judicial hold metadata, including indefinite court commitments.
- [x] Online-only countdown; no time served while disconnected. All earlier offline-elapsed references are superseded.
- [x] Server-side admission, extension and discharge exports (trusted-resource boundary only; clinician and judicial authorization must be enforced by the caller).
- [x] Inventory custody snapshot, storage state, return checkpoints, and restricted manual reconciliation exports.
- [ ] Verify inventory clearing and restoration against the PowerMoves development server; no live testing has been performed.
- [ ] Complete manual recovery workflow for interrupted custody transactions and document operator verification.
- [ ] Map actual Parsons MLO coordinates; existing locations are upstream prison placeholders.
- [ ] Implement facility activities and staff/patient interactions after coordinates are supplied.
- [ ] Implement external /commit and /uncommit authorization separately in the customized qb-ambulancejob fork.
- [ ] Complete integration tests for reconnect, restart, admission, release, inventory failure and unauthorized departure.

**Do not deploy as production-ready.** This document tracks code implementation, not verified gameplay.

## Stage 7 implementation snapshot (2026-11-06)

- Implemented source foundations: single configurable property polygon and low-aircraft detection; timed electrical and gate security compromise; incident history and server events; item checks for `electronickit` and `gatecrack`; `ox_lib` skill checks; qb-target/E-key interactions; optional PS Dispatch integration.
- Reporting company and planned front-gate guard: **Gruppe Sechs** (Rockstar GTA security company).
- PS Dispatch is the approved dispatch adapter. It is configured inside qb-parsons and has **no automatic legacy qb-policejob fallback**. Configurable codes/job filters and actual FiveM behavior require verification.
- Still required in code: physical gate qb-doorlock adapter, security interaction validation/feedback review, and incident/escape consistency audit. Missing MLO mapping and door IDs are tracked separately and must not delay code review.
- Next approved work order: **finish Stage 7 code → restructure Stages 1–4** for pending arrival, reception check-in, assigned room/belongings and authorized Gruppe Sechs guard-shack checkout → Stage 8.
- See [PARSONS-ADMISSION-SECURITY-WORKFLOW.md](PARSONS-ADMISSION-SECURITY-WORKFLOW.md), [PARSONS-SERVER-MAPPING-CHECKLIST.md](PARSONS-SERVER-MAPPING-CHECKLIST.md), and [INSTALLATION.md](INSTALLATION.md).
