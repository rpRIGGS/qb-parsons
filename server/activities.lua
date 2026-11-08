-- Parsons patient activities: server-authoritative participation, no sentence reduction.
local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local active = {}
local cooldowns = {}
local nextSessionId = 0
local function sendStatus(src, session)
    if not session then
        TriggerClientEvent('parsons:client:ActivityStatus', src, false)
        return
    end
    local definition = Config.Activities[session.id]
    TriggerClientEvent('parsons:client:ActivityStatus', src, {
        id = session.id,
        token = session.token,
        label = definition and definition.label or session.id,
        durationSeconds = math.max(0, session.finishAt - os.time())
    })
end
local function cancel(src)
    if not active[src] then return end
    local session = active[src]
    active[src] = nil
    sendStatus(src, nil)
    TriggerEvent('parsons:activities:Cancelled', {
        citizenid = session.citizenid, activity = session.id, cancelledAt = os.time()
    })
end
local function patient(src)
    local p = QBCore.Functions.GetPlayer(src)
    local h = p and p.PlayerData.metadata and p.PlayerData.metadata.parsons_hold
    if not p or type(h) ~= 'table' or h.active ~= true or h.checkedIn ~= true
        or h.kind == 'outpatient' or h.absentSince ~= nil
        or h.reentryInventoryPending == true or h.roomReservationExpired == true
        or (h.transport and h.transport.active == true) then return nil end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or GetEntityHealth(ped) <= 0 then return nil end
    return p
end
local function nearStation(src, id)
    local station = Config.Locations and Config.Locations.activities and Config.Locations.activities[id]
    if type(station) ~= 'table' or not station.coords then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local c = station.coords
    if type(c.x) ~= 'number' or type(c.y) ~= 'number' or type(c.z) ~= 'number' then return false end
    local radius = math.max(1.0, math.min(15.0, tonumber(station.radius) or 4.0))
    return #(GetEntityCoords(ped) - vector3(c.x, c.y, c.z)) <= radius
end
RegisterNetEvent('parsons:server:StartActivity', function(id)
    local src = source
    local def = type(id) == 'string' and Config.Activities[id]
    if not def or not patient(src) or not nearStation(src, id) then return end
    if active[src] then
        TriggerClientEvent('QBCore:Notify', src, 'Finish or cancel your current activity first.', 'error')
        return
    end
    local now = os.time()
    if (cooldowns[src] and cooldowns[src][id] or 0) > now then
        TriggerClientEvent('QBCore:Notify', src, 'This activity is on cooldown.', 'error')
        return
    end
    local duration = math.max(10, math.min(1800, math.floor(tonumber(def.durationSeconds) or 60)))
    nextSessionId = nextSessionId + 1
    active[src] = {
        id = id, token = nextSessionId, finishAt = now + duration,
        durationSeconds = duration, startedAt = now,
        citizenid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
    }
    sendStatus(src, active[src])
end)
local function complete(src, session)
    if active[src] ~= session then return end
    local Player = patient(src)
    if not Player or Player.PlayerData.citizenid ~= session.citizenid
        or not nearStation(src, session.id) then
        cancel(src)
        return
    end
    local def = Config.Activities[session.id]
    if not def then cancel(src) return end
    active[src] = nil
    local hold = Player.PlayerData.metadata.parsons_hold
    hold.activities = type(hold.activities) == 'table' and hold.activities or {}
    local history = hold.activities
    history[#history + 1] = {
        id = session.id, completedAt = os.time(),
        durationSeconds = session.durationSeconds
    }
    while #history > 100 do table.remove(history, 1) end
    Player.Functions.SetMetaData('parsons_hold', hold)
    local relief = math.min(20, math.max(0, math.floor(tonumber(def.stressRelief) or 0)))
    if relief > 0 then
        local metadata = Player.PlayerData.metadata or {}
        local stress = math.max(0, tonumber(metadata.stress) or 0)
        Player.Functions.SetMetaData('stress', math.max(0, stress - relief))
    end
    Player.Functions.Save()
    TriggerEvent('parsons:activities:Completed', {
        citizenid = Player.PlayerData.citizenid,
        activity = session.id,
        durationSeconds = session.durationSeconds,
        completedAt = history[#history].completedAt
    })
    cooldowns[src] = cooldowns[src] or {}
    cooldowns[src][session.id] = os.time() + math.max(0, math.min(86400,
        math.floor(tonumber(def.cooldownSeconds) or 0)))
    sendStatus(src, nil)
    TriggerClientEvent('QBCore:Notify', src, 'Activity completed.', 'success')
end

RegisterNetEvent('parsons:server:FinishActivity', function(id, token)
    local src = source
    local session = active[src]
    if not session or session.id ~= id or session.token ~= token then return end
    if os.time() < session.finishAt then
        sendStatus(src, session)
        return
    end
    complete(src, session)
end)
RegisterNetEvent('parsons:server:RequestActivityStatus', function()
    local src = source
    local session = active[src]
    if session and (not patient(src)
        or patient(src).PlayerData.citizenid ~= session.citizenid
        or not nearStation(src, session.id)) then
        cancel(src)
        return
    end
    sendStatus(src, session)
end)
RegisterNetEvent('parsons:server:CancelActivity', function()
    local src = source
    cancel(src)
end)
AddEventHandler('playerDropped', function()
    active[source] = nil
    cooldowns[source] = nil
end)

-- Server checks are independent of the client's activity timer and cancellation requests.
CreateThread(function()
    while true do
        Wait(3000)
        for src, session in pairs(active) do
            if not patient(src) or patient(src).PlayerData.citizenid ~= session.citizenid
                or not nearStation(src, session.id) then
                cancel(src)
            elseif os.time() >= session.finishAt then
                complete(src, session)
            end
        end
    end
end)

-- Restricted read-only inspection for future authorized medical staff interface.
-- The invoking resource must be an explicitly trusted server integration.
exports('GetPatientActivityHistory', function(targetId)
    local caller = GetInvokingResource()
    if caller ~= 'qb-ambulancejob' then return nil, 'untrusted resource' end
    local Player = QBCore.Functions.GetPlayer(tonumber(targetId))
    if not Player then return nil, 'patient offline' end
    local hold = Player.PlayerData.metadata and Player.PlayerData.metadata.parsons_hold
    if type(hold) ~= 'table' or hold.active ~= true then return nil, 'no active admission' end
    local history = type(hold.activities) == 'table' and hold.activities or {}
    local copy = {}
    for i, entry in ipairs(history) do
        if type(entry) == 'table' then
            copy[i] = {id = entry.id, completedAt = entry.completedAt, durationSeconds = entry.durationSeconds}
        end
    end
    return copy
end)
