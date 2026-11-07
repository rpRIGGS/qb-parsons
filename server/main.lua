local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local DAY_SECONDS = 86400
local METADATA_KEY = 'parsons_hold'
local allowedResources = {['qb-ambulancejob'] = true}

-- Operational commitment state only. PS-MDT remains the source for medical/legal records.
-- QBCore metadata persists remaining seconds. Only connected playtime counts.
local lastTick = {}
local lastEligible = {}
local departureCooldown = {}
local lastInside = {}
-- Offline room expiry is stored separately from player metadata, then reconciled on login.
local function RoomKey(roomId) return 'parsons_room_' .. roomId end
local function AbsenceKey(roomId) return 'parsons_absence_' .. roomId end
local function ClearRoomReservation(roomId, citizenid)
    if not roomId or GetResourceKvpString(RoomKey(roomId)) ~= citizenid then return false end
    DeleteResourceKvp(RoomKey(roomId))
    DeleteResourceKvp(AbsenceKey(roomId))
    return true
end
local function MarkRoomAbsence(roomId, citizenid, since)
    if roomId and GetResourceKvpString(RoomKey(roomId)) == citizenid then
        SetResourceKvpInt(AbsenceKey(roomId), since)
    end
end

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
    -- Never recreate an expired reservation's absence timestamp after an offline sweep.
    if hold.roomId and hold.absentSince and not hold.roomReservationExpired
        and GetResourceKvpString(RoomKey(hold.roomId)) == Player.PlayerData.citizenid
        and not (hold.transport and hold.transport.active) then
        MarkRoomAbsence(hold.roomId, Player.PlayerData.citizenid, hold.absentSince)
    end
    local reservationLost = hold.roomId and GetResourceKvpString(RoomKey(hold.roomId)) ~= Player.PlayerData.citizenid
    local changed = false
    if reservationLost and not hold.roomReservationExpired then
        hold.roomReservationExpired = true
        changed = true
    end
    -- Expire wall-clock grace BEFORE clearing absence on return. A patient who
    -- reconnects after 48h must not retain a room simply by appearing inside.
    local grace = math.max(0, tonumber(Config.EscapeRoomGraceHours) or 48) * 3600
    if hold.absentSince and now - hold.absentSince >= grace and not hold.roomReservationExpired then
        hold.roomReservationExpired = true
        ClearRoomReservation(hold.roomId, Player.PlayerData.citizenid)
        changed = true
        TriggerEvent('parsons:server:RoomGraceExpired', Player.PlayerData.citizenid, hold.roomId)
    end
    local signal = nil
    if inside then
        if hold.transport and hold.transport.active then return hold end
        if hold.absentSince ~= nil then
            hold.lastReturnedAt = now
            hold.absentSince = nil
            hold.absenceReason = nil
            if hold.roomId and not hold.roomReservationExpired then
                MarkRoomAbsence(hold.roomId, Player.PlayerData.citizenid, 0)
            end
            changed = true
            signal = 'parsons:server:PatientReturned'
        end
    elseif hold.absentSince == nil and not (hold.transport and hold.transport.active)
        and lastInside[Player.PlayerData.source] == true then
        hold.absentSince = now
        hold.lastDepartedAt = now
        MarkRoomAbsence(hold.roomId, Player.PlayerData.citizenid, now)
        changed = true
        signal = 'parsons:server:UnauthorizedDepartureVerified'
    end
    if changed then
        Player.Functions.SetMetaData(METADATA_KEY, hold)
        Player.Functions.Save()
        if signal then TriggerEvent(signal, Player.PlayerData.source, Player.PlayerData.citizenid) end
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
    lastInside[src] = inside
    local eligible = hold ~= nil and hold.checkedIn == true and inside
        and not hold.roomReservationExpired and not (hold.transport and hold.transport.active)
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
        absent = hold.absentSince ~= nil,
        transportActive = hold.transport ~= nil and hold.transport.active == true,
        roomId = hold.roomId
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
    -- Court/medical order records a pending arrival; custody is deferred to reception.
    if GetBelongings(Player) then return false, 'existing belongings require reconciliation' end
    hold.checkedIn = false
    SetHold(Player, hold)
    Player.Functions.Save()
    lastTick[Player.PlayerData.source] = os.time()
    lastEligible[Player.PlayerData.source] = false
    lastInside[Player.PlayerData.source] = nil
    TriggerClientEvent('parsons:client:Admit', Player.PlayerData.source, PublicState(hold))
    return true
