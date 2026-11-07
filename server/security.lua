-- Stage 7 Parsons security: one property polygon; server-authoritative incident signals.
local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local incidents = {}
local nextIncident = 0
local aircraftSeen = {}
local aircraftCooldown = {}

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
    nextIncident = nextIncident + 1
    local record = {id = nextIncident, kind = kind, time = os.time(), details = details or {}}
    if kind == 'security_communications_failure' then record.details.monitoringProvider = Config.Security.provider end
    incidents[#incidents + 1] = record
    if #incidents > 100 then table.remove(incidents, 1) end
    -- Trusted dispatch and SAMS adapters subscribe server-side, and decide recipients.
    TriggerEvent('parsons:security:Incident', record)
    local dispatch = Config.Security and Config.Security.PSDispatch
    if dispatch and dispatch.enabled and dispatch.codes and dispatch.codes[kind] and GetResourceState('ps-dispatch') == 'started' then
        local point = record.details.coords or (Config.Reception and Config.Reception.coords) or
            (Config.FacilityZone.points and Config.FacilityZone.points[1])
        if point and point.x and point.y then
            local payload = {kind = kind, code = dispatch.codes and dispatch.codes[kind] or '10-90',
                jobs = dispatch.jobs, coords = {x = point.x, y = point.y, z = point.z or Config.FacilityZone.minZ or 0}}
            for _, id in ipairs(QBCore.Functions.GetPlayers()) do
                local player = QBCore.Functions.GetPlayer(id)
                if player and player.PlayerData.job and player.PlayerData.job.onduty then
                    local job = player.PlayerData.job
                    local authorized = false
                    for _, allowed in ipairs(dispatch.jobs or {}) do
                        if job.name == allowed or job.type == allowed then authorized = true break end
                    end
                    if authorized then
                        -- CustomAlert creates a shared dispatch call; emit once to avoid duplicates.
                        TriggerClientEvent('parsons:security:SendDispatch', id, payload)
                        break
                    end
                end
            end
        end
    end
    print(('[qb-parsons] Security incident %d: %s'):format(record.id, kind))
end
-- Guard peds are currently client-local. A client report cannot prove damage or death,
-- so there is intentionally NO network event that converts such reports into dispatch.
-- A future network-owned guard can use this trusted resource-only integration point.
local lastGuardAlert = 0
exports('ReportVerifiedGuardIncident', function(kind)
    local caller = GetInvokingResource()
    if caller ~= 'qb-ambulancejob' then return false, 'untrusted resource' end
    if kind ~= 'guard_assault' and kind ~= 'guard_down' then return false, 'invalid incident' end
    local point = Config.GuardShack and Config.GuardShack.coords
    if not point or type(point.x) ~= 'number' or type(point.y) ~= 'number' or type(point.z) ~= 'number' then
        return false, 'guard shack not mapped'
    end
    local now = os.time()
    if now - lastGuardAlert < 120 then return false, 'cooldown' end
    lastGuardAlert = now
    emit(kind, {coords = {x = point.x, y = point.y, z = point.z}, provider = 'Gruppe Sechs'})
    return true
end)
AddEventHandler('parsons:server:UnauthorizedDepartureVerified', function(src, citizenid)
    local coords
    local ped = type(src) == 'number' and GetPlayerPed(src)
    if ped and ped ~= 0 then
        local pos = GetEntityCoords(ped)
        coords = {x = pos.x, y = pos.y, z = pos.z}
    end
    emit('patient_departure', {citizenid = citizenid, coords = coords})
end)
AddEventHandler('parsons:server:PatientReturned', function(src, citizenid)
    emit('patient_return', {citizenid = citizenid})
end)
-- Server-owned security state; interactions must be validated before invoking.
local powerUntil, gateUntil, alarmUntil = 0, 0, 0
local lastActionAt = {}
local lastMonitoringAlert = -1000000000
local alarmReason = nil
local function raiseAlarm(reason)
    local duration = math.max(60, tonumber(Config.Security.alarm and Config.Security.alarm.durationSeconds) or 300)
    if os.time() >= alarmUntil then
        alarmReason = reason
        alarmUntil = os.time() + duration
        TriggerClientEvent('parsons:security:AlarmState', -1, true, reason)
        TriggerEvent('parsons:security:AlarmChanged', true, reason)
    end
end
-- Physical qb-doorlock changes are intentionally deferred to the dedicated fork.
-- Never spoof an online player's identity or use unlockAnyway to force door state.
-- Stage 7 records a compromised gate and raises an alarm; actual gate motion
-- must be implemented by the future trusted qb-doorlock adapter.
local function state()
    local now = os.time()
    return {powerFailure = now < powerUntil, gateCompromised = now < gateUntil, alarmActive = now < alarmUntil, alarmReason = now < alarmUntil and alarmReason or nil}
end
local function validPoint(src, point)
    if not point or type(point.x) ~= 'number' or type(point.y) ~= 'number' or type(point.z) ~= 'number' then return false end
    if type(src) ~= 'number' or src < 1 then return false end
    local ped = GetPlayerPed(src)
    return ped ~= nil and ped ~= 0 and #(GetEntityCoords(ped) - vector3(point.x, point.y, point.z)) <= 3.0
end
local function act(src, action)
    local cfg = Config.Security
    if not cfg or not cfg.electrical or not cfg.gate then return false end
    local now = os.time()
    if not src or not QBCore.Functions.GetPlayer(src) then return false end
    if action == 'electrical_inside' or action == 'electrical_outside' then
        local point = action == 'electrical_inside' and cfg.electrical.inside or cfg.electrical.outside
        if not validPoint(src, point) or now < powerUntil then return false end
        powerUntil = now + math.max(30, tonumber(cfg.electrical.durationSeconds) or 180)
        if now - lastMonitoringAlert >= math.max(0, tonumber(cfg.monitoring and cfg.monitoring.incidentCooldownSeconds) or 120) then
            lastMonitoringAlert = now
            emit('security_communications_failure', {powerUntil = powerUntil})
        end
    elseif action == 'gate_hack' then
        if not validPoint(src, cfg.gate.hack) or now < gateUntil then return false end
        gateUntil = now + math.max(30, tonumber(cfg.gate.compromisedSeconds) or 120)
        -- Physical gate unlock is deferred; security incident remains operational.
        raiseAlarm('gate_security_compromised')
        emit('gate_security_compromised', {gateUntil = gateUntil})
    else
        return false
    end
    TriggerClientEvent('parsons:security:State', -1, state())
    TriggerEvent('parsons:security:GateStateChanged', state())
    return true
end
local attempts = {}
local function actionPoint(action)
    local cfg = Config.Security
    if not cfg or not cfg.electrical or not cfg.gate then return nil end
    if action == 'electrical_inside' then return cfg.electrical.inside end
    if action == 'electrical_outside' then return cfg.electrical.outside end
    if action == 'gate_hack' then return cfg.gate.hack end
end
local function hasTools(src, action)
    local player = QBCore.Functions.GetPlayer(src)
    if not player then return false end
    local cfg = Config.Security
    local item = action == 'gate_hack' and cfg.gate.item or cfg.electrical.item
    if type(item) ~= 'string' or item == '' then return false end
    local found = player.Functions.GetItemByName(item)
    return found ~= nil and (tonumber(found.amount) or 0) >= 1
end
RegisterNetEvent('parsons:security:BeginAction', function(action)
    local src = source
    if type(action) ~= 'string' or not validPoint(src, actionPoint(action)) or not hasTools(src, action) then
        TriggerClientEvent('parsons:security:BeginDenied', src, 'Security station unavailable or required tool missing.')
        return
    end
    local now = os.time()
    if attempts[src] and now - attempts[src].started < 120 then return end
    if (action == 'gate_hack' and now < gateUntil)
        or ((action == 'electrical_inside' or action == 'electrical_outside') and now < powerUntil) then
        TriggerClientEvent('parsons:security:ActionResult', src, false, action)
        return
    end
    if now < (lastActionAt[src] or 0) then return end
    lastActionAt[src] = now + math.max(5, tonumber(Config.Security.actionRetrySeconds) or 15)
    attempts[src] = {action = action, started = now, token = math.random(100000,999999)}
    TriggerClientEvent('parsons:security:StartAction', src, action, attempts[src].token)
end)
RegisterNetEvent('parsons:security:FinishAction', function(action, token, succeeded)
    local src = source
    local pending = attempts[src]
    attempts[src] = nil
    if not pending or pending.action ~= action or pending.token ~= token then
        TriggerClientEvent('parsons:security:ActionResult', src, false, action)
        return
    end
    -- The client reports a minigame result, not proof of success. Enforce a
    -- server-observed minimum interaction duration and revalidate all conditions.
    local elapsed = os.time() - pending.started
    local minimum = math.max(2, math.floor(tonumber(Config.Security and Config.Security.minimumActionSeconds) or 5))
    if elapsed > 120 or not validPoint(src, actionPoint(action)) or not hasTools(src, action) then
        TriggerClientEvent('parsons:security:ActionResult', src, false, action)
        return
    end
    if succeeded == true and elapsed < minimum then
        TriggerClientEvent('parsons:security:ActionResult', src, false, action)
        return
    end
    if succeeded ~= true then
        if action == 'gate_hack' and validPoint(src, actionPoint(action)) then
            raiseAlarm('failed_gate_hack')
            emit('failed_gate_hack', {coords = actionPoint(action)})
            TriggerClientEvent('parsons:security:State', -1, state())
        end
        TriggerClientEvent('parsons:security:ActionResult', src, false, action)
        return
    end
    local applied = act(src, action)
    TriggerClientEvent('parsons:security:ActionResult', src, applied == true, action)
end)
RegisterNetEvent('parsons:security:ResetAlarm', function(index)
    local src = source
    local cfg = Config.Security and Config.Security.alarm
    if not cfg or type(index) ~= 'number' or index % 1 ~= 0 then return end
    local point = cfg.resetPoints and cfg.resetPoints[index]
    if not validPoint(src, point) then return end
    local player = QBCore.Functions.GetPlayer(src)
    local job = player and player.PlayerData and player.PlayerData.job
    if not job or not job.onduty then return end
    local allowed = false
    for _, kind in ipairs(cfg.resetJobTypes or {}) do
        if job.type == kind then allowed = true; break end
    end
    if not allowed or os.time() >= alarmUntil then return end
    alarmUntil = 0
    alarmReason = nil
    TriggerClientEvent('parsons:security:AlarmState', -1, false)
    TriggerEvent('parsons:security:AlarmChanged', false, 'authorized_reset')
    emit('security_alarm_reset', {by = player.PlayerData.citizenid, coords = {x = point.x, y = point.y, z = point.z}})
    TriggerClientEvent('parsons:security:State', -1, state())
end)
RegisterNetEvent('parsons:security:RequestState', function()
    local src = source
    TriggerClientEvent('parsons:security:State', src, state())
    local current = state()
    if current.alarmActive then
        TriggerClientEvent('parsons:security:AlarmState', src, true, current.alarmReason)
    end
end)
AddEventHandler('playerDropped', function()
    attempts[source] = nil
    lastActionAt[source] = nil
end)
-- Deliberately restricted: no untrusted client event can assert a successful hack.
exports('ApplyVerifiedSecurityAction', function(src, action)
    local caller = GetInvokingResource()
    if caller ~= 'qb-ambulancejob' then return false, 'untrusted resource' end
    return act(tonumber(src), action)
end)
exports('GetFacilitySecurityState', function()
    if GetInvokingResource() ~= 'qb-ambulancejob' then return nil, 'untrusted resource' end
    return state()
end)
CreateThread(function()
    local wasPower, wasGate = false, false
    while true do
        Wait(2000)
        local current = state()
        if alarmUntil > 0 and os.time() >= alarmUntil then
            alarmUntil = 0
            alarmReason = nil
            TriggerClientEvent('parsons:security:AlarmState', -1, false)
            TriggerEvent('parsons:security:AlarmChanged', false, 'failsafe_timeout')
            TriggerClientEvent('parsons:security:State', -1, state())
        end
        if wasPower and not current.powerFailure then emit('security_communications_restored') end
        if wasGate and not current.gateCompromised then
            emit('gate_security_restored')
        end
        if wasPower ~= current.powerFailure or wasGate ~= current.gateCompromised then
            TriggerClientEvent('parsons:security:State', -1, current)
            TriggerEvent('parsons:security:GateStateChanged', current)
        end
        wasPower, wasGate = current.powerFailure, current.gateCompromised
    end
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
                            local pilot = QBCore.Functions.GetPlayer(src)
                            local job = pilot and pilot.PlayerData and pilot.PlayerData.job
                            local exempt = false
                            if job and job.onduty then
                                for _, allowed in ipairs(cfg.exemptJobTypes or {}) do
                                    if job.type == allowed then exempt = true; break end
                                end
                            end
                            if not exempt then
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
                            end -- authorized on-duty emergency pilot exemption
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
