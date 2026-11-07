-- Stage 7 configurable sabotage/gate interactions. No legacy prison coordinates.
local actions = {
    {key = 'electrical_inside', label = 'Tamper with electrical panel', config = function() return Config.Security.electrical.inside end},
    {key = 'electrical_outside', label = 'Sabotage electrical service', config = function() return Config.Security.electrical.outside end},
    {key = 'gate_hack', label = 'Bypass gate electronics', config = function() return Config.Security.gate.hack end}
}
local busy = false
local requesting = false
local function start(key)
    if busy or requesting then return end
    requesting = true
    TriggerServerEvent('parsons:security:BeginAction', key)
    SetTimeout(3000, function() requesting = false end)
end
RegisterNetEvent('parsons:security:StartAction', function(key, token)
    if busy then return end
    requesting = false
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
    if GetResourceState('qb-target') == 'started' then
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
    else
        while true do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local nearest, distance
            for _, entry in ipairs(actions) do
                local point = entry.config()
                if point and point.x and point.y and point.z then
                    local dist = #(coords - vector3(point.x, point.y, point.z))
                    if dist < 2.0 and (not distance or dist < distance) then nearest, distance = entry, dist end
                end
            end
            if nearest and not busy then
                exports['qb-core']:DrawText('[E] ' .. nearest.label, 'left')
                if IsControlJustReleased(0, 38) then start(nearest.key) end
            else
                exports['qb-core']:HideText()
            end
            Wait(nearest and 0 or 750)
        end
    end
end)

-- Configurable security alarm reset stations; server verifies proximity and on-duty job type.
CreateThread(function()
    Wait(1500)
    local alarm = Config.Security and Config.Security.alarm
    if not alarm or type(alarm.resetPoints) ~= 'table' then return end
    if GetResourceState('qb-target') ~= 'started' then return end
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
local securityState = {powerFailure = false, gateCompromised = false, alarmActive = false}
RegisterNetEvent('parsons:security:State', function(nextState)
    if type(nextState) ~= 'table' then return end
    securityState.powerFailure = nextState.powerFailure == true
    securityState.gateCompromised = nextState.gateCompromised == true
    securityState.alarmActive = nextState.alarmActive == true
end)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('parsons:security:RequestState')
end)
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerServerEvent('parsons:security:RequestState')
end)

RegisterNetEvent('parsons:security:AlarmState', function(active, reason)
    if active then
        lib.notify({title = 'Parsons security', description = 'Security alarm activated.', type = 'error'})
    else
        lib.notify({title = 'Parsons security', description = 'Security alarm reset.', type = 'success'})
    end
end)