end)

-- Room reservations are keyed by patient citizen ID; metadata is authoritative across reconnects.
-- Only configured room identifiers can be assigned. No coordinates or door IDs are invented.
local function RoomById(id)
    for _, room in ipairs(Config.PatientRooms or {}) do
        if type(room) == 'table' and room.id == id then return room end
    end
end
local function FindRoomOccupant(roomId, exceptCitizenId)
    for _, id in ipairs(QBCore.Functions.GetPlayers()) do
        local other = GetPlayer(id)
        if other and other.PlayerData.citizenid ~= exceptCitizenId then
            local hold = GetHold(other)
            if hold and hold.checkedIn and hold.roomId == roomId and not hold.roomReservationExpired then
                return other.PlayerData.citizenid
            end
        end
    end
    return nil
end
local roomLocks = {}
local function RoomOwner(roomId)
    local owner = GetResourceKvpString('parsons_room_' .. roomId)
    return owner and owner ~= '' and owner or nil
end
local function AssignRoom(Player, hold)
    local citizenid = Player.PlayerData.citizenid
    -- A missing KVP is not proof of ownership: another online patient may still
    -- hold this room after a restart. Reconcile the occupant before reusing it.
    if hold.roomId and not hold.roomReservationExpired and RoomById(hold.roomId)
        and (not RoomOwner(hold.roomId) or RoomOwner(hold.roomId) == citizenid)
        and not FindRoomOccupant(hold.roomId, citizenid) then
        return hold.roomId
    end
    for _, room in ipairs(Config.PatientRooms or {}) do
        if type(room) == 'table' and type(room.id) == 'string' and room.id ~= ''
            and (room.housing == nil or room.housing == 'standard') -- secure housing requires staff classification
            and not roomLocks[room.id] and not RoomOwner(room.id)
            and not FindRoomOccupant(room.id, citizenid) then
            return room.id
        end
    end
    return nil
end

-- Authorized staff integration: explicitly classify a checked-in patient into a secure
-- basement bedroom. Court holds are NOT automatically assigned secure housing.
-- This server-only export does not create holds or grant door access.
exports('AssignSecureRoom', function(targetId, roomId)
    if not IsTrustedCaller() then return false, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return false, 'patient offline' end
    local hold = TickHold(Player)
    if not hold or not hold.checkedIn then return false, 'patient not checked in' end
    if hold.roomReservationExpired then return false, 'patient must check in again' end
    if hold.transport and hold.transport.active then return false, 'patient away on transport' end
    local room = RoomById(roomId)
    if not room or room.housing ~= 'secure' then return false, 'not a configured secure bedroom' end
    local citizenid = Player.PlayerData.citizenid
    if roomLocks[roomId] then return false, 'room assignment in progress' end
    local owner = RoomOwner(roomId)
    if (owner and owner ~= citizenid) or FindRoomOccupant(roomId, citizenid) then
        return false, 'secure room occupied'
    end
    if hold.roomId == roomId and owner == citizenid then return true end
    roomLocks[roomId] = true
    -- Reserve the destination before releasing the previous room.
    SetResourceKvp(RoomKey(roomId), citizenid)
    SetResourceKvpInt(AbsenceKey(roomId), 0)
    local previousRoom = hold.roomId
    hold.roomId = roomId
    hold.roomReservationExpired = false
    hold.secureHousingAssignedAt = os.time()
    SetHold(Player, hold)
    Player.Functions.Save()
    if previousRoom ~= roomId then ClearRoomReservation(previousRoom, citizenid) end
    roomLocks[roomId] = nil
    TriggerClientEvent('parsons:client:RoomAssignmentChanged', Player.PlayerData.source, PublicState(hold))
    TriggerEvent('parsons:server:RoomAssigned', Player.PlayerData.source, citizenid, roomId)
    return true
end)

