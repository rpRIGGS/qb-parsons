-- Parsons patient activities. Stations remain inactive until MLO coordinates are configured.
local admitted = false
local activeActivity = nil
local sessionId = 0

RegisterNetEvent('parsons:client:AdmissionState', function(value)
    admitted = value == true
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
    QBCore = QBCore or exports['qb-core']:GetCoreObject({'Functions'})
    QBCore.Functions.Notify((activity.label or 'Activity') .. ' started.', 'primary')
    CreateThread(function()
        Wait(math.max(0, math.floor(duration * 1000)))
        if serial ~= sessionId or not admitted then return end
        TriggerServerEvent('parsons:server:FinishActivity', activity.id)
    end)
end)

function GetParsonsActivity()
    return activeActivity
end

CreateThread(function()
    if not Config.UseTarget then return end
    for id, station in pairs(Config.Locations.jobs or {}) do
        local definition = Config.Jobs[id]
        if definition and station.coords then
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
                            TriggerServerEvent('parsons:server:StartActivity', id)
                        end,
                        canInteract = function() return admitted and not activeActivity end
                    }},
                    distance = 2.5
                })
        end
    end
end)
