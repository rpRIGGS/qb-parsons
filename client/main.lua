local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local admitted = false
local hold = nil
local deskPed = nil
local guardPed = nil
local refreshSerial = 0

local function TransferTo(coords)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(10) end
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z - 0.9, false, false, false, false)
    SetEntityHeading(PlayerPedId(), coords.w)
    Wait(500)
    DoScreenFadeIn(1000)
end

local function ApplyPatientClothes()
    if not Config.PatientUniformsEnabled then return end
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then return end
    local gender = QBCore.Functions.GetPlayerData().charinfo.gender
    TriggerEvent('qb-clothing:client:loadOutfit', gender == 0 and Config.Uniforms.male or Config.Uniforms.female)
end

-- Server-issued operational state only. The server-side authoritative hold implementation
-- and admission authorization are Task 3/4; never infer release from a local countdown.
RegisterNetEvent('parsons:client:Admit', function(state)
    if type(state) ~= 'table' or not state.active then return end
    refreshSerial = refreshSerial + 1
    hold = state
    admitted = true
    TriggerEvent('parsons:client:AdmissionState', true)
    -- A commitment is pending until reception check-in; no belongings or clothing are changed here.
    if Config.Arrival then TransferTo(Config.Arrival) end
    QBCore.Functions.Notify('Commitment recorded. Report to Parsons reception for check-in.', 'primary')
end)

RegisterNetEvent('parsons:client:ReceptionComplete', function(state)
    if type(state) ~= 'table' or not state.active or not state.checkedIn then return end
    hold = state
    admitted = true
    ApplyPatientClothes()
    TriggerEvent('parsons:client:AdmissionState', true)
end)

RegisterNetEvent('parsons:client:Discharge', function()
    -- A server-issued event is not by itself a substitute for authorization;
    -- the server must validate discharge before emitting it.
    if not admitted then return end
    if not Config.Release then
        QBCore.Functions.Notify('Discharged. Exit location is not mapped; contact staff.', 'primary')
    end
    refreshSerial = refreshSerial + 1
    admitted = false
    hold = nil
    TriggerEvent('parsons:client:AdmissionState', false)
    if Config.PatientUniformsEnabled then
        TriggerEvent('qb-clothing:client:loadPlayerSkin')
    end
    if Config.Release then TransferTo(Config.Release) end
    QBCore.Functions.Notify(Lang:t('success.discharged'), 'success')
end)

local function RefreshStatus()
    refreshSerial = refreshSerial + 1
    local serial = refreshSerial
    QBCore.Functions.TriggerCallback('parsons:server:GetAdmission', function(state)
        if serial ~= refreshSerial then return end
        if type(state) ~= 'table' or not state.active then
            admitted = false
            hold = nil
            TriggerEvent('parsons:client:AdmissionState', false)
            return
        end
        hold = state
        admitted = true
        TriggerEvent('parsons:client:AdmissionState', true)
        -- Reconnect must not teleport an escaped patient back into treatment.
        -- Recovery is performed by staff and verified by the server polygon.
    end)
end

local function RequestDischargeStatus()
    if not admitted then return end
    TriggerServerEvent('parsons:server:RequestDischargeStatus')
end

local function SetupDesk()
    if deskPed or not Config.Reception or not Config.Reception.coords then return end
    local model = joaat(Config.Reception.ped or 's_m_m_doctor_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local pos = Config.Reception.coords
    deskPed = CreatePed(0, model, pos.x, pos.y, pos.z - 1.0, pos.w, false, true)
    FreezeEntityPosition(deskPed, true)
    SetEntityInvincible(deskPed, true)
    SetBlockingOfNonTemporaryEvents(deskPed, true)
    TaskStartScenarioInPlace(deskPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    if Config.UseTarget then
        exports['qb-target']:AddTargetEntity(deskPed, {
            options = {
                {icon = 'fas fa-clipboard-check', label = 'Reception check-in',
                    action = function() TriggerServerEvent('parsons:server:ReceptionCheckIn') end,
                    canInteract = function() return admitted and hold and not hold.checkedIn end},
                {icon = 'fas fa-clipboard', label = Lang:t('info.check_hold'), action = RequestDischargeStatus,
                    canInteract = function() return admitted end}
            },
            distance = 2.5
        })
    end
end

-- Guard interaction is only a UI entry point; the server validates officer duty,
-- patient identity, both players' positions, and active hold state.
local function TransportPrompt(returning)
    local response = lib.inputDialog(returning and 'Return patient from court' or 'Court transport checkout', {
        {type = 'number', label = 'Patient server ID', required = true, min = 1}
    })
    if not response or not response[1] then return end
    TriggerServerEvent('parsons:server:TransportAction', tonumber(response[1]), returning)
end
local function SetupGuard()
    if guardPed or not Config.GuardShack or not Config.GuardShack.coords then return end
    if GetResourceState('qb-target') ~= 'started' then return end
    local model = joaat(Config.GuardShack.ped or 's_m_m_security_01')
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local point = Config.GuardShack.coords
    guardPed = CreatePed(0, model, point.x, point.y, point.z - 1.0, point.w or 0.0, false, true)
    FreezeEntityPosition(guardPed, true)
    SetEntityInvincible(guardPed, false)
    SetBlockingOfNonTemporaryEvents(guardPed, true)
    TaskStartScenarioInPlace(guardPed, 'WORLD_HUMAN_GUARD_STAND', 0, true)
    exports['qb-target']:AddTargetEntity(guardPed, {
        options = {
            {icon = 'fas fa-car', label = 'Check out patient for court transport',
                action = function() TransportPrompt(false) end},
            {icon = 'fas fa-clipboard-check', label = 'Return patient from court transport',
                action = function() TransportPrompt(true) end}
        }, distance = 2.5
    })
end
RegisterNetEvent('parsons:client:TransportState', function(state)
    if type(state) ~= 'table' or not state.active then return end
    hold = state
    admitted = true
    QBCore.Functions.Notify(state.transportActive and 'Court transport authorized. Your hold is paused.'
        or 'Court transport completed. Report to treatment.', 'primary')
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    RefreshStatus()
    SetupDesk()
    SetupGuard()
end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    refreshSerial = refreshSerial + 1
    admitted = false
    hold = nil
    TriggerEvent('parsons:client:AdmissionState', false)
end)
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    Wait(500)
    if LocalPlayer.state.isLoggedIn then RefreshStatus() end
    SetupDesk()
end)

CreateThread(function()
    if Config.UseTarget then return end
    if not Config.Reception or not Config.Reception.coords then return end
    local pos = Config.Reception.coords
    local zone = BoxZone:Create(vector3(pos.x, pos.y, pos.z), 2.75, 2.75, {name='parsons_desk',debugPoly=false})
    local inside = false
    zone:onPlayerInOut(function(entered)
        inside = entered
        if entered and admitted then exports['qb-core']:DrawText(Lang:t('info.check_hold_prompt'), 'left')
        else exports['qb-core']:HideText() end
    end)
    while true do
        if inside and admitted and IsControlJustReleased(0, 38) then
            exports['qb-core']:KeyPressed()
            RequestDischargeStatus()
        end
        Wait(inside and 0 or 1000)
    end
end)
