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
Config.PatientRooms = { -- Only bedded rooms; padded observation rooms are excluded from routine allocation
    {id = 'medical-1', housing = 'standard', doorIds = {'Parsons-Main Floor med ward 4'}},
    {id = 'medical-2', housing = 'standard', doorIds = {'Parsons-Main Floor med ward 5'}},
    {id = 'medical-3', housing = 'standard', doorIds = {'Parsons-Main Floor med ward 6'}},
    {id = 'medical-4', housing = 'standard', doorIds = {'Parsons-Main Floor med ward 7'}},
    {id = 'secure-1', housing = 'secure', doorIds = {'Parsons-Basement 7'}},
    {id = 'secure-2', housing = 'secure', doorIds = {'Parsons-Basement 8'}},
    {id = 'secure-3', housing = 'secure', doorIds = {'Parsons-Basement 9'}},
    {id = 'secure-4', housing = 'secure', doorIds = {'Parsons-Basement 10'}},
}
Config.ObservationRooms = {
    {id = 'observation-1', doorIds = {'Parsons-Basement 5'}},
    {id = 'observation-secure', doorIds = {'Parsons-Basement 6'}}
}
Config.SecureWardGateDoorIds = {'Parsons-Basement 11'} -- verify partition in game
Config.PatientRoomStaffJobTypes = {'ems', 'parsonsmed'} -- On-duty medical staff by job type or name; no blanket LEO access
Config.Reception = { coords = vector4(-1501.46, 849.16, 181.6, 249.1), additionalCoords = {vector4(-1514.51, 848.23, 181.6, 114.2)}, ped = 's_m_m_doctor_01' } -- Initial check-in and return to treatment
Config.GuardShack = { coords = vector4(-1486.85, 881.13, 183.35, 341.37), ped = 's_m_m_security_01' } -- Status and authorized checkout
Config.Arrival = vector4(-1523.8, 854.92, 181.59, 36.46) -- Inside Parsons gate
Config.Release = vector4(-1475.89, 881.74, 182.98, 301.48) -- Outside Parsons gate
Config.FacilityZone = { -- Parsons PolyZone export, 2026-11-06; adjust vertical limits after devPoly inspection
    points = {
        vector2(-1484.771484375, 880.91412353516),
        vector2(-1474.4055175781, 873.27014160156),
        vector2(-1469.2403564453, 849.04193115234),
        vector2(-1464.9094238281, 831.99353027344),
        vector2(-1461.7163085938, 820.06103515625),
        vector2(-1481.4152832031, 811.54919433594),
        vector2(-1485.1281738281, 803.78729248047),
        vector2(-1489.724609375, 796.67309570312),
        vector2(-1503.4226074219, 795.58917236328),
        vector2(-1515.5177001953, 790.4970703125),
        vector2(-1527.3354492188, 784.97692871094),
        vector2(-1539.8552246094, 773.03704833984),
        vector2(-1550.0793457031, 767.38714599609),
        vector2(-1569.3668212891, 758.40814208984),
        vector2(-1585.2768554688, 750.65399169922),
        vector2(-1592.5657958984, 747.09399414062),
        vector2(-1600.3880615234, 743.90753173828),
        vector2(-1608.96875, 744.81005859375),
        vector2(-1616.2114257812, 749.19097900391),
        vector2(-1623.3607177734, 764.51098632812),
        vector2(-1619.4779052734, 771.78015136719),
        vector2(-1612.2801513672, 776.40509033203),
        vector2(-1601.6477050781, 784.32159423828),
        vector2(-1598.271484375, 791.90173339844),
        vector2(-1599.2530517578, 800.59069824219),
        vector2(-1604.5662841797, 812.10699462891),
        vector2(-1610.1090087891, 823.87829589844),
        vector2(-1611.4516601562, 832.22198486328),
        vector2(-1608.3409423828, 839.87933349609),
        vector2(-1594.3450927734, 850.01013183594),
        vector2(-1587.5551757812, 854.97967529297),
        vector2(-1575.01171875, 864.28051757812),
        vector2(-1567.6286621094, 869.5263671875),
        vector2(-1561.5709228516, 875.55041503906),
        vector2(-1556.9174804688, 882.98181152344),
        vector2(-1551.1197509766, 889.45574951172),
        vector2(-1543.6918945312, 893.67694091797),
        vector2(-1535.2485351562, 895.80688476562),
        vector2(-1527.3529052734, 899.17291259766),
        vector2(-1519.8433837891, 903.93707275391),
        vector2(-1514.6456298828, 911.31213378906),
        vector2(-1507.9565429688, 915.60394287109),
        vector2(-1500.4440917969, 913.36938476562),
        vector2(-1493.5648193359, 908.56506347656),
        vector2(-1487.1324462891, 902.77062988281),
        vector2(-1482.3350830078, 895.85711669922),
    },
    minZ = 177.0, -- Just below basement door Z ~177.15; verify basement floor with devPoly
    maxZ = 189.31729125977
}
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
    gate = {item = 'gatecrack', hack = nil, bypass = nil, doorIds = {'Parsons-Security ring'}, compromisedSeconds = 300},
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

-- Parsons medical management / boss menu interaction point
Config.BossMenu = vector4(-1493.83, 860.13, 180.6, 115.0)
