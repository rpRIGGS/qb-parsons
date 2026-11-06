# qb-parsons Development Reference

Planning checklist for PowerMoves RP Parsons Rehabilitation Center.

## Foundation
- [ ] Audit original qb-prison functionality and dependencies.
- [ ] Separate Parsons operational admission state from prison sentences and metadata; PS-MDT owns clinical and judicial records.
- [ ] Keep QBCore, qb-target, custom qb-inventory and ox_lib.
- [ ] Map custom MLO gate, guard shack, rooms and activity spaces.

## Patient management
- [ ] Voluntary admissions and outpatient visits.
- [ ] Involuntary 72-hour evaluations and judicial commitments.
- [ ] Real-time holds that persist offline; no activity-based time reduction.
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
- Track actual start/end timestamps, including offline elapsed time and restarts.
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

**Planning only:** No gameplay implementation is implied by this checklist. This file does not authorize work on other repositories.

## Law enforcement, courtroom and medical transport integration

- [ ] Integrate new Parsons `/commit` and `/uncommit` commands through the existing PowerMoves `qb-ambulancejob` fork for on-duty `ems` or `leo`; do not modify `qb-policejob`.
- [ ] Support judicially ordered commitments initiated by a Division of Law Enforcement officer assigned to courtroom security.
- [ ] Support optional direct transfer, officer transport or EMS/Parsons medical transport; no ambulance is mandatory for every commitment.
- [ ] Support legally authorized clinician-initiated holds and hospital referrals without requiring an officer for every admission.
- [ ] Validate order/hold authority and Parsons intake server-side; do not reuse prison `injail` state or assume job name `police`.
- [ ] Test direct transfer and optional courtroom order -> officer/medical transport -> Parsons acceptance and admission, including interrupted transports.

See [INSTALLATION.md](INSTALLATION.md) for the earlier dependency audit (some policejob modification proposals are superseded by the decisions below) and the future deployment checklist. **No integration code has been changed yet.**

## Upstream dependency audit

- [ ] Complete the file-by-file prison-reference audit and remove prison-specific language from qb-parsons without breaking actual jail gameplay.
- [ ] Keep the upstream LEO-only criminal jail permission separate from Parsons clinical hold authorization.
- [ ] Confirm whether PowerMoves law designates qualified non-psychiatrist hospital physicians to initiate 5150-style holds; never grant authority to every EMS employee automatically.
- [ ] Keep ambulance transport permissions distinct from clinical hold decisions.

See [UPSTREAM-PRISON-AUDIT.md](UPSTREAM-PRISON-AUDIT.md) for verified upstream paths, English locale keys and outstanding integration work.

## Approved commitment and transport architecture (2026-11-06)

These decisions supersede conflicting older planning text in this file and related references. The 2023 PowerMoves 51-50 policy is historical context; a rewritten SADOJ/SAMS policy is still required. The following is approved **gameplay architecture**, not a claim that updated law or code has been published.

### Commitment types and decision authority

| Type | Duration / expiry | Responsible authority |
| --- | --- | --- |
| Emergency involuntary psychiatric evaluation | Up to 72 hours in real elapsed time | Authorized law enforcement officer or appropriately credentialed medical professional may initiate |
| Extended psychiatric evaluation | Up to seven days **total** from initial hold (72h + up to 96h) | SAMS / appropriately authorized clinicians |
| Extended psychiatric treatment | Up to 28 days **total** from initial hold | SAMS / appropriately authorized clinicians |
| Long-term judicial psychiatric commitment | Court-specified term; no 28-day cap | SADOJ |
| Indefinite or lifetime judicial commitment | No automatic expiration; remains until applicable court order changes | SADOJ |
| Voluntary residential or outpatient care | Not automatically a custodial hold | Authorized clinical facility process |

- SAMS is responsible for medical evaluation and treatment extensions through the 28-day framework; law enforcement does not grant those extensions.
- SADOJ is responsible for court-ordered long-term, indefinite and lifetime commitments and judicial releases.
- A SAMS discharge must not override an active SADOJ confinement order. Judicial orders must not be treated as ordinary automatically expiring medical holds.
- Grade 10 Parsons Psychiatrist may independently evaluate and admit when appropriately credentialed; administrative rank alone is not clinical authority.
- A person having access to `/commit` or `/uncommit` does not itself prove clinical or legal authorization for every requested action. Define validated permissions, medical decisions and court-order enforcement before implementation.
- Hold timestamps run on actual elapsed time, including offline time and server restarts. Activities do not reduce them. Preserve any valid extension or court order when a shorter timer expires.

### Admission and transport choices

The original `qb-prison` direct-to-facility transfer is the starting pattern. **Do not require a physical ambulance or vehicle for every commitment.** Support three roleplay choices:

1. **Direct transfer:** An authorized commitment immediately sends the patient to a configured Parsons intake/spawn location, similar to prison jail processing. Configure appropriate arrival positions/animations later based on the actual MLO.
2. **Officer transport:** Patient remains in the world while LEO arranges and performs the physical transfer to Parsons; transport can be intercepted through normal RP.
3. **Medical transport:** EMS or Parsons personnel arrange and perform the physical transfer, likewise allowing RP/interception.

For physical transport, distinguish a **legally initiated hold/order** from **physical admission at Parsons**. Track pending/in-transit/arrived operational states. An interrupted transport or escape must not erase an active commitment or automatically teleport the person to the facility. Reconcile recapture, return, discharge and court/medical changes through the appropriate authorities. Define how the legal clock starts independently of actual arrival so transport cannot arbitrarily lengthen a 72-hour hold.

### Resource boundaries and interface contract

- **qb-ambulancejob:** Add new `/commit` and `/uncommit` entry points for on-duty `job.type == 'ems' or job.type == 'leo'`; route Parsons-specific requests to qb-parsons. Maintain the fork's separately planned `ems` + `fire` medical functionality. Fire medical permissions do not automatically grant commitment authority; LEO commitment access does not grant general medical privileges.
- **qb-parsons:** Validate incoming requests and maintain only operational admission, patient location, belongings, room, hold expiration and transport state. Adapt original qb-prison mechanisms without using `injail`, `jailitems`, criminal record or prison events for Parsons.
- **PowerMoves PS-MDT:** SAMS.net owns medical records and medical extension decisions; SADOJ.net owns court records and judicial orders. Define reliable server-side event/export/callback contracts and reference IDs, with error handling/reconciliation; do not create a parallel patient-record system.
- **qb-policejob:** No edits. Existing `/jail`, `/unjail`, criminal incarceration and original locale wording remain intact.

### Next implementation tasks

- [ ] Define qb-parsons server event/export names, request payloads, response/status and trust boundaries.
- [ ] Define PS-MDT medical and judicial reference/authorization integration; document handling when PS-MDT is unavailable.
- [ ] Inspect and reuse qb-prison direct transfer, admission/release, belongings and persistence mechanisms while separating all prison metadata.
- [ ] Implement and test direct transfer first, then physical transport states and interruption behavior.
- [ ] Integrate qb-ambulancejob `/commit` and `/uncommit` only after the Parsons backend contract is stable.
- [ ] Test 72-hour expiry, seven-day and 28-day SAMS extensions, non-expiring SADOJ orders, offline time, reconnects, restarts, transport interruption and authorized release.

**Status:** Approved planning only. No gameplay implementation or external repository changes are implied by this document.
