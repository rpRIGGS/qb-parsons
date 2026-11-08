-- Stage 7 configurable sabotage/gate interactions. No legacy prison coordinates.
local actions = {
    {key = 'electrical_inside', label = 'Tamper with electrical panel', config = function() return Config.Security.electrical.inside end},
    {key = 'electrical_outside', label = 'Sabotage electrical service', config = function() return Config.Security.electrical.outside end},
    {key = 'gate_hack', label = 'Bypass gate electronics', config = function() return Config.Security.gate.hack end}
}
local busy = false
local requesting = false
local requestSerial = 0
local function start(key)
    if busy or requesting then return end
    requesting = true
    requestSerial = requestSerial + 1
    local serial = requestSerial
    TriggerServerEvent('parsons:security:BeginAction', key)
    SetTimeout(3000, function()
        if requesting and requestSerial == serial then
            requesting = false
            lib.notify({title = 'Parsons security', description = 'Security action unavailable at this location or required tool missing.', type = 'error'})
        end
    end)
end
RegisterNetEvent('parsons:security:BeginDenied', function(message)
    requesting = false
    requestSerial = requestSerial + 1
    lib.notify({title = 'Parsons security', description = message or 'Security action denied.', type = 'error'})
end)
RegisterNetEvent('parsons:security:StartAction', function(key, token)
    if busy then return end
    requesting = false
    requestSerial = requestSerial + 1
    local label
    for _, entry in ipairs(actions) do if entry.key == key then label = entry.label break end end
    if not label then return end
    busy = true
    local settings = Config.Security.minigames
    local spec = key == 'gate_hack' and settings.gate or settings.electrical
    local success = lib.skillCheck(spec.difficulty, spec.inputs)
    if success then
        -- Match the server-observed minimum duration without trusting client timing.
        success = lib.progressCircle({
            duration = (math.max(2, tonumber(Config.Security.minimumActionSeconds) or 5) + 1) * 1000,
            label = 'Completing security bypass',
            position = 'bottom',
            canCancel = true,
            disable = {move = true, car = true, combat = true}
        }) == true
    end
    busy = false
    -- Server validates and returns the final result (including failed gate alarm).
    TriggerServerEvent('parsons:security:FinishAction', key, token, success == true)
end)
RegisterNetEvent('parsons:security:ActionResult', function(applied, action)
    local description = 'Security bypass rejected.'
    if applied and action == 'gate_hack' then
        description = 'Gate compromise alarm registered. Physical unlocking awaits the doorlock adapter.'
    elseif applied then
        description = 'Local security communications interruption registered.'
    end
    lib.notify({title = 'Parsons security', description = description, type = applied and 'success' or 'error'})
end)
CreateThread(function()
    Wait(1000)
    for _, entry in ipairs(actions) do
        local point = entry.config()
        if point and point.x and point.y and point.z then
            local key, label = entry.key, entry.label
            exports['qb-target']:AddBoxZone('parsons_' .. key, vector3(point.x, point.y, point.z),
                1.5, 1.5, {name = 'parsons_' .. key, heading = point.w or 0, minZ = point.z - 1, maxZ = point.z + 1},
                {options = {{icon = 'fas fa-bolt', label = label, action = function() start(key) end}},
                distance = 2.5})
        end
    end
end)

-- Configurable security alarm reset stations; server verifies proximity and on-duty job type.
CreateThread(function()
    Wait(1500)
    local alarm = Config.Security and Config.Security.alarm
    if not alarm or type(alarm.resetPoints) ~= 'table' then return end
    for index, point in ipairs(alarm.resetPoints) do
        if point and point.x and point.y and point.z then
            local station = index
            exports['qb-target']:AddBoxZone('parsons_alarm_reset_' .. station,
                vector3(point.x, point.y, point.z), 1.5, 1.5,
                {name = 'parsons_alarm_reset_' .. station, heading = point.w or 0,
                 minZ = point.z - 1, maxZ = point.z + 1},
                {options = {{icon = 'fas fa-bell-slash', label = 'Reset Parsons security alarm',
                    action = function() TriggerServerEvent('parsons:security:ResetAlarm', station) end}},
                 distance = 2.5})
        end
    end
end)

-- Parsons-only fixture controls. Configure actual fixture entities in
-- Config.Security.power.controllableLights; never touch global weather or blackout.
local darkened = {}
local function restoreFixtures()
    for entity in pairs(darkened) do
        if DoesEntityExist(entity) then SetEntityLights(entity, false) end
    end
    darkened = {}
end
local function applyFixtureOutage(active)
    restoreFixtures()
    if not active then return end
    for _, fixture in ipairs((Config.Security.power and Config.Security.power.controllableLights) or {}) do
        if fixture.model and fixture.coords and fixture.coords.x and fixture.coords.y and fixture.coords.z then
            local model = type(fixture.model) == 'number' and fixture.model or joaat(fixture.model)
            local origin = vector3(fixture.coords.x, fixture.coords.y, fixture.coords.z)
            local radius = math.max(0.5, tonumber(fixture.radius) or 2.0)
            local entity = GetClosestObjectOfType(origin.x, origin.y, origin.z, radius, model, false, false, false)
            if entity and entity ~= 0 and DoesEntityExist(entity) then
                SetEntityLights(entity, true)
                darkened[entity] = true
            end
        end
    end
end
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then restoreFixtures() end
end)

local securityState = {powerFailure = false, gateCompromised = false, alarmActive = false}
CreateThread(function()
    while true do
        Wait(5000)
        if securityState.powerFailure then applyFixtureOutage(true) end
    end
end)
RegisterNetEvent('parsons:security:State', function(nextState)
    if type(nextState) ~= 'table' then return end
    local previousPower = securityState.powerFailure
    local previousGate = securityState.gateCompromised
    securityState.powerFailure = nextState.powerFailure == true
    securityState.gateCompromised = nextState.gateCompromised == true
    securityState.alarmActive = nextState.alarmActive == true
    -- Scoped MLO integrations can subscribe without using global weather blackout.
    if previousPower ~= securityState.powerFailure then
        applyFixtureOutage(securityState.powerFailure)
        TriggerEvent('parsons:security:LocalPowerChanged', securityState.powerFailure)
    end
    if previousGate ~= securityState.gateCompromised then
        TriggerEvent('parsons:security:LocalGateChanged', securityState.gateCompromised)
    end
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('parsons:security:RequestState')
end)
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerServerEvent('parsons:security:RequestState')
end)

RegisterNetEvent('parsons:security:AlarmResetResult', function(success, message)
    if success then return end
    lib.notify({title = 'Parsons security', description = message or 'Alarm reset denied.', type = 'error'})
end)

RegisterNetEvent('parsons:security:AlarmState', function(active, reason)
    if active then
        lib.notify({title = 'Parsons security', description = 'Security alarm activated.', type = 'error'})
    else
        lib.notify({title = 'Parsons security', description = 'Security alarm reset.', type = 'success'})
    end
end)
