-- Parsons patient activities: server-authoritative participation, no sentence reduction.
local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local active = {}
local cooldowns = {}
local function patient(src)
    local p = QBCore.Functions.GetPlayer(src)
    local h = p and p.PlayerData.metadata and p.PlayerData.metadata.parsons_hold
    if not p or type(h) ~= 'table' or h.active ~= true then return nil end
    return p
end
local function nearStation(src, id)
    local station = Config.Locations.jobs and Config.Locations.jobs[id]
    if not station or not station.coords then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local c = station.coords
    return #(GetEntityCoords(ped) - vec3(c.x, c.y, c.z)) <= (station.radius or 4.0)
end
RegisterNetEvent('parsons:server:StartActivity', function(id)
    local src = source
    local def = type(id) == 'string' and Config.Jobs[id]
    if not def or not patient(src) or not nearStation(src, id) then return end
    if active[src] then return end
    local now = os.time()
    if (cooldowns[src] and cooldowns[src][id] or 0) > now then return end
    local duration = math.max(10, math.floor(tonumber(def.durationSeconds) or 60))
    active[src] = {id = id, finishAt = now + duration}
    TriggerClientEvent('parsons:client:ActivityStatus', src, {id = id, label = def.label, durationSeconds = duration})
end)
RegisterNetEvent('parsons:server:FinishActivity', function(id)
    local src = source
    local session = active[src]
    if not session or session.id ~= id then return end
    if not patient(src) or not nearStation(src, id) then
        active[src] = nil
        TriggerClientEvent('parsons:client:ActivityStatus', src, false)
        return
    end
    if os.time() < session.finishAt then return end
    active[src] = nil
    cooldowns[src] = cooldowns[src] or {}
    cooldowns[src][id] = os.time() + math.max(0, math.floor(tonumber(Config.Jobs[id].cooldownSeconds) or 0))
    TriggerClientEvent('parsons:client:ActivityStatus', src, false)
    TriggerClientEvent('QBCore:Notify', src, 'Activity completed.', 'success')
end)
RegisterNetEvent('parsons:server:CancelActivity', function()
    local src = source
    active[src] = nil
    TriggerClientEvent('parsons:client:ActivityStatus', src, false)
end)
AddEventHandler('playerDropped', function()
    active[source] = nil
    cooldowns[source] = nil
end)
