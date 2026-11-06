-- PS Dispatch optional integration; only a server-selected on-duty responder emits alerts.
local labels = {
    security_communications_failure = 'Parsons security monitoring reports lost communications; request welfare/security check',
    gate_security_compromised = 'Parsons electronic gate security compromised; units requested',
    unauthorized_aircraft = 'Unauthorized low aircraft entering Parsons secured property',
    patient_departure = 'Confirmed unauthorized patient departure from Parsons',
    patient_return = 'Parsons patient recovered; update incident'
}
RegisterNetEvent('parsons:security:SendDispatch', function(data)
    local cfg = Config.Security and Config.Security.PSDispatch
    if not cfg or not cfg.enabled or GetResourceState('ps-dispatch') ~= 'started' then return end
    if type(data) ~= 'table' or not labels[data.kind] then return end
    exports['ps-dispatch']:CustomAlert({
        coords = vector3(data.coords.x, data.coords.y, data.coords.z),
        message = labels[data.kind], dispatchCode = 'PARSONS_' .. data.kind,
        code = data.code, jobs = data.jobs, priority = data.kind == 'patient_departure' and 1 or 2,
        icon = 'fas fa-shield-alt', sprite = 60, color = 3, scale = 0.8, length = 3
    })
end)
