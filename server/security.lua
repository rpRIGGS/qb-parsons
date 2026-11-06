-- Stage 7 Parsons security: one property polygon; server-authoritative incident signals.
local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local incidents = {}
local nextIncident = 0
local aircraftSeen = {}
local aircraftCooldown = {}
local activeIncident = nil

local function withinProperty(pos)
    local z = Config.FacilityZone
    if type(z) ~= 'table' or type(z.points) ~= 'table' or #z.points < 3 or
        type(z.minZ) ~= 'number' or type(z.maxZ) ~= 'number' or
        pos.z < z.minZ or pos.z > z.maxZ then return false end
    local inside, j = false, #z.points
    for i = 1, #z.points do
        local a, b = z.points[i], z.points[j]
        if type(a.x) ~= 'number' or type(a.y) ~= 'number' or
            type(b.x) ~= 'number' or type(b.y) ~= 'number' then return false end
        if (a.y > pos.y) ~= (b.y > pos.y) then
            local cross = (b.x-a.x)*(pos.y-a.y)/(b.y-a.y)+a.x
            if pos.x < cross then inside = not inside end
        end
        j = i
    end
    return inside
end
local function emit(kind, details)
    if not activeIncident or kind == 'patient_return' then
        nextIncident = nextIncident + 1
        activeIncident = nextIncident
    end
    local record = {id = activeIncident, kind = kind, time = os.time(), details = details or {}}
    if kind == 'patient_return' then activeIncident = nil end
    incidents[#incidents + 1] = record
    if #incidents > 100 then table.remove(incidents, 1) end
    -- Trusted dispatch and SAMS adapters subscribe server-side, and decide recipients.
    TriggerEvent('parsons:security:Incident', record)
    print(('[qb-parsons] Security incident %d: %s'):format(record.id, kind))
end
AddEventHandler('parsons:server:UnauthorizedDepartureVerified', function(src, citizenid)
    emit('patient_departure', {citizenid = citizenid})
end)
AddEventHandler('parsons:server:PatientReturned', function(src, citizenid)
    emit('patient_return', {citizenid = citizenid})
end)
-- Inspect server-observed vehicles rather than accepting client aircraft reports.
CreateThread(function()
    while true do
        Wait(2000)
        local cfg = Config.Security and Config.Security.aircraft
        if cfg and cfg.enabled then
            local now = os.time()
            local present = {}
            for _, src in ipairs(QBCore.Functions.GetPlayers()) do
                local ped = GetPlayerPed(src)
                if ped and ped ~= 0 then
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    if vehicle and vehicle ~= 0 and GetPedInVehicleSeat(vehicle, -1) == ped then
                        local class = GetVehicleClass(vehicle)
                        if class == 15 or class == 16 then
                            local pos = GetEntityCoords(vehicle)
                            if withinProperty(pos) then
                                local key = tostring(vehicle)
                                present[key] = true
                                aircraftSeen[key] = aircraftSeen[key] or now
                                local verify = math.max(1, tonumber(cfg.verifySeconds) or 5)
                                local cooldown = math.max(30, tonumber(cfg.cooldownSeconds) or 180)
                                if now - aircraftSeen[key] >= verify and
                                    now >= (aircraftCooldown[key] or 0) then
                                    aircraftCooldown[key] = now + cooldown
                                    emit('unauthorized_aircraft', {
                                        coords = {x = pos.x, y = pos.y, z = pos.z},
                                        vehicleClass = class
                                    })
                                end
                            end
                        end
                    end
                end
            end
            for key in pairs(aircraftSeen) do
                if not present[key] then aircraftSeen[key] = nil end
            end
            for key, expiry in pairs(aircraftCooldown) do
                if now >= expiry then aircraftCooldown[key] = nil end
            end
        end
    end
end)
exports('GetRecentSecurityIncidents', function()
    local caller = GetInvokingResource()
    if caller ~= 'qb-ambulancejob' then return nil, 'untrusted resource' end
    local result = {}
    for i, record in ipairs(incidents) do
        result[i] = {id = record.id, kind = record.kind, time = record.time, details = record.details}
    end
    return result
end)
