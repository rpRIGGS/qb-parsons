-- Parsons unauthorized-departure monitoring, adapted from qb-prison's escape concept.
-- No prison gate IDs, hacking mini-game, prison alarms, or automatic hold clearing.
-- Server retains authority over the hold; leaving the grounds is not a discharge.
local admitted = false
local departureReported = false

RegisterNetEvent('parsons:client:AdmissionState', function(active)
    admitted = active == true
    departureReported = false
end)

CreateThread(function()
    while true do
        Wait(1500)
        local center = Config.Locations.middle
        local radius = Config.EscapeDetectionRadius or 200.0
        if admitted and center and radius > 0 then
            local pos = GetEntityCoords(PlayerPedId())
            local outside = #(pos.xy - vec2(center.x, center.y)) > radius
            if outside and not departureReported then
                departureReported = true
                -- Task 4: validate admission and actual perimeter server-side,
                -- then notify the appropriate Parsons/LEO dispatch workflow.
                TriggerServerEvent('parsons:server:ReportUnauthorizedDeparture')
            elseif not outside then
                departureReported = false
            end
        end
    end
end)