-- Door-access policy for a future qb-doorlock adapter. No client can grant access.
-- Rooms are not wired to qb-doorlock until real MLO door IDs are configured.
local function RoomForDoor(doorId)
    for _, room in ipairs(Config.PatientRooms or {}) do
        if type(room) == 'table' and type(room.doorIds) == 'table' then
            for _, configured in ipairs(room.doorIds) do
                if configured == doorId then return room.id end
            end
        end
    end
end
local function CanAccessRoomDoor(src, doorId)
    local Player = GetPlayer(src)
    if not Player then return false end
    local roomId = RoomForDoor(doorId)
    if not roomId then return false end
    local job = Player.PlayerData.job
    if job and job.onduty then
        for _, allowed in ipairs(Config.PatientRoomStaffJobTypes or {'ems'}) do
            if job.type == allowed or job.name == allowed then return true end
        end
    end
    local hold = GetHold(Player)
    return hold ~= nil and hold.checkedIn == true and not hold.roomReservationExpired
        and not (hold.transport and hold.transport.active) and hold.roomId == roomId
        and RoomOwner(roomId) == Player.PlayerData.citizenid
end
exports('CanAccessRoomDoor', function(src, doorId)
    -- Read-only query; the doorlock integration must call server-side and enforce
    -- this decision itself. This export does not unlock any door.
    return CanAccessRoomDoor(tonumber(src), doorId)
end)

-- Reception intake is a distinct phase; server verifies proximity before custody changes.
-- Room assignment remains blocked until the real mapped room allocator is implemented.
RegisterNetEvent('parsons:server:ReceptionCheckIn', function()
    local src = source
    local Player = GetPlayer(src)
    local point = Config.Reception and Config.Reception.coords
    if not Player or not point then return end
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local nearby = #(GetEntityCoords(ped) - vec3(point.x, point.y, point.z)) <= 4.0
    for _, other in ipairs(Config.Reception.additionalCoords or {}) do
        if other.x and other.y and other.z and
            #(GetEntityCoords(ped) - vec3(other.x, other.y, other.z)) <= 4.0 then nearby = true break end
    end
    if not nearby then return end
    local hold = GetHold(Player)
    if not hold or (hold.checkedIn and not hold.roomReservationExpired) then return end
    if hold.checkedIn and hold.roomReservationExpired then
        local roomId = AssignRoom(Player, hold)
        if not roomId then
            TriggerClientEvent('QBCore:Notify', src, 'No available room for reassignment.', 'error')
            return
        end
        if roomLocks[roomId] or RoomOwner(roomId) then return end
        roomLocks[roomId] = true
        SetResourceKvp(RoomKey(roomId), Player.PlayerData.citizenid)
        SetResourceKvpInt(AbsenceKey(roomId), 0)
        hold.roomId = roomId
        hold.roomReservationExpired = false
        hold.absentSince = nil
        hold.absenceReason = nil
        SetHold(Player, hold)
        Player.Functions.Save()
        roomLocks[roomId] = nil
        lastTick[src] = os.time()
        lastEligible[src] = false
        TriggerClientEvent('parsons:client:ReceptionComplete', src, PublicState(hold))
        TriggerEvent('parsons:server:RoomAssigned', src, Player.PlayerData.citizenid, roomId)
        return
    end
    local roomId = AssignRoom(Player, hold)
    if not roomId then
        TriggerClientEvent('QBCore:Notify', src, 'No available mapped patient room. Contact reception staff.', 'error')
        return
    end
    if roomLocks[roomId] or (RoomOwner(roomId) and RoomOwner(roomId) ~= Player.PlayerData.citizenid) then return end
    roomLocks[roomId] = true
    local stored, err = StoreBelongings(Player)
    if not stored then
        roomLocks[roomId] = nil
        TriggerClientEvent('QBCore:Notify', src, err or 'Belongings storage failed; staff assistance required.', 'error')
        return
    end
    SetResourceKvp(RoomKey(roomId), Player.PlayerData.citizenid)
    SetResourceKvpInt(AbsenceKey(roomId), 0)
    hold.checkedIn = true
    hold.roomId = roomId
    hold.roomReservationExpired = false
    hold.absentSince = nil
    hold.checkedInAt = os.time()
    SetHold(Player, hold)
    Player.Functions.Save()
    roomLocks[roomId] = nil
    lastTick[src] = os.time()
    lastEligible[src] = false
    TriggerClientEvent('parsons:client:ReceptionComplete', src, PublicState(hold))
    TriggerEvent('parsons:server:RoomAssigned', src, Player.PlayerData.citizenid, roomId)
    TriggerClientEvent('QBCore:Notify', src, 'Reception check-in complete. Assigned room: ' .. roomId, 'success')
end)

