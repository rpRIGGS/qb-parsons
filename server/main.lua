local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local DAY_SECONDS = 86400
local METADATA_KEY = 'parsons_hold'
local allowedResources = {['qb-ambulancejob'] = true}

-- Operational commitment state only. PS-MDT remains the source for medical/legal records.
-- QBCore metadata persists remaining seconds. Only connected playtime counts.
local lastTick = {}
local departureCooldown = {}
local function GetPlayer(id)
    return QBCore.Functions.GetPlayer(tonumber(id))
end

local function NormalizeHold(value)
    if type(value) ~= 'table' or value.active ~= true then return nil end
    if type(value.startedAt) ~= 'number' then return nil end
    if value.kind ~= 'medical' and value.kind ~= 'court' then return nil end
    if value.remainingSeconds ~= nil and (type(value.remainingSeconds) ~= 'number' or value.remainingSeconds < 0) then return nil end
    if value.kind == 'medical' and value.remainingSeconds == nil then return nil end
    return value
end

local function GetHold(Player)
    return NormalizeHold(Player.PlayerData.metadata and Player.PlayerData.metadata[METADATA_KEY])
end

local function TickHold(Player)
    local src = Player.PlayerData.source
    local now = os.time()
    local previous = lastTick[src]
    lastTick[src] = now
    local hold = GetHold(Player)
    if not hold or hold.remainingSeconds == nil or not previous then return hold end
    -- Cap long scheduler gaps to avoid counting downtime or lag as treatment time.
    local elapsed = math.max(0, math.min(now - previous, 35))
    if elapsed == 0 then return hold end
    hold.remainingSeconds = math.max(0, hold.remainingSeconds - elapsed)
    Player.Functions.SetMetaData(METADATA_KEY, hold)
    return hold
end

local function PublicState(hold)
    if not hold then return {active = false} end
    local expired = hold.remainingSeconds ~= nil and hold.remainingSeconds <= 0
    return {
        active = true,
        kind = hold.kind,
        phase = hold.phase,
        startedAt = hold.startedAt,
        remainingSeconds = hold.remainingSeconds,
        expired = expired,
        indefinite = hold.remainingSeconds == nil
    }
end

local function SetHold(Player, hold)
    Player.Functions.SetMetaData(METADATA_KEY, hold or {})
end

local function IsTrustedCaller()
    local resource = GetInvokingResource()
    return resource ~= nil and allowedResources[resource] == true
end

local function BuildHold(kind, phase, days)
    local started = os.time()
    if kind == 'medical' then
        local permitted = {evaluation = 3, evaluation_extension = 7, treatment_extension = 28}
        if permitted[phase] ~= days then return nil, 'invalid medical hold duration' end
    elseif kind == 'court' then
        if days ~= nil and (type(days) ~= 'number' or days ~= math.floor(days) or days < 1 or days > 36500) then
            return nil, 'invalid court duration'
        end
    else
        return nil, 'invalid hold kind'
    end
    return {active = true, kind = kind, phase = phase, startedAt = started,
        remainingSeconds = days and (days * DAY_SECONDS) or nil}
end

-- Parsons belongings are isolated from qb-prison's jailitems metadata.
-- This ledger is not an inventory adapter: never remove or grant items here.
local BELONGINGS_KEY = 'parsons_belongings'

local function GetBelongings(Player)
    local data = Player.PlayerData.metadata and Player.PlayerData.metadata[BELONGINGS_KEY]
    if type(data) ~= 'table' then return nil end
    if data.status ~= 'stored' and data.status ~= 'pending_return' then return nil end
    return data
end

exports('GetBelongingsStatus', function(targetId)
    if not IsTrustedCaller() then return nil, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return nil, 'patient offline' end
    local data = GetBelongings(Player)
    return data and data.status or 'none'
end)

-- Use standard QBCore player inventory functions supported by qb-inventory.
-- Persist the custody record BEFORE clearing inventory, so a restart cannot
-- silently discard the snapshot. Pending states require reconciliation.
local function StoreBelongings(Player)
    if GetBelongings(Player) then return false, 'existing belongings require reconciliation' end
    local snapshot = {}
    for slot, item in pairs(Player.PlayerData.items or {}) do
        if item and item.name and item.amount and item.amount > 0 then
            snapshot[#snapshot + 1] = {
                name = item.name, amount = item.amount, info = item.info,
                slot = item.slot or slot
            }
        end
    end
    Player.Functions.SetMetaData(BELONGINGS_KEY, {
        status = 'stored', items = snapshot, storedAt = os.time()
    })
    Player.Functions.ClearInventory()
    Player.Functions.Save()
    return true
end

local function ReturnBelongings(Player)
    local data = GetBelongings(Player)
    if not data then return true end
    if GetHold(Player) then return false, 'patient still committed' end
    if data.status == 'pending_return' then return false, 'return requires reconciliation' end
    -- Mark pending before restoration. A partial failure must never cause
    -- the full snapshot to be issued again automatically.
    data.status = 'pending_return'
    Player.Functions.SetMetaData(BELONGINGS_KEY, data)
    Player.Functions.Save()
    for _, item in ipairs(data.items or {}) do
        local success = Player.Functions.AddItem(item.name, item.amount, item.slot, item.info)
        if not success then
            Player.Functions.Save()
            return false, 'partial return: staff reconciliation required'
        end
    end
    Player.Functions.SetMetaData(BELONGINGS_KEY, {})
    Player.Functions.Save()
    return true
