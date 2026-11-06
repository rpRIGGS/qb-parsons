local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local DAY_SECONDS = 86400
local METADATA_KEY = 'parsons_hold'
local allowedResources = {['qb-ambulancejob'] = true}

-- Operational commitment state only. PS-MDT remains the source for medical/legal records.
-- QBCore metadata persists remaining seconds. Only connected playtime counts.
local lastTick = {}
local lastEligible = {}
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

-- Polygon verification uses server-observed player coordinates; client zone events are hints only.
local function InsideFacility(src)
    local zone = Config.FacilityZone
    if type(zone) ~= 'table' or type(zone.points) ~= 'table' or #zone.points < 3
        or type(zone.minZ) ~= 'number' or type(zone.maxZ) ~= 'number' then return false end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return false end
    local pos = GetEntityCoords(ped)
    if pos.z < zone.minZ or pos.z > zone.maxZ then return false end
    local inside, j = false, #zone.points
    for i = 1, #zone.points do
        local a, b = zone.points[i], zone.points[j]
        if type(a.x) ~= 'number' or type(a.y) ~= 'number'
            or type(b.x) ~= 'number' or type(b.y) ~= 'number' then return false end
        if (a.y > pos.y) ~= (b.y > pos.y) then
            local crossX = (b.x - a.x) * (pos.y - a.y) / (b.y - a.y) + a.x
            if pos.x < crossX then inside = not inside end
        end
        j = i
    end
    return inside
end

-- Absence is wall-clock time, distinct from playable treatment time.
-- Room release is only flagged here; physical room/door changes await mapped IDs.
local function UpdateAbsence(Player, hold, inside)
    if not hold or hold.checkedIn ~= true then return hold end
    local now = os.time()
    local changed = false
    if inside then
        if hold.absentSince ~= nil then
            hold.lastReturnedAt = now
            hold.absentSince = nil
            changed = true
            TriggerEvent('parsons:server:PatientReturned', Player.PlayerData.source, Player.PlayerData.citizenid)
        end
    elseif hold.absentSince == nil then
        hold.absentSince = now
        hold.lastDepartedAt = now
        changed = true
        TriggerEvent('parsons:server:UnauthorizedDepartureVerified', Player.PlayerData.source, Player.PlayerData.citizenid)
    end
    local grace = math.max(0, tonumber(Config.EscapeRoomGraceHours) or 48) * 3600
    if hold.absentSince and now - hold.absentSince >= grace and hold.roomReservationExpired ~= true then
        hold.roomReservationExpired = true
        changed = true
        -- A room manager must revoke access and free the assigned room atomically.
        TriggerEvent('parsons:server:RoomGraceExpired', Player.PlayerData.citizenid, hold.roomId)
    end
    if changed then
        Player.Functions.SetMetaData(METADATA_KEY, hold)
        Player.Functions.Save()
    end
    return hold
end

local function TickHold(Player)
    local src = Player.PlayerData.source
    local now = os.time()
    local previous = lastTick[src]
    local previouslyEligible = lastEligible[src] == true
    local hold = GetHold(Player)
    local inside = InsideFacility(src)
    hold = UpdateAbsence(Player, hold, inside)
    local eligible = hold ~= nil and hold.checkedIn == true and inside
    lastTick[src] = now
    lastEligible[src] = eligible
    if not hold or hold.remainingSeconds == nil or not previous or not eligible or not previouslyEligible then return hold end
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
        indefinite = hold.remainingSeconds == nil,
        checkedIn = hold.checkedIn == true,
        roomReservationExpired = hold.roomReservationExpired == true,
        absent = hold.absentSince ~= nil
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
-- Custody metadata is separate from qb-prison's jailitems and is never auto-replayed after interruption.
local BELONGINGS_KEY = 'parsons_belongings'

local function GetBelongings(Player)
    local data = Player.PlayerData.metadata and Player.PlayerData.metadata[BELONGINGS_KEY]
    if type(data) ~= 'table' then return nil end
    if data.status ~= 'stored' and data.status ~= 'pending_return' and data.status ~= 'storing' then return nil end
    return data
end

exports('GetBelongingsStatus', function(targetId)
    if not IsTrustedCaller() then return nil, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return nil, 'patient offline' end
    local data = GetBelongings(Player)
    return data and data.status or 'none'
end)

-- Restricted server-only recovery inspection. Staff must compare the custody record
-- against the actual player inventory before acknowledging a completed recovery.
exports('GetBelongingsRecord', function(targetId)
    if not IsTrustedCaller() then return nil, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return nil, 'patient offline' end
    local data = GetBelongings(Player)
    if not data then return nil, 'no belongings record' end
    return {
        status = data.status,
        storedAt = data.storedAt,
        returnIndex = data.returnIndex,
        items = data.items
    }
end)

-- This does not grant or remove any items. Only acknowledge after a trusted
-- staff workflow has manually reconciled the inventory and custody snapshot.
exports('ConfirmBelongingsReconciled', function(targetId, acknowledged)
    if not IsTrustedCaller() then return false, 'untrusted resource' end
    if acknowledged ~= true then return false, 'explicit reconciliation acknowledgement required' end
    local Player = GetPlayer(targetId)
    if not Player then return false, 'patient offline' end
    if GetHold(Player) then return false, 'patient still committed' end
    local data = GetBelongings(Player)
    if not data then return false, 'no belongings record' end
    if data.status ~= 'pending_return' and data.status ~= 'storing' then
        return false, 'record is not pending reconciliation'
    end
    -- A storing record may contain items that were never successfully removed.
    -- Never clear that record without separately resolving the interrupted admission.
    print(('[qb-parsons] Belongings reconciliation acknowledged for %s (previous status: %s)'):format(
        Player.PlayerData.citizenid, data.status))
    Player.Functions.SetMetaData(BELONGINGS_KEY, {})
    Player.Functions.Save()
    return true
end)

