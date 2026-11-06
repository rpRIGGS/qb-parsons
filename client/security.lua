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
    busy = false
    if not success then
        lib.notify({title = 'Security bypass', description = 'Bypass unsuccessful.', type = 'error'})
    end
    TriggerServerEvent('parsons:security:FinishAction', key, token, success == true)
end)
RegisterNetEvent('parsons:security:ActionResult', function(applied)
    lib.notify({title = 'Security bypass', description = applied and 'Security system bypassed.' or 'Security bypass rejected.', type = applied and 'success' or 'error'})
end)
CreateThread(function()
    Wait(1000)
    if Config.UseTarget and GetResourceState('qb-target') == 'started' then
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
