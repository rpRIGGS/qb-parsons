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
    cb({authorized = true, patients = patients})
end)
