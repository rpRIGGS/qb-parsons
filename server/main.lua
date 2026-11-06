local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local DAY_SECONDS = 86400
local METADATA_KEY = 'parsons_hold'
local allowedResources = {['qb-ambulancejob'] = true}

-- Operational commitment state only. PS-MDT remains the source for medical/legal records.
-- Metadata is saved by QBCore; timestamps are Unix seconds and progress while offline.
local function GetPlayer(id)
    return QBCore.Functions.GetPlayer(tonumber(id))
end

local function NormalizeHold(value)
    if type(value) ~= 'table' or value.active ~= true then return nil end
    if type(value.startedAt) ~= 'number' then return nil end
    if value.kind ~= 'medical' and value.kind ~= 'court' then return nil end
    if value.expiresAt ~= nil and (type(value.expiresAt) ~= 'number' or value.expiresAt <= value.startedAt) then return nil end
    if value.kind == 'medical' and value.expiresAt == nil then return nil end
    return value
end

local function GetHold(Player)
    return NormalizeHold(Player.PlayerData.metadata and Player.PlayerData.metadata[METADATA_KEY])
end

local function PublicState(hold)
    if not hold then return {active = false} end
    local expired = hold.expiresAt ~= nil and os.time() >= hold.expiresAt
    return {
        active = true,
        kind = hold.kind,
        phase = hold.phase,
        startedAt = hold.startedAt,
        expiresAt = hold.expiresAt,
        expired = expired,
        indefinite = hold.expiresAt == nil
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
        expiresAt = days and (started + days * DAY_SECONDS) or nil}
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
    SetHold(Player, hold)
    TriggerClientEvent('parsons:client:Admit', Player.PlayerData.source, PublicState(hold))
    return true
end)

-- Extend the existing commitment using the ORIGINAL admission time: 3/7/28 days TOTAL.
-- Authority and clinical/legal basis must be validated by the calling server resource.
exports('ExtendMedicalHold', function(targetId, phase)
    if not IsTrustedCaller() then return false, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return false, 'patient offline' end
    local hold = GetHold(Player)
    if not hold or hold.kind ~= 'medical' then return false, 'no medical hold' end
    local durations = {evaluation_extension = 7, treatment_extension = 28}
    local days = durations[phase]
    if not days or hold.expiresAt >= hold.startedAt + days * DAY_SECONDS then
        return false, 'invalid extension'
    end
    hold.expiresAt = hold.startedAt + days * DAY_SECONDS
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
    local hold = GetHold(Player)
    if not hold then return false, 'no active hold' end
    if hold.kind == 'court' and authority ~= 'judicial' then return false, 'judicial clearance required' end
    if hold.kind == 'medical' and authority ~= 'medical' and authority ~= 'judicial' then
        return false, 'medical clearance required'
    end
    SetHold(Player, nil)
    TriggerClientEvent('parsons:client:Discharge', Player.PlayerData.source)
    return true
end)

QBCore.Functions.CreateCallback('parsons:server:GetAdmission', function(src, cb)
    local Player = GetPlayer(src)
    cb(PublicState(Player and GetHold(Player)))
end)

RegisterNetEvent('parsons:server:RequestDischargeStatus', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player then return end
    local hold = GetHold(Player)
    if not hold then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('error.no_active_hold'), 'error')
    elseif hold.expiresAt and os.time() >= hold.expiresAt then
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.discharge_pending'), 'primary')
    else
        TriggerClientEvent('QBCore:Notify', src, Lang:t('info.hold_active'), 'primary')
    end
end)

RegisterNetEvent('parsons:server:ReportUnauthorizedDeparture', function()
    local src = source
    local Player = GetPlayer(src)
    if not Player or not GetHold(Player) then return end
    -- No client-requested hold cancellation. Task 4 will add server-side
    -- perimeter verification, throttling, and agency dispatch integration.
    print(('[qb-parsons] Patient %s reported outside Parsons perimeter (unverified)'):format(Player.PlayerData.citizenid))
end)
