fx_version('cerulean')
game('rdr3')
rdr3_warning(
    'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
)
lua54('yes')
author('330; VORP catalogue data by CrimsonFreak (MIT)')
description('Frontier stable UI with VORP ownership, equipment and wagons')
version('0.2.0-beta.1')
dependencies({ 'vorp_core', 'oxmysql', '/onesync' })
shared_scripts({
    'shared/keys.lua',
    'shared/data.lua',
    'config.lua',
    'shared/locale.lua',
    'locations.lua',
    'shared/catalog.lua',
})
server_scripts({ '@oxmysql/lib/MySQL.lua', 'server/service.lua', 'server/storage.lua', 'server/main.lua' })
client_scripts({ 'client/preload.lua', 'client/spawn.lua', 'client/reading.lua', 'client/interactions.lua', 'client/main.lua' })
ui_page('web/dist/index.html')
files({ 'web/dist/index.html', 'web/dist/*.js', 'web/dist/*.css', 'web/dist/fonts/*', 'web/dist/images/*', 'sql/install.sql', 'locales/*.json' })
