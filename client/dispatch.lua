-- PowerMoves-PSDispatch CustomAlert integration; one server-selected on-duty responder emits each alert.
local labels = {
    security_communications_failure = 'Gruppe Sechs reports a security monitoring alarm at Parsons Rehabilitation Center',
    failed_gate_hack = 'Gruppe Sechs reports attempted gate tampering at Parsons Rehabilitation Center',
    gate_security_compromised = 'Gruppe Sechs reports electronic gate tampering at Parsons Rehabilitation Center',
    unauthorized_aircraft = 'Gruppe Sechs reports unauthorized low aircraft over Parsons Rehabilitation Center',
    patient_departure = 'Gruppe Sechs reports confirmed unauthorized patient departure from Parsons',
    patient_return = 'Gruppe Sechs reports patient returned to Parsons'
}
RegisterNetEvent('parsons:security:SendDispatch', function(data)
    local cfg = Config.Security and Config.Security.PSDispatch
    if not cfg or not cfg.enabled or GetResourceState('ps-dispatch') ~= 'started' then return end
    if type(data) ~= 'table' or not labels[data.kind] or type(data.coords) ~= 'table' then return end
    if type(data.coords.x) ~= 'number' or type(data.coords.y) ~= 'number' or type(data.coords.z) ~= 'number' then return end
    exports['ps-dispatch']:CustomAlert({
        coords = vector3(data.coords.x, data.coords.y, data.coords.z),
        message = labels[data.kind], dispatchCode = 'PARSONS_' .. data.kind,
        code = data.code, jobs = data.jobs, priority = data.kind == 'patient_departure' and 1 or 2,
        icon = 'fas fa-shield-alt', sprite = 60, color = 3, scale = 0.8, length = 3
    })
end)
