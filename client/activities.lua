-- Parsons patient activities. Stations remain inactive until MLO coordinates are configured.
local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local admitted = false
local activeActivity = nil
local sessionId = 0
local activityScenario = nil
local function StopActivityPresentation()
    if activityScenario then
        ClearPedTasks(PlayerPedId())
        activityScenario = nil
    end
end
local function StartActivityPresentation(id)
    local definition = Config.Activities[id]
    local scenario = definition and definition.scenario
    if type(scenario) ~= 'string' or scenario == '' then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsPedRagdoll(ped) then return end
    TaskStartScenarioInPlace(ped, scenario, 0, true)
    activityScenario = scenario
end

RegisterNetEvent('parsons:client:AdmissionState', function(value)
    admitted = value == true
    if admitted then TriggerServerEvent('parsons:server:RequestActivityStatus') end
    if not admitted and activeActivity then
        sessionId = sessionId + 1
        activeActivity = nil
        StopActivityPresentation()
        TriggerServerEvent('parsons:server:CancelActivity')
    end
end)

RegisterNetEvent('parsons:client:ActivityStatus', function(activity)
    sessionId = sessionId + 1
    local serial = sessionId
    local previous = activeActivity
    if previous and activity and previous.token == activity.token and previous.id == activity.id then
        -- Server status refresh must not restart the timer or animation.
        return
    end
    StopActivityPresentation()
    activeActivity = activity or nil
    if not activeActivity then return end
    StartActivityPresentation(activity.id)
    local duration = tonumber(activity.durationSeconds) or 0
    local startedAt = GetGameTimer()
    local scenarioGraceUntil = startedAt + 2000
    QBCore.Functions.Notify((activity.label or 'Activity') .. ' started. Press Backspace to cancel.', 'primary')
    CreateThread(function()
        while serial == sessionId and admitted do
            local elapsed = (GetGameTimer() - startedAt) / 1000
            if elapsed >= duration then break end
            local remaining = math.max(0, math.ceil(duration - elapsed))
            BeginTextCommandDisplayHelp('STRING')
            AddTextComponentSubstringPlayerName(('%s: %ds remaining | BACKSPACE to cancel'):format(activity.label or 'Activity', remaining))
            EndTextCommandDisplayHelp(0, false, false, -1)
            local station = Config.Locations.activities and Config.Locations.activities[activity.id]
            if station and station.coords and #(GetEntityCoords(PlayerPedId()) - vector3(station.coords.x, station.coords.y, station.coords.z)) > (station.radius or 4.0) then
                TriggerServerEvent('parsons:server:CancelActivity')
                QBCore.Functions.Notify('Activity cancelled: you left the station.', 'error')
                return
            end
            if activityScenario and GetGameTimer() > scenarioGraceUntil and not IsPedUsingAnyScenario(PlayerPedId()) then
                TriggerServerEvent('parsons:server:CancelActivity')
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
AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        TriggerServerEvent('parsons:server:RequestActivityStatus')
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    admitted = false
    sessionId = sessionId + 1
    activeActivity = nil
    StopActivityPresentation()
end)

function GetParsonsActivity()
    return activeActivity
end

CreateThread(function()
    for id, station in pairs(Config.Locations.activities or {}) do
        local definition = Config.Activities[id]
        if definition and type(station) == 'table' and station.coords
            and type(station.coords.x) == 'number' and type(station.coords.y) == 'number'
            and type(station.coords.z) == 'number' then
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

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then StopActivityPresentation() end
end)
