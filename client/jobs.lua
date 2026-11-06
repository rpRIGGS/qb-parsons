-- Parsons patient activity framework. Original prison work mechanics are intentionally
-- not executed: they reduced sentence time and awarded contraband.
-- Future activities will be configured under Config.Jobs and Config.Locations.jobs.
local activeActivity = nil

RegisterNetEvent('parsons:client:ActivityStatus', function(activity)
    activeActivity = activity
end)

-- Keep a safe entry point for future activity interactions without granting
-- rewards or changing medical/judicial hold duration.
function GetParsonsActivity()
    return activeActivity
end