-- Temporary court transport is never a discharge. Officer and patient must be at the
-- configured guard shack. All checks are server-side; no client-supplied patient authority.
local function NearGuard(src)
    local point = Config.GuardShack and Config.GuardShack.coords
    if not point then return false end
    local ped = GetPlayerPed(src)
    return ped and ped ~= 0 and #(GetEntityCoords(ped) - vec3(point.x, point.y, point.z)) <= 5.0
end
local function OnDutyLEO(src)
    local officer = GetPlayer(src)
    local job = officer and officer.PlayerData.job
    return officer and job and job.type == 'leo' and job.onduty == true and officer or nil
end
local function TransportAction(src, patientId, returning)
    local officer = OnDutyLEO(src)
    local patient = GetPlayer(patientId)
    if not officer or not patient or officer.PlayerData.citizenid == patient.PlayerData.citizenid
        or not NearGuard(src) or not NearGuard(patient.PlayerData.source) then
        return false, 'Authorized officer and patient must both be at the guard shack'
    end
    local hold = TickHold(patient)
    if not hold or not hold.checkedIn then return false, 'Patient is not checked in' end
    if returning then
        if not hold.transport or not hold.transport.active then return false, 'No active transport' end
        hold.transport.returnedAt = os.time()
        hold.transport.active = false
        hold.absentSince = nil
        hold.absenceReason = nil
        if not hold.roomReservationExpired then MarkRoomAbsence(hold.roomId, patient.PlayerData.citizenid, 0) end
        hold.lastReturnedAt = os.time()
    else
        if hold.transport and hold.transport.active then return false, 'Already checked out for transport' end
        if not InsideFacility(patient.PlayerData.source) then return false, 'Patient must be inside Parsons' end
        hold.transport = {active = true, officer = officer.PlayerData.citizenid, startedAt = os.time(), purpose = 'court'}
        hold.absentSince = nil
        hold.absenceReason = nil
        MarkRoomAbsence(hold.roomId, patient.PlayerData.citizenid, 0)
    end
    SetHold(patient, hold)
    patient.Functions.Save()
    lastTick[patient.PlayerData.source] = os.time()
    lastEligible[patient.PlayerData.source] = false
    TriggerClientEvent('parsons:client:TransportState', patient.PlayerData.source, PublicState(hold))
    TriggerEvent(returning and 'parsons:server:TransportReturned' or 'parsons:server:TransportStarted',
        patient.PlayerData.source, patient.PlayerData.citizenid, officer.PlayerData.citizenid)
    return true