-- Match the upstream qb-prison inventory API: Player.ClearInventory() and qb-inventory:AddItem().
-- Persist the custody record BEFORE clearing inventory, so a restart cannot
-- silently discard the snapshot. Pending states require reconciliation.
local function StoreBelongings(Player)
    if GetBelongings(Player) then return false, 'existing belongings require reconciliation' end
    if type(Player.ClearInventory) ~= 'function' or type(Player.Functions.Save) ~= 'function' then
        return false, 'required inventory functions unavailable'
    end
    local snapshot = {}
    for slot, item in pairs(Player.PlayerData.items or {}) do
        if item and item.name and item.amount and item.amount > 0 then
            snapshot[#snapshot + 1] = {
                name = item.name, amount = item.amount, info = item.info,
                slot = item.slot or slot
            }
        end
    end
    table.sort(snapshot, function(a, b) return (tonumber(a.slot) or 0) < (tonumber(b.slot) or 0) end)
    Player.Functions.SetMetaData(BELONGINGS_KEY, {
        status = 'storing', items = snapshot, storedAt = os.time()
    })
    Player.Functions.Save()
    local cleared = Player.ClearInventory()
    Player.Functions.Save()
    if cleared == false then return false, 'inventory clear failed; staff reconciliation required' end
    for _, item in pairs(Player.PlayerData.items or {}) do
        if item and item.name and (tonumber(item.amount) or 0) > 0 then
            print(('[qb-parsons] Inventory not cleared for %s; admission blocked for reconciliation'):format(Player.PlayerData.citizenid))
            return false, 'inventory clearing incomplete; staff reconciliation required'
        end
    end
    local data = GetBelongings(Player)
    if not data or data.status ~= 'storing' then return false, 'custody record changed during storage' end
    data.status = 'stored'
    Player.Functions.SetMetaData(BELONGINGS_KEY, data)
    Player.Functions.Save()
    return true
end

local function ReturnBelongings(Player)
    local data = GetBelongings(Player)
    if not data then return true end
    if GetHold(Player) then return false, 'patient still committed' end
    if data.status ~= 'stored' then return false, 'belongings require reconciliation' end
    if type(Player.Functions.Save) ~= 'function' then
        return false, 'required inventory functions unavailable'
    end
    -- Mark pending before restoration. A partial failure must never cause
    -- the full snapshot to be issued again automatically.
    data.status = 'pending_return'
    Player.Functions.SetMetaData(BELONGINGS_KEY, data)
    Player.Functions.Save()
    for index, item in ipairs(data.items or {}) do
        -- Each grant is tracked individually; after a crash, staff must reconcile
        -- the current item rather than blindly granting the entire snapshot.
        data.returnIndex = index
        Player.Functions.SetMetaData(BELONGINGS_KEY, data)
        Player.Functions.Save()
        local success = exports['qb-inventory']:AddItem(Player.PlayerData.source, item.name, item.amount, false, item.info, 'qb-parsons:return-belongings')
        Player.Functions.Save()
        if not success then return false, 'partial return: staff reconciliation required' end
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
    Player.Functions.Save()
    lastTick[Player.PlayerData.source] = os.time()
    lastEligible[Player.PlayerData.source] = false
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
    if type(hold.remainingSeconds) ~= 'number' then return false, 'invalid hold duration' end
    local served = currentTotal * DAY_SECONDS - hold.remainingSeconds
    hold.remainingSeconds = math.max(0, days * DAY_SECONDS - served)
    hold.phase = phase
    SetHold(Player, hold)
    Player.Functions.Save()
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
    Player.Functions.Save()
    local returned, returnError = ReturnBelongings(Player)
    if not returned then
        print(('[qb-parsons] Belongings return requires attention for %s: %s'):format(Player.PlayerData.citizenid, returnError))
        TriggerClientEvent('QBCore:Notify', Player.PlayerData.source,
            'Your belongings need staff assistance before they can be returned.', 'error', 10000)
    end
    departureCooldown[Player.PlayerData.source] = nil
    lastTick[Player.PlayerData.source] = nil
    lastEligible[Player.PlayerData.source] = nil
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
    local desk = Config.Locations.desk
    local ped = GetPlayerPed(src)
    if not desk or ped == 0 or #(GetEntityCoords(ped) - vec3(desk.x, desk.y, desk.z)) > 5.0 then return end
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
    local hold = GetHold(Player)
    if not hold or hold.checkedIn ~= true or InsideFacility(src) then return end
    local zone = Config.FacilityZone
    if not zone or not zone.points or #zone.points < 3 then return end
    local now = os.time()
    if departureCooldown[src] and now - departureCooldown[src] < 120 then return end
    departureCooldown[src] = now
    print(('[qb-parsons] Active patient %s departed Parsons perimeter'):format(Player.PlayerData.citizenid))
    -- Verification/alert is performed by the periodic authoritative monitor.
    -- Client hints never create or reset an absence timestamp.
end)

-- Count only connected, checked-in time at server-verified Parsons positions.
-- Until a valid polygon is configured, no treatment time is deducted.
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
    lastEligible[source] = nil
    departureCooldown[source] = nil
end)
