fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_fxv2_oal 'yes'
author 'Kakarot'
description 'PowerMoves RP Parsons Rehabilitation Center admission and discharge foundation'
version '2.3.0'

dependencies {
    'ox_lib',
    'qb-core',
    'qb-target',
    'PolyZone'
}

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',
    'client/main.lua',
    'client/activities.lua',
    'client/escape.lua',
    'client/dispatch.lua',
    'client/security.lua',
    'client/operations.lua'
}

server_scripts {
    'server/main.lua',
    'server/activities.lua',
    'server/security.lua',
    'server/operations.lua'
}