end
RegisterNetEvent('parsons:server:TransportAction', function(patientId, returning)
    local src = source
    if type(patientId) ~= 'number' or patientId % 1 ~= 0 or type(returning) ~= 'boolean' then return end
    local ok, err = TransportAction(src, patientId, returning)
    TriggerClientEvent('QBCore:Notify', src, ok and (returning and 'Patient returned to Parsons.' or 'Patient checked out for court transport.')
        or err, ok and 'success' or 'error')
end)
exports('GetTransportStatus', function(targetId)
    if not IsTrustedCaller() then return nil, 'untrusted resource' end
    local patient = GetPlayer(targetId)
    if not patient then return nil, 'patient offline' end
    local hold = GetHold(patient)
    return hold and hold.transport or nil
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
    ClearRoomReservation(hold.roomId, Player.PlayerData.citizenid)
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
    lastInside[Player.PlayerData.source] = nil
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
    -- Status is available at either medical reception PED or the guard shack.
    -- Do not let the existence of a guard coordinate hide both reception desks.
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local pos = GetEntityCoords(ped)
    local function Near(point)
        return point and point.x and point.y and point.z
            and #(pos - vec3(point.x, point.y, point.z)) <= 5.0
    end
    local nearby = Near(Config.GuardShack and Config.GuardShack.coords)
        or Near(Config.Reception and Config.Reception.coords)
    if not nearby then
        for _, point in ipairs((Config.Reception and Config.Reception.additionalCoords) or {}) do
            if Near(point) then nearby = true break end
        end
    end
    if not nearby then return end
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

-- Expire disconnected patients' room reservations without requiring them to reconnect.
-- Metadata reconciliation happens when the patient next loads; the hold is never deleted.
CreateThread(function()
    while true do
        Wait(60000)
        local now = os.time()
        local grace = math.max(0, tonumber(Config.EscapeRoomGraceHours) or 48) * 3600
        for _, room in ipairs(Config.PatientRooms or {}) do
            if type(room) == 'table' and type(room.id) == 'string' then
                local owner = GetResourceKvpString(RoomKey(room.id))
                local since = GetResourceKvpInt(AbsenceKey(room.id))
                if owner and since > 0 and now - since >= grace then
                    if ClearRoomReservation(room.id, owner) then
                        TriggerEvent('parsons:server:RoomGraceExpired', owner, room.id)
                    end
                end
            end
        end
    end
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
    local src = source
    local Player = GetPlayer(src)
    if Player then
        local hold = GetHold(Player)
        if hold and hold.checkedIn and not hold.absentSince and not (hold.transport and hold.transport.active) then
            hold.absentSince = os.time()
            hold.lastDepartedAt = hold.absentSince
            hold.absenceReason = 'disconnect'
            MarkRoomAbsence(hold.roomId, Player.PlayerData.citizenid, hold.absentSince)
            SetHold(Player, hold)
            Player.Functions.Save()
        end
    end
    lastTick[source] = nil
    lastEligible[source] = nil
    lastInside[source] = nil
    departureCooldown[source] = nil
end)

-- Trusted integrations can inspect a patient's current recovery status without
-- changing commitment, room ownership or belongings.
exports('GetPatientSecurityStatus', function(targetId)
    if not IsTrustedCaller() then return nil, 'untrusted resource' end
    local Player = GetPlayer(targetId)
    if not Player then return nil, 'patient offline' end
    local hold = TickHold(Player)
    if not hold then return nil, 'no active hold' end
    return {
        checkedIn = hold.checkedIn == true,
        insideFacility = InsideFacility(Player.PlayerData.source),
        absentSince = hold.absentSince,
        lastDepartedAt = hold.lastDepartedAt,
        lastReturnedAt = hold.lastReturnedAt,
        roomReservationExpired = hold.roomReservationExpired == true,
        remainingSeconds = hold.remainingSeconds
    }
end)
