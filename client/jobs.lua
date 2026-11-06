-- Parsons patient activities. Stations remain inactive until MLO coordinates are configured.
local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local admitted = false
local activeActivity = nil
local sessionId = 0

RegisterNetEvent('parsons:client:AdmissionState', function(value)
    admitted = value == true
    if admitted then TriggerServerEvent('parsons:server:RequestActivityStatus') end
    if not admitted and activeActivity then
        sessionId = sessionId + 1
        activeActivity = nil
        TriggerServerEvent('parsons:server:CancelActivity')
    end
end)

RegisterNetEvent('parsons:client:ActivityStatus', function(activity)
    sessionId = sessionId + 1
    local serial = sessionId
    activeActivity = activity or nil
    if not activeActivity then return end
    local duration = tonumber(activity.durationSeconds) or 0
    local startedAt = GetGameTimer()
    QBCore.Functions.Notify((activity.label or 'Activity') .. ' started. Press Backspace to cancel.', 'primary')
    CreateThread(function()
        while serial == sessionId and admitted do
            local elapsed = (GetGameTimer() - startedAt) / 1000
            if elapsed >= duration then break end
            local remaining = math.max(0, math.ceil(duration - elapsed))
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(('%s: %ds remaining | BACKSPACE to cancel'):format(activity.label or 'Activity', remaining))
            EndTextCommandDisplayHelp(0, false, false, -1)
            local station = Config.Locations.jobs and Config.Locations.jobs[activity.id]
            if station and station.coords and #(GetEntityCoords(PlayerPedId()) - vector3(station.coords.x, station.coords.y, station.coords.z)) > (station.radius or 4.0) then
                TriggerServerEvent('parsons:server:CancelActivity')
                QBCore.Functions.Notify('Activity cancelled: you left the station.', 'error')
                return
            end
            if IsControlJustReleased(0, 177) then
                TriggerServerEvent('parsons:server:CancelActivity')
                return
            end
            Wait(0)
        end
        if serial ~= sessionId or not admitted then return end
        TriggerServerEvent('parsons:server:FinishActivity', activity.id, activity.token)
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    TriggerServerEvent('parsons:server:RequestActivityStatus')
end)

function GetParsonsActivity()
    return activeActivity
end

CreateThread(function()
    if not Config.UseTarget then return end
    for id, station in pairs(Config.Locations.jobs or {}) do
        local definition = Config.Jobs[id]
        if definition and station.coords then
            local activityId = id
            local c = station.coords
            exports['qb-target']:AddBoxZone('parsons_activity_' .. id, vector3(c.x, c.y, c.z),
                station.length or 2.0, station.width or 2.0, {
                    name = 'parsons_activity_' .. id,
                    heading = station.heading or 0,
                    minZ = station.minZ or (c.z - 1.0),
                    maxZ = station.maxZ or (c.z + 1.5),
                    debugPoly = false
                }, {
                    options = {{
                        icon = 'fas fa-clipboard-check',
                        label = definition.label,
                        action = function()
                            TriggerServerEvent('parsons:server:StartActivity', activityId)
                        end,
                        canInteract = function() return admitted and not activeActivity end
                    }},
                    distance = 2.5
                })
        end
    end
end)

-- Non-target fallback for servers that have not enabled the UseTarget convar.
CreateThread(function()
    if Config.UseTarget then return end
    while true do
        local delay = 1000
        if admitted and not activeActivity then
            local playerCoords = GetEntityCoords(PlayerPedId())
            for id, station in pairs(Config.Locations.jobs or {}) do
                if Config.Jobs[id] and station.coords then
                    local c = station.coords
                    local distance = #(playerCoords - vector3(c.x, c.y, c.z))
                    if distance < 2.5 then
                        delay = 0
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(('Press ~INPUT_CONTEXT~ for %s'):format(Config.Jobs[id].label))
                        EndTextCommandDisplayHelp(0, false, false, -1)
                        if IsControlJustReleased(0, 38) then
                            TriggerServerEvent('parsons:server:StartActivity', id)
                        end
                        break
                    end
                end
            end
        end
        Wait(delay)
    end
end)
