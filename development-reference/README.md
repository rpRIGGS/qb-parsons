# qb-parsons Development Reference

Planning checklist for PowerMoves RP Parsons Rehabilitation Center.

## Foundation
- [ ] Audit original qb-prison functionality and dependencies.
- [ ] Separate Parsons admissions and records from prison sentences.
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

## Records and certifications
- [ ] Admission, hold, assessment, treatment, counseling and progress records.
- [ ] Hospital referral and transfer records.
- [ ] Judicial extensions, discharge and facility incident records.
- [ ] Track medical, nursing, counseling and technician qualifications, training and expiration.

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
- Involuntary 72-hour psychiatric evaluation holds under existing PowerMoves law.
- Court-ordered commitments and authorized extended treatment.
- Outpatient counseling and follow-up without residential confinement.

### Hold and discharge behavior
- Track actual start/end timestamps, including offline elapsed time and restarts.
- Do not shorten holds for work, therapy, or recreational activities.
- At hold expiry, check whether a lawful extension/order exists; never release solely on a countdown when an active order supersedes it.
- Record authorized discharge and return of stored belongings.
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

### Record categories to support
- Admission source, consent/legal basis, responsible clinician and room assignment.
- Evaluation hold initiator, justification, timestamps, reviews and status.
- Psychiatric evaluations, treatment plans, therapy sessions and progress notes.
- Nursing/behavioral observations.
- Hospital consultation, referral, transfer and acceptance.
- Extended commitments, judicial review dates and discharge authorization.
- Incidents, unauthorized departures, personal belongings and room history.

### Credentials and certifications to account for
- Psychiatrist medical license and psychiatric specialization.
- Psychiatric nurse practitioner authorization; RN, LPN and CNA credentials.
- Mental health and substance-use counselor qualifications and supervision.
- Behavioral health/psychiatric technician training.
- Facility orientation, safety/de-escalation training, credential status and renewals.

Long-form confidential medical records and court orders can be integrated later; qb-parsons should focus on gameplay and the facility state, with appropriate access controls rather than unrestricted copies.

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

- [ ] Inspect the installed PowerMoves `qb-policejob` and define a separate Parsons admission/transport action for authorized law enforcement personnel; preserve criminal jail operations.
- [ ] Support judicially ordered commitments initiated by a Division of Law Enforcement officer assigned to courtroom security.
- [ ] Request ambulance service for medical transport; officer custody coordination and medical transport are distinct responsibilities.
- [ ] Support legally authorized clinician-initiated holds and hospital referrals without requiring an officer for every admission.
- [ ] Validate order/hold authority and Parsons intake server-side; do not reuse prison `injail` state or assume job name `police`.
- [ ] Test courtroom order -> officer custody -> ambulance request -> Parsons acceptance and admission.

See [INSTALLATION.md](INSTALLATION.md) for dependencies, required changes to the police/ambulance integrations, and the future deployment checklist. **No integration code has been changed yet.**
