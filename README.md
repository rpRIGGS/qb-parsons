# qb-parsons

**Parsons Rehabilitation Center — Psychiatric & Rehabilitation Facility**

A PowerMoves RP-specific QBCore FiveM resource adapted from the original [qb-prison](https://github.com/qbcore-fivem/qb-prison) project.

> **PowerMoves RP only:** This adaptation is being designed and configured specifically for the PowerMoves RP server, its Parsons Rehabilitation Center interior, and its gameplay systems. It is **not** intended as a drop-in, general-purpose resource for other FiveM servers. This describes the project's intended support and compatibility, **not** a restriction on rights granted by the original GPL license.

## Overview

qb-parsons is planned to transform prison mechanics into a small psychiatric and rehabilitation facility with voluntary treatment, involuntary evaluation holds, court-ordered commitments, counseling, and secure patient accommodation.

**Development status:** Initial fork / planning. The features below are a roadmap, not a claim that they currently work. The underlying fork may still contain original qb-prison behavior until adapted.

## Planned Features

### Admissions and commitments
- Voluntary residential admissions and outpatient treatment
- Involuntary 72-hour psychiatric evaluation holds
- Court-ordered commitments and authorized extensions
- Intake, patient status, referrals, transfers, and discharge
- Real elapsed-time hold tracking, including while a player is offline
- No hold-time reductions from facility activities

### Patient rooms and belongings
- Individual room assignments
- Personal storage and secure handling of restricted belongings
- Patient clothing and wardrobe access
- Property return during authorized discharge

### Treatment and rehabilitation
- Individual and group counseling
- Substance-use and gambling-related treatment roleplay
- Recreational activities and supervised daily routines
- Outpatient appointments and follow-up visits

### Facility operations and security
- On-duty Parsons medical staff and authorized clinical admissions
- Controlled doors, perimeter gate, and guard shack
- Patient movement and access management
- Incident records and unauthorized departure / escape handling

## Framework and Planned Integrations

- QBCore (`qb-core`)
- `qb-target`
- PowerMoves RP customized `qb-inventory`
- `ox_lib`

The adaptation will retain the PowerMoves RP QBCore ecosystem; no migration to `ox_target` or `ox_inventory` is planned. Exact dependencies and setup steps will be documented as implementation progresses.

## Credits and License

Adapted from [QBCore qb-prison](https://github.com/qbcore-fivem/qb-prison). Original authors and contributors retain their respective credits. PowerMoves RP is responsible for its own adaptation.

The PowerMoves RP-only statement above is a compatibility and project-scope notice, not a change to the open-source license. The original license notice follows.

# License

    QBCore Framework
    Copyright (C) 2021 Joshua Eger

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>
