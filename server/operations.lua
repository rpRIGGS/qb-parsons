-- Stage 8: medical operations roster. Server authorizes every request.
local QBCore = exports['qb-core']:GetCoreObject({'Functions'})

local function isStaff(player)
    local job = player and player.PlayerData and player.PlayerData.job
    if not job or not job.onduty then return false end
    for _, allowed in ipairs(Config.PatientRoomStaffJobTypes or {'ems'}) do
        if job.type == allowed or job.name == allowed then return true end
    end
    return false
end

local function atReception(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local coords = GetEntityCoords(ped)
    local reception = Config.Reception
    if not reception then return false end
    local points = {reception.coords}
    for _, point in ipairs(reception.additionalCoords or {}) do points[#points + 1] = point end
    for _, point in ipairs(points) do
        if point and point.x and point.y and point.z
            and #(coords - vector3(point.x, point.y, point.z)) <= 4.0 then return true end
    end
    return false
end

-- Operational shift notes are not medical charts; PS-MDT owns clinical records.
local NOTE_KEY = 'parsons_shift_notes'
local NOTE_LIMIT = 20
local NOTE_LENGTH = 500
local function validPatient(src, targetId)
    local id = tonumber(targetId)
    if not id or id < 1 or id % 1 ~= 0 then return nil end
    local patient = QBCore.Functions.GetPlayer(id)
    local data = patient and patient.PlayerData
    local hold = data and data.metadata and data.metadata.parsons_hold
    if not hold or hold.active ~= true then return nil end
    -- The authorized receptionist can review the active online patient
    -- anywhere in Parsons; server access is already restricted to reception.
    return patient
end

-- Staff-to-patient assignment for the current admission, not a legal
-- authorization or treatment decision. Assignments persist on patient metadata.
local ASSIGNMENT_KEY = 'parsons_care_assignment'
RegisterNetEvent('parsons:operations:AssignCareStaff', function(targetId, workerId)
    local src = source
    local actor = QBCore.Functions.GetPlayer(src)
    if not isStaff(actor) or not atReception(src) then return end
    local patient = validPatient(src, targetId)
    if not patient then
        TriggerClientEvent('parsons:operations:NoteResult', src, false, 'Active patient not found.')
        return
    end
    local worker = QBCore.Functions.GetPlayer(tonumber(workerId))
    if not isStaff(worker) then
        TriggerClientEvent('parsons:operations:NoteResult', src, false, 'Assigned staff must be on duty.')
        return
    end
    local hold = patient.PlayerData.metadata.parsons_hold
    local assignment = {
        admissionStartedAt = hold.startedAt,
        staffCitizenId = worker.PlayerData.citizenid,
        staffName = ((worker.PlayerData.charinfo and worker.PlayerData.charinfo.firstname) or 'Staff') ..
            ' ' .. ((worker.PlayerData.charinfo and worker.PlayerData.charinfo.lastname) or ''),
        assignedBy = actor.PlayerData.citizenid,
        assignedAt = os.time()
    }
    patient.Functions.SetMetaData(ASSIGNMENT_KEY, assignment)
    patient.Functions.Save()
    TriggerEvent('parsons:operations:CareStaffAssigned', {
        patientCitizenId = patient.PlayerData.citizenid,
        staffCitizenId = assignment.staffCitizenId,
        assignedBy = assignment.assignedBy, admissionStartedAt = hold.startedAt
    })
    TriggerClientEvent('parsons:operations:NoteResult', src, true, 'Care staff assigned.')
end)

QBCore.Functions.CreateCallback('parsons:operations:GetActivityHistory', function(src, cb, targetId)
    local staff = QBCore.Functions.GetPlayer(src)
    if not isStaff(staff) or not atReception(src) then
        cb({authorized = false, reason = 'Authorized staff must use reception.'})
        return
    end
    local patient = validPatient(src, targetId)
    if not patient then cb({authorized = false, reason = 'Patient is not online or has no active Parsons admission.'}); return end
    local hold = patient.PlayerData.metadata.parsons_hold
    local entries = type(hold.activities) == 'table' and hold.activities or {}
    local history = {}
    for i = math.max(1, #entries - 49), #entries do
        local entry = entries[i]
        if type(entry) == 'table' then
            history[#history + 1] = {
                id = entry.id, completedAt = entry.completedAt,
                durationSeconds = entry.durationSeconds
            }
        end
    end
    cb({authorized = true, history = history})
end)

QBCore.Functions.CreateCallback('parsons:operations:GetShiftNotes', function(src, cb, targetId)
    local staff = QBCore.Functions.GetPlayer(src)
    if not isStaff(staff) or not atReception(src) then
        cb({authorized = false, reason = 'Authorized staff must use reception.'})
        return
    end
    local patient = validPatient(src, targetId)
    if not patient then cb({authorized = false, reason = 'Patient is not online or has no active Parsons admission.'}); return end
    local record = patient.PlayerData.metadata and patient.PlayerData.metadata[NOTE_KEY]
    local hold = patient.PlayerData.metadata.parsons_hold
    local notes = type(record) == 'table' and record.admissionStartedAt == hold.startedAt
        and type(record.entries) == 'table' and record.entries or {}
    cb({authorized = true, notes = notes})
end)

RegisterNetEvent('parsons:operations:AddShiftNote', function(targetId, message)
    local src = source
    local staff = QBCore.Functions.GetPlayer(src)
    if not isStaff(staff) or not atReception(src) then return end
    local patient = validPatient(src, targetId)
    if not patient then
        TriggerClientEvent('parsons:operations:NoteResult', src, false, 'Patient is not online or has no active Parsons admission.')
        return
    end
    if type(message) ~= 'string' then return end
    message = message:gsub('%c', ' '):match('^%s*(.-)%s*, function(src, cb)
    local staff = QBCore.Functions.GetPlayer(src)
    if not isStaff(staff) or not atReception(src) then
        cb({authorized = false, reason = 'On-duty Parsons medical staff must use reception.'})
        return
    end
    local patients = {}
    for _, id in ipairs(QBCore.Functions.GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(id)
        local data = player and player.PlayerData
        local hold = data and data.metadata and data.metadata.parsons_hold
        if type(hold) == 'table' and hold.active == true then
            local assignment = data.metadata and data.metadata[ASSIGNMENT_KEY]
            if type(assignment) ~= 'table' or assignment.admissionStartedAt ~= hold.startedAt then
                assignment = nil
            end
            patients[#patients + 1] = {
                assignedStaff = assignment and assignment.staffName or nil,
                id = id,
                name = ((data.charinfo and data.charinfo.firstname) or 'Patient') .. ' ' ..
                    ((data.charinfo and data.charinfo.lastname) or ''),
                careSetting = hold.careSetting or (hold.kind == 'outpatient' and 'outpatient' or 'residential'),
                kind = hold.kind,
                phase = hold.phase,
                room = hold.roomId or 'Unassigned',
                checkedIn = hold.checkedIn == true,
                absent = hold.absentSince ~= nil,
                reentryPending = hold.reentryInventoryPending == true,
                transport = hold.transport and hold.transport.active == true,
                roomExpired = hold.roomReservationExpired == true
            }
        end
    end
    table.sort(patients, function(a, b) return a.id < b.id end)
    local staffRoster = {}
    for _, id in ipairs(QBCore.Functions.GetPlayers()) do
        local worker = QBCore.Functions.GetPlayer(id)
        if isStaff(worker) then
            local info = worker.PlayerData
            staffRoster[#staffRoster + 1] = {
                id = id,
                name = ((info.charinfo and info.charinfo.firstname) or 'Staff') .. ' ' ..
                    ((info.charinfo and info.charinfo.lastname) or ''),
                job = info.job.label or info.job.name,
                grade = (info.job.grade and info.job.grade.name) or 'Staff'
            }
        end
    end
    table.sort(staffRoster, function(a, b) return a.id < b.id end)
    local rooms = {}
    for _, room in ipairs(Config.PatientRooms or {}) do
        local owner = GetResourceKvpString('parsons_room_' .. room.id)
        local absentAt = GetResourceKvpInt('parsons_absence_' .. room.id)
        rooms[#rooms + 1] = {
            id = room.id,
            housing = room.housing or 'standard',
            occupied = owner ~= nil and owner ~= '',
            absentSince = absentAt and absentAt > 0 and absentAt or nil,
            reservationExpiresAt = absentAt and absentAt > 0 and
                (absentAt + math.max(1, tonumber(Config.EscapeRoomGraceHours) or 48) * 3600) or nil
        }
    end
    cb({authorized = true, patients = patients, staff = staffRoster, rooms = rooms})
end)
)
    if #message < 3 or #message > NOTE_LENGTH then
        TriggerClientEvent('parsons:operations:NoteResult', src, false, 'Shift note must be 3–500 characters.')
        return
    end
    local hold = patient.PlayerData.metadata.parsons_hold
    local record = patient.PlayerData.metadata and patient.PlayerData.metadata[NOTE_KEY]
    local notes = type(record) == 'table' and record.admissionStartedAt == hold.startedAt
        and type(record.entries) == 'table' and record.entries or {}
    notes[#notes + 1] = {
        at = os.time(), by = staff.PlayerData.citizenid,
        staff = ((staff.PlayerData.charinfo and staff.PlayerData.charinfo.firstname) or 'Staff') .. ' ' ..
            ((staff.PlayerData.charinfo and staff.PlayerData.charinfo.lastname) or ''),
        message = message
    }
    while #notes > NOTE_LIMIT do table.remove(notes, 1) end
    patient.Functions.SetMetaData(NOTE_KEY, {admissionStartedAt = hold.startedAt, entries = notes})
    patient.Functions.Save()
    TriggerEvent('parsons:operations:ShiftNoteRecorded', {
        patientCitizenId = patient.PlayerData.citizenid,
        staffCitizenId = staff.PlayerData.citizenid,
        admissionStartedAt = hold.startedAt,
        recordedAt = notes[#notes].at
    })
    TriggerClientEvent('parsons:operations:NoteResult', src, true, 'Shift note saved.')
end)

QBCore.Functions.CreateCallback('parsons:operations:GetCensus', function(src, cb)
    local staff = QBCore.Functions.GetPlayer(src)
    if not isStaff(staff) or not atReception(src) then
        cb({authorized = false, reason = 'On-duty Parsons medical staff must use reception.'})
        return
    end
    local patients = {}
    for _, id in ipairs(QBCore.Functions.GetPlayers()) do
        local player = QBCore.Functions.GetPlayer(id)
        local data = player and player.PlayerData
        local hold = data and data.metadata and data.metadata.parsons_hold
        if type(hold) == 'table' and hold.active == true then
            patients[#patients + 1] = {
                id = id,
                name = ((data.charinfo and data.charinfo.firstname) or 'Patient') .. ' ' ..
                    ((data.charinfo and data.charinfo.lastname) or ''),
                careSetting = hold.careSetting or (hold.kind == 'outpatient' and 'outpatient' or 'residential'),
                kind = hold.kind,
                phase = hold.phase,
                room = hold.roomId or 'Unassigned',
                checkedIn = hold.checkedIn == true,
                absent = hold.absentSince ~= nil,
                reentryPending = hold.reentryInventoryPending == true,
                transport = hold.transport and hold.transport.active == true,
                roomExpired = hold.roomReservationExpired == true
            }
        end
    end
    table.sort(patients, function(a, b) return a.id < b.id end)
    local staffRoster = {}
    for _, id in ipairs(QBCore.Functions.GetPlayers()) do
        local worker = QBCore.Functions.GetPlayer(id)
        if isStaff(worker) then
            local info = worker.PlayerData
            staffRoster[#staffRoster + 1] = {
                id = id,
                name = ((info.charinfo and info.charinfo.firstname) or 'Staff') .. ' ' ..
                    ((info.charinfo and info.charinfo.lastname) or ''),
                job = info.job.label or info.job.name,
                grade = (info.job.grade and info.job.grade.name) or 'Staff'
            }
        end
    end
    table.sort(staffRoster, function(a, b) return a.id < b.id end)
    local rooms = {}
    for _, room in ipairs(Config.PatientRooms or {}) do
        local owner = GetResourceKvpString('parsons_room_' .. room.id)
        local absentAt = GetResourceKvpInt('parsons_absence_' .. room.id)
        rooms[#rooms + 1] = {
            id = room.id,
            housing = room.housing or 'standard',
            occupied = owner ~= nil and owner ~= '',
            absentSince = absentAt and absentAt > 0 and absentAt or nil
        }
    end
    cb({authorized = true, patients = patients, staff = staffRoster, rooms = rooms})
end)
