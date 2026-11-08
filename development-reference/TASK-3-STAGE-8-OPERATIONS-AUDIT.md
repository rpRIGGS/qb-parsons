# Task 3 — Stage 8: Parsons operations and staff management

## Implemented
- Mandatory qb-target reception operations terminal with ox_lib context menus.
- Server-side on-duty medical staff and reception-distance checks for every data request and write.
- Online active patient census with residential/outpatient status, check-in, escape, transport, reentry, room assignment, and assigned care staff.
- Online on-duty authorized medical staff roster and grade.
- Persistent configured room occupancy board, including absent-patient reservation expiry based on the configured 48-hour grace.
- Per-admission, server-validated staff-to-patient assignment, with a server audit event. Assignments do not confer judicial or clinical authority.
- Admission-scoped persistent shift handoff notes (up to 20 entries, 500 characters each), staff attribution, and a privacy-minimized server audit event.
- Read-only completed activity history, from the authoritative Parsons hold metadata. No activity can reduce treatment time.
- Patient notes and assignments are limited to the current admission to avoid carrying operational records into later admissions.

## Integration boundaries
- PS-MDT remains authoritative for medical charts, treatment orders, judicial decisions, and confidential records. Shift notes here are operational only.
- QBCore job duty and configured medical job types remain the staff authorization source; no independent job/grade or payroll system is introduced.
- qb-doorlock physical access remains in the separately planned fork.
- Existing room, intake, discharge, transport and security authority remain in their respective server modules.
- MLO coordinates beyond the already mapped reception/guard positions are configuration work, not blockers for this stage.

## Deployment QA (not performed here)
1. Authorized on-duty medical staff at reception can open the dashboard; off-duty, unrelated jobs and distant players cannot.
2. Census reflects pending and checked-in patients, escape/transport/reentry, and new admissions.
3. Staff assignments reject nonstaff/off-duty IDs and remain scoped to the current admission.
4. Shift notes persist through reconnects, reject malformed/oversized submissions, and do not carry over to later admissions.
5. Activity history matches completed sessions, and room board reflects KVP reservations and grace expiry.
6. Restart resource, inspect F8/server console for errors, and verify qb-target menu registration.

**Development status:** Task 3 Stage 8 functionality implemented and committed. Live FiveM testing is outstanding; do not describe it as gameplay-verified.
