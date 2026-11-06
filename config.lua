Config = {}
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)

-- Parsons patient activities will be defined here as they are designed.
-- No prison electrician work or sentence-reduction jobs.
Config.Jobs = {
    therapy = {label = 'Therapy Session', durationSeconds = 120, cooldownSeconds = 300},
    recreation = {label = 'Recreation', durationSeconds = 90, cooldownSeconds = 180},
    rehabilitation = {label = 'Rehabilitation Activity', durationSeconds = 120, cooldownSeconds = 300},
    swimming = {label = 'Supervised Swimming', durationSeconds = 180, cooldownSeconds = 300},
    tennis = {label = 'Tennis', durationSeconds = 180, cooldownSeconds = 300},
    yoga = {label = 'Outdoor Yoga', durationSeconds = 150, cooldownSeconds = 240, scenario = 'WORLD_HUMAN_YOGA', stressRelief = 3},
    meditation = {label = 'Garden Meditation', durationSeconds = 120, cooldownSeconds = 180, scenario = 'WORLD_HUMAN_YOGA', stressRelief = 5},
    gardening = {label = 'Gardening', durationSeconds = 180, cooldownSeconds = 240, scenario = 'WORLD_HUMAN_GARDENER_PLANT'},
    raking = {label = 'Groundskeeping', durationSeconds = 150, cooldownSeconds = 240, scenario = 'WORLD_HUMAN_GARDENER_LEAF_BLOWER'},
    laundry = {label = 'Laundry Duties', durationSeconds = 180, cooldownSeconds = 240},
    foodprep = {label = 'Kitchen Food Preparation', durationSeconds = 180, cooldownSeconds = 240},
    dishwashing = {label = 'Dishwashing', durationSeconds = 120, cooldownSeconds = 180},
    restocking = {label = 'Cafeteria Restocking', durationSeconds = 180, cooldownSeconds = 240},
    cleaning = {label = 'Facility Cleaning', durationSeconds = 150, cooldownSeconds = 240, scenario = 'WORLD_HUMAN_JANITOR'}
}
-- Activity coordinates remain unset until the Parsons MLO is mapped.
-- No activity reduces a hold or grants money/items.
Config.EscapeRoomGraceHours = 48 -- Real-world hours away before an escaped patient's room may be reassigned
Config.PatientRooms = {} -- Map actual room identifiers and door access after inspecting Parsons MLO
Config.Reception = { coords = nil, ped = 's_m_m_doctor_01' } -- Initial check-in and return to treatment
Config.GuardShack = { coords = nil, ped = 's_m_m_security_01' } -- Status and authorized checkout
Config.Arrival = nil -- vector4 inside front gate, never reuse prison spawns
Config.Release = nil -- vector4 outside Parsons gate
Config.FacilityZone = { points = {}, minZ = nil, maxZ = nil } -- Parsons PolyZone coordinates pending
-- Stage 7: one fenced-property polygon for patient eligibility and low-aircraft detection.
-- maxZ is also the aircraft alert ceiling; minZ is the property floor.
Config.Security = {
    provider = 'Group Six',
    minigames = {
        electrical = {difficulty = {'easy', 'medium', 'medium'}, inputs = {'w', 'a', 's', 'd'}},
        gate = {difficulty = {'medium', 'medium', 'hard'}, inputs = {'w', 'a', 's', 'd'}}
    },
    aircraft = {enabled = true, verifySeconds = 5, cooldownSeconds = 180},
    monitoring = {incidentCooldownSeconds = 120},
    PSDispatch = {enabled = false, jobs = {'police', 'sheriff', 'state', 'leo'}, codes = {
        security_communications_failure = '10-90', gate_security_compromised = '10-90',
        unauthorized_aircraft = '10-66', patient_departure = '10-80', patient_return = '10-80'
    }},
    electrical = {item = 'electronickit', inside = nil, outside = nil, durationSeconds = 180},
    gate = {item = 'gatecrack', hack = nil, bypass = nil, compromisedSeconds = 120},
    -- Incident notifications are server events for a future dispatch/MDT adapter.
    -- No assumed dispatch resource or fictional NPC response.
}
Config.EscapeDetectionRadius = 200.0 -- Legacy prison radius; replace with validated facility polygon

Config.Uniforms = {
    ['male'] = {
        outfitData = {
            ['t-shirt'] = { item = 15, texture = 0 },
            ['torso2'] = { item = 345, texture = 0 },
            ['arms'] = { item = 19, texture = 0 },
            ['pants'] = { item = 3, texture = 7 },
            ['shoes'] = { item = 1, texture = 0 },
        }
    },
    ['female'] = {
        outfitData = {
            ['t-shirt'] = { item = 14, texture = 0 },
            ['torso2'] = { item = 370, texture = 0 },
            ['arms'] = { item = 0, texture = 0 },
            ['pants'] = { item = 0, texture = 12 },
            ['shoes'] = { item = 1, texture = 0 },
        }
    },
}

Config.PatientUniformsEnabled = false -- Preserve original prison uniform settings until Parsons clothing is planned

-- Original qb-prison coordinates retained as placeholders until Parsons MLO positions are provided.
-- Do not treat these as final Parsons coordinates.
Config.Locations = {
    freedom = vector4(1740.88, 2476.57, 44.85, 299.49), -- upstream placeholder
    desk = vector4(1740.88, 2476.57, 44.85, 299.49), -- Parsons reception placeholder
    outside = vector4(1848.13, 2586.05, 44.67, 269.5),
    yard = vector4(1765.67, 2565.91, 44.56, 1.5),
    middle = vector4(1693.33, 2569.51, 44.55, 123.5),
    spawns = {
        { coords = vector4(1661.046, 2524.681, 45.564, 260.545) },
        { coords = vector4(1650.812, 2540.582, 45.564, 230.436) },
        { coords = vector4(1654.959, 2545.535, 45.564, 230.436) },
        { coords = vector4(1697.106, 2525.558, 45.564, 187.208) },
        { coords = vector4(1673.084, 2519.823, 45.564, 229.542) },
        { coords = vector4(1666.029, 2511.367, 45.564, 233.888) },
        { coords = vector4(1691.229, 2509.635, 45.564, 52.432) },
        { coords = vector4(1770.59, 2536.064, 45.564, 258.113) },
        { coords = vector4(1792.45, 2584.37, 45.56, 276.24) },
        { coords = vector4(1768.33, 2566.08, 45.56, 176.83) },
        { coords = vector4(1696.09, 2469.4, 45.56, 1.4) }
    },
    -- Placeholder for future Parsons therapy, recreation and rehabilitation activity coordinates.
    -- Keep other original prison coordinates above as temporary MLO placeholders.
    -- Set each activity station to { coords = vector3(...), radius = 4.0 } once mapped.
    -- nil disables interaction safely; no prison coordinates are substituted.
    jobs = {
        swimming = {}, tennis = {}, yoga = {}, meditation = {},
        gardening = {}, raking = {}, laundry = {}, foodprep = {},
        dishwashing = {}, restocking = {}, cleaning = {},
        therapy = {}, recreation = {}, rehabilitation = {}
    }
}
