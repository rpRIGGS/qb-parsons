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
    local definition = Config.Jobs[session.id]
    TriggerClientEvent('parsons:client:ActivityStatus', src, {
        id = session.id,
        token = session.token,
        label = definition and definition.label or session.id,
        durationSeconds = math.max(0, session.finishAt - os.time())
    })
end
local function cancel(src)
    if not active[src] then return end
    active[src] = nil
    sendStatus(src, nil)
end
local function patient(src)
    local p = QBCore.Functions.GetPlayer(src)
    local h = p and p.PlayerData.metadata and p.PlayerData.metadata.parsons_hold
    if not p or type(h) ~= 'table' or h.active ~= true or h.checkedIn ~= true then return nil end
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
    nextSessionId = nextSessionId + 1
    active[src] = {id = id, token = nextSessionId, finishAt = now + duration}
    sendStatus(src, active[src])
end)
RegisterNetEvent('parsons:server:FinishActivity', function(id, token)
    local src = source
    local session = active[src]
    if not session or session.id ~= id or session.token ~= token then return end
    if not patient(src) or not nearStation(src, id) then
        cancel(src)
        return
    end
    if os.time() < session.finishAt then
        -- Client and server clocks can disagree at the finish boundary.
        -- Resync instead of leaving the activity stuck indefinitely.
        sendStatus(src, session)
        return
    end
    active[src] = nil
    -- Participation history belongs to this admission, not a global player counter.
    local Player = patient(src)
    if Player then
        local hold = Player.PlayerData.metadata.parsons_hold
        hold.activities = type(hold.activities) == 'table' and hold.activities or {}
        local history = hold.activities
        history[#history + 1] = {id = id, completedAt = os.time(), durationSeconds = math.max(10, math.floor(tonumber(Config.Jobs[id].durationSeconds) or 60))}
        -- Bound metadata growth for long court commitments.
        while #history > 100 do table.remove(history, 1) end
        Player.Functions.SetMetaData('parsons_hold', hold)
        Player.Functions.Save()
    end
    cooldowns[src] = cooldowns[src] or {}
    cooldowns[src][id] = os.time() + math.max(0, math.floor(tonumber(Config.Jobs[id].cooldownSeconds) or 0))
    sendStatus(src, nil)
    TriggerClientEvent('QBCore:Notify', src, 'Activity completed.', 'success')
end)
RegisterNetEvent('parsons:server:RequestActivityStatus', function()
    local src = source
    local session = active[src]
    if session and (not patient(src) or not nearStation(src, session.id)) then
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
            if not patient(src) or not nearStation(src, session.id) then
                cancel(src)
            end
        end
    end
end)