end

-- Invoked by a trusted server resource only. Never expose admission through a client event.
-- Integration must validate credential, legal authority and patient selection BEFORE calling.
exports('AdmitPatient', function(targetId, kind, phase, days)
    if not IsTrustedCaller() then return false, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return false, 'patient offline' end
    if GetHold(Player) then return false, 'patient already admitted' end
    local hold, err = BuildHold(kind, phase, days)
    if not hold then return false, err end
    local stored, storageError = StoreBelongings(Player)
    if not stored then return false, storageError or 'belongings storage failed' end
    SetHold(Player, hold)
    lastTick[Player.PlayerData.source] = os.time()
    TriggerClientEvent('parsons:client:Admit', Player.PlayerData.source, PublicState(hold))
    return true
end)

-- Extend commitment to 7/28 TOTAL playable days, preserving already-served online time.
-- Authority and clinical/legal basis must be validated by the calling server resource.
exports('ExtendMedicalHold', function(targetId, phase)
    if not IsTrustedCaller() then return false, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return false, 'patient offline' end
    local hold = TickHold(Player)
    if not hold or hold.kind ~= 'medical' then return false, 'no medical hold' end
    local durations = {evaluation_extension = 7, treatment_extension = 28}
    local days = durations[phase]
    local currentTotal = ({evaluation = 3, evaluation_extension = 7, treatment_extension = 28})[hold.phase]
    if not days or not currentTotal or days <= currentTotal then return false, 'invalid extension' end
    local served = currentTotal * DAY_SECONDS - hold.remainingSeconds
    hold.remainingSeconds = math.max(0, days * DAY_SECONDS - served)
    hold.phase = phase
    SetHold(Player, hold)
    return true
end)

-- An authorized external server integration may discharge a patient after verifying
-- legal authority. Court holds MUST be judicially cleared by that integration.
exports('DischargePatient', function(targetId, authority)
    if not IsTrustedCaller() then return false, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return false, 'patient offline' end
    local hold = TickHold(Player)
    if not hold then return false, 'no active hold' end
    if hold.kind == 'court' and authority ~= 'judicial' then return false, 'judicial clearance required' end
    if hold.kind == 'medical' and authority ~= 'medical' and authority ~= 'judicial' then
        return false, 'medical clearance required'
    end
    SetHold(Player, nil)
    local returned, returnError = ReturnBelongings(Player)
    if not returned then
        print(('[qb-parsons] Belongings return requires attention for %s: %s'):format(Player.PlayerData.citizenid, returnError))
    end
    departureCooldown[Player.PlayerData.source] = nil
    lastTick[Player.PlayerData.source] = nil
    TriggerClientEvent('parsons:client:Discharge', Player.PlayerData.source)
    return true, returned and nil or ('discharged; belongings pending: ' .. tostring(returnError))
end)

QBCore.Functions.CreateCallback('parsons:server:GetAdmission', function(src, cb)
    local Player = GetPlayer(src)
    cb(PublicState(Player and TickHold(Player)))
end)

RegisterNetEvent('parsons:server:RequestDischargeStatus', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    local hold = TickHold(Player)
    if not hold then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_active_hold'), 'error')
    elseif hold.remainingSeconds == nil then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.indefinite_hold'), 'primary')
    elseif hold.remainingSeconds <= 0 then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.discharge_pending'), 'primary')
    else
        local hours = math.floor(hold.remainingSeconds / 3600)
        local minutes = math.ceil((hold.remainingSeconds % 3600) / 60)
        TriggerClientEvent('QBCore:Notify', src, ('Commitment remaining: %d hours, %d minutes'):format(hours, minutes), 'primary')
    end
end)

RegisterNetEvent('parsons:server:ReportUnauthorizedDeparture', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player or not GetHold(Player) then return end
    local center = Config.Locations.middle
    local radius = Config.EscapeDetectionRadius or 200.0
    if not center or radius <= 0 then return end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local coords = GetEntityCoords(ped)
    if #(coords.xy - vec2(center.x, center.y)) <= radius then return end
    local now = os.time()
    if departureCooldown[src] and now - departureCooldown[src] < 120 then return end
    departureCooldown[src] = now
    print(('[qb-parsons] Active patient %s departed Parsons perimeter'):format(Player.PlayerData.citizenid))
    -- A future dispatch adapter can subscribe to this server-side event.
    TriggerEvent('parsons:server:UnauthorizedDepartureVerified', src, Player.PlayerData.citizenid)
end)

-- Count only connected time. Persist progress in QBCore metadata every 30 seconds.
-- The first tick after reconnect initializes the clock; offline gaps never subtract.
CreateThread(function()
    while true do
        Wait(30000)
        for _, src in ipairs(QBCore.Functions.GetPlayers()) do
            local Player = GetPlayer(src)
            if Player then TickHold(Player) end
        end
    end
end)

AddEventHandler('playerDropped', function()
    lastTick[source] = nil
    departureCooldown[source] = nil
end)
