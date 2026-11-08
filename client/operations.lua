-- Stage 8 medical operations terminal; qb-target is required.
local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local function showPatientNotes(patient)
    QBCore.Functions.TriggerCallback('parsons:operations:GetShiftNotes', function(result)
        if not result or not result.authorized then
            lib.notify({title = 'Parsons operations', description = result and result.reason or 'Access denied.', type = 'error'})
            return
        end
        local options = {{
            title = 'Write shift handoff note',
            description = 'Operational notes only — use PS-MDT for medical charts',
            icon = 'pen',
            onSelect = function()
                local values = lib.inputDialog('Shift note — ' .. patient.name, {
                    {type = 'textarea', label = 'Handoff note', required = true, min = 3, max = 500}
                })
                if values and type(values[1]) == 'string' then
                    TriggerServerEvent('parsons:operations:AddShiftNote', patient.id, values[1])
                end
            end
        }}
        local notes = result.notes or {}
        for i = #notes, 1, -1 do
            local note = notes[i]
            options[#options + 1] = {
                title = (note.staff or 'Staff') .. ' — ' .. os.date('%Y-%m-%d %H:%M', note.at or os.time()),
                description = note.message or '',
                icon = 'note-sticky', readOnly = true
            }
        end
        lib.registerContext({
            id = 'parsons_patient_shift_notes', title = 'Shift notes — ' .. patient.name,
            menu = 'parsons_medical_census', options = options
        })
        lib.showContext('parsons_patient_shift_notes')
    end, patient.id)
end
RegisterNetEvent('parsons:operations:NoteResult', function(success, message)
    lib.notify({title = 'Parsons operations', description = message or 'Shift note result', type = success and 'success' or 'error'})
end)

local function openCensus()
    QBCore.Functions.TriggerCallback('parsons:operations:GetCensus', function(result)
        if not result or not result.authorized then
            lib.notify({title = 'Parsons operations', description = result and result.reason or 'Access denied.', type = 'error'})
            return
        end
        local options = {}
        for _, patient in ipairs(result.patients or {}) do
            local status = patient.absent and 'Away / escape' or
                (patient.transport and 'Authorized transport' or
                (patient.reentryPending and 'Reentry clearance required' or
                (patient.checkedIn and 'Checked in' or 'Awaiting check-in')))
            if patient.roomExpired then status = 'Room reservation expired' end
            options[#options + 1] = {
                title = patient.name .. ' (#' .. patient.id .. ')',
                description = ('%s | %s | Room: %s | %s'):format(
                    patient.careSetting or 'residential', patient.phase or patient.kind or 'care',
                    patient.room or 'Unassigned', status),
                icon = 'user-doctor',
                onSelect = function() showPatientNotes(patient) end
            }
        end
        if #options == 0 then
            options[1] = {title = 'No online Parsons patients', readOnly = true}
        end
        local staffOptions = {}
        for _, worker in ipairs(result.staff or {}) do
            staffOptions[#staffOptions + 1] = {
                title = worker.name .. ' (#' .. worker.id .. ')',
                description = worker.job .. ' — ' .. worker.grade,
                icon = 'user-nurse', readOnly = true
            }
        end
        if #staffOptions == 0 then staffOptions[1] = {title = 'No medical staff on duty', readOnly = true} end
        local roomOptions = {}
        for _, room in ipairs(result.rooms or {}) do
            roomOptions[#roomOptions + 1] = {
                title = room.id .. ' (' .. room.housing .. ')',
                description = not room.occupied and 'Available' or
                    (room.absentSince and 'Reserved — patient absent' or 'Occupied'),
                icon = room.occupied and 'bed' or 'door-open', readOnly = true
            }
        end
        if #roomOptions == 0 then roomOptions[1] = {title = 'No configured patient rooms', readOnly = true} end
        lib.registerContext({id = 'parsons_medical_census', title = 'Parsons — Patient Census', options = options})
        lib.registerContext({id = 'parsons_staff_roster', title = 'Parsons — On-Duty Staff', options = staffOptions})
        lib.registerContext({id = 'parsons_room_board', title = 'Parsons — Room Board', options = roomOptions})
        local occupied = 0
        for _, room in ipairs(result.rooms or {}) do
            if room.occupied then occupied = occupied + 1 end
        end
        lib.registerContext({id = 'parsons_operations', title = 'Parsons — Operations', options = {
            {title = 'Patient census', description = #result.patients .. ' active online records',
                icon = 'clipboard-list', menu = 'parsons_medical_census'},
            {title = 'On-duty staff', description = #(result.staff or {}) .. ' authorized staff online',
                icon = 'user-nurse', menu = 'parsons_staff_roster'},
            {title = 'Room availability', description = occupied .. ' occupied / ' .. #(result.rooms or {}) .. ' configured rooms',
                icon = 'bed', menu = 'parsons_room_board'}
        }})
        lib.showContext('parsons_operations')
    end)
end

CreateThread(function()
    Wait(1500)
    local reception = Config.Reception
    if not reception or not reception.coords then return end
    local points = {reception.coords}
    for _, point in ipairs(reception.additionalCoords or {}) do points[#points + 1] = point end
    for index, point in ipairs(points) do
        if point and point.x and point.y and point.z then
            exports['qb-target']:AddBoxZone('parsons_medical_census_' .. index,
                vector3(point.x, point.y, point.z), 1.5, 1.5,
                {name = 'parsons_medical_census_' .. index, heading = point.w or 0,
                    minZ = point.z - 1, maxZ = point.z + 1},
                {options = {{icon = 'fas fa-clipboard-list', label = 'Parsons medical patient census',
                    action = openCensus}}, distance = 2.5})
        end
    end
end)
