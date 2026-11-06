local QBCore = exports['qb-core']:GetCoreObject({'Functions'})
local admitted = false
local hold = nil
local deskPed = nil

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
    if type(Config.Locations.spawns) ~= 'table' or #Config.Locations.spawns == 0 then
        QBCore.Functions.Notify(Lang:t('error.missing_admission_location'), 'error')
        return
    end
    hold = state
    admitted = true
    TriggerEvent('parsons:client:AdmissionState', true)
    local spawn = Config.Locations.spawns[math.random(#Config.Locations.spawns)]
    TransferTo(spawn.coords)
    ApplyPatientClothes()
    QBCore.Functions.Notify(Lang:t('info.admitted'), 'primary')
end)

RegisterNetEvent('parsons:client:Discharge', function()
    -- A server-issued event is not by itself a substitute for authorization;
    -- the server must validate discharge before emitting it.
    if not admitted then return end
    if not Config.Locations.outside then return end
    admitted = false
    hold = nil
    TriggerEvent('parsons:client:AdmissionState', false)
    TriggerEvent('qb-clothes:loadPlayerSkin')
    TransferTo(Config.Locations.outside)
    QBCore.Functions.Notify(Lang:t('success.discharged'), 'success')
end)

local function RefreshStatus()
    QBCore.Functions.TriggerCallback('parsons:server:GetAdmission', function(state)
        if type(state) ~= 'table' or not state.active then
            admitted = false
            hold = nil
            TriggerEvent('parsons:client:AdmissionState', false)
            return
        end
        hold = state
        admitted = true
        TriggerEvent('parsons:client:AdmissionState', true)
        -- Rejoin/restart: reuse qb-prison's return-to-facility pattern.
        if Config.Locations.spawns and #Config.Locations.spawns > 0 then
            TransferTo(Config.Locations.spawns[math.random(#Config.Locations.spawns)].coords)
        end
    end)
end

local function RequestDischargeStatus()
    if not admitted then return end
    TriggerServerEvent('parsons:server:RequestDischargeStatus')
end

local function SetupDesk()
    if deskPed or not Config.Locations.desk then return end
    local model = `s_m_m_doctor_01`
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(0) end
    local pos = Config.Locations.desk
    deskPed = CreatePed(0, model, pos.x, pos.y, pos.z - 1.0, pos.w, false, true)
    FreezeEntityPosition(deskPed, true)
    SetEntityInvincible(deskPed, true)
    SetBlockingOfNonTemporaryEvents(deskPed, true)
    TaskStartScenarioInPlace(deskPed, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    if Config.UseTarget then
        exports['qb-target']:AddTargetEntity(deskPed, {
            options = {{icon = 'fas fa-clipboard', label = Lang:t('info.check_hold'), action = RequestDischargeStatus,
                canInteract = function() return admitted end}},
            distance = 2.5
        })
    end
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    RefreshStatus()
    SetupDesk()
end)
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
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
    if not Config.Locations.desk then return end
    local pos = Config.Locations.desk
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
