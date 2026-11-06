Config = {}
Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)

-- Parsons therapeutic, recreational and occupational activities. No sentence reductions.
Config.Activities = {
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
    provider = 'Gruppe Sechs',
    minigames = {
        electrical = {difficulty = {'easy', 'medium', 'medium'}, inputs = {'w', 'a', 's', 'd'}},
        gate = {difficulty = {'medium', 'medium', 'hard'}, inputs = {'w', 'a', 's', 'd'}}
    },
    aircraft = {enabled = true, verifySeconds = 5, cooldownSeconds = 180, exemptJobTypes = {'leo', 'ems', 'fire'}},
    monitoring = {incidentCooldownSeconds = 120},
    alarm = {durationSeconds = 300, resetJobTypes = {'leo', 'ems'}, resetPoints = {}}, -- map qb-target reset stations at guard shack and medical offices
    guard = {weapon = 'WEAPON_NIGHTSTICK', respawnSeconds = 300, clearRadius = 35.0, ped = 's_m_m_security_01'}, -- guard shack position pending
    power = {localOnly = true, restoreSeconds = 300, controllableLights = {}}, -- never invoke global qb-weathersync blackout
    PSDispatch = {enabled = true, jobs = {'police', 'sheriff', 'state', 'leo'}, codes = {
        security_communications_failure = '10-90', gate_security_compromised = '10-90', failed_gate_hack = '10-90',
        unauthorized_aircraft = '10-66', patient_departure = '10-80', patient_return = '10-80', guard_assault = '10-90', guard_down = '10-90'
    }},
    electrical = {item = 'electronickit', inside = nil, outside = nil, durationSeconds = 300},
    gate = {item = 'gatecrack', hack = nil, bypass = nil, doorIds = {}, compromisedSeconds = 300},
    -- PS Dispatch is the optional configured police alert adapter; no legacy fallback.
}

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

Config.PatientUniformsEnabled = false -- Patient clothing to be finalized during Stages 1–4

-- Parsons activity stations remain disabled until the actual MLO is mapped.
Config.Locations = {
    activities = {
        swimming = {}, tennis = {}, yoga = {}, meditation = {},
        gardening = {}, raking = {}, laundry = {}, foodprep = {},
        dishwashing = {}, restocking = {}, cleaning = {},
        therapy = {}, recreation = {}, rehabilitation = {}
    }
}
