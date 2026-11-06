-- Client-side departure hint. Server independently verifies the Parsons polygon.
-- The hold, belongings and remaining treatment time are never cleared here.
local admitted = false
local departureReported = false
local zone = nil

local function BuildZone()
    local config = Config.FacilityZone
    if type(config) ~= 'table' or type(config.points) ~= 'table' or #config.points < 3
        or type(config.minZ) ~= 'number' or type(config.maxZ) ~= 'number' then return nil end
    return PolyZone:Create(config.points, {
        name = 'parsons_facility',
        minZ = config.minZ,
        maxZ = config.maxZ,
        debugPoly = false
    })
end

RegisterNetEvent('parsons:client:AdmissionState', function(active)
    admitted = active == true
    departureReported = false
end)

CreateThread(function()
    zone = BuildZone()
    while true do
        Wait(1500)
        if admitted and zone then
            local inside = zone:isPointInside(GetEntityCoords(PlayerPedId()))
            if not inside and not departureReported then
                departureReported = true
                TriggerServerEvent('parsons:server:ReportUnauthorizedDeparture')
            elseif inside then
                departureReported = false
            end
        end
    end
end)
